package bridge

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	M "github.com/sagernet/sing/common/metadata"
)

func TestPublicAddressPolicy(t *testing.T) {
	for _, value := range []string{
		"0.0.0.0", "0.1.2.3", "10.1.2.3", "100.64.0.1", "100.127.255.254",
		"127.1.2.3", "169.254.169.254", "172.16.0.1", "172.31.255.254",
		"192.0.0.1", "192.0.2.1", "192.88.99.1", "192.168.1.1",
		"198.18.0.1", "198.19.255.255", "198.51.100.1", "203.0.113.1",
		"224.0.0.1", "239.255.255.255", "240.0.0.1", "255.255.255.255",
		"168.63.129.16", "::", "::1", "::ffff:127.0.0.1", "::ffff:10.1.2.3",
		"::ffff:192.168.1.1", "::ffff:169.254.169.254", "64:ff9b::7f00:1",
		"100::1", "2001::1", "2001:1ff::1", "2001:db8::1", "2002:7f00:1::1",
		"3fff::1", "3fff:f::1", "fc00::1", "fd7a:115c:a1e0::1", "fe80::1",
		"fec0::1", "ff02::1", "2001:4860::1%en0",
	} {
		if isPublicAddress(netip.MustParseAddr(value)) {
			t.Errorf("allowed non-public address %s", value)
		}
	}
	for _, value := range []string{"1.1.1.1", "8.8.8.8", "100.63.255.255", "172.15.255.255", "172.32.0.1", "::ffff:8.8.8.8", "2001:4860:4860::8888", "2606:4700:4700::1111"} {
		if !isPublicAddress(netip.MustParseAddr(value)) {
			t.Errorf("blocked public address %s", value)
		}
	}
}

type capturePublicDialer struct {
	destinations []M.Socksaddr
}

func (d *capturePublicDialer) DialContext(_ context.Context, _ string, address M.Socksaddr) (net.Conn, error) {
	d.destinations = append(d.destinations, address)
	return nil, errors.New("intentional dial stop")
}
func (*capturePublicDialer) ListenPacket(context.Context, M.Socksaddr) (net.PacketConn, error) {
	return nil, errors.New("unexpected packet listen")
}

func TestPublicDialPinsEachDNSAnswerBeforeSendingToCore(t *testing.T) {
	var lookupCount int
	lookup := func(context.Context, string) ([]netip.Addr, error) {
		lookupCount++
		if lookupCount == 1 {
			return []netip.Addr{netip.MustParseAddr("8.8.8.8")}, nil
		}
		return []netip.Addr{netip.MustParseAddr("127.0.0.1")}, nil
	}
	upstream := &capturePublicDialer{}
	dial := publicDialContext(lookup, upstream)
	_, _ = dial(context.Background(), "tcp", "rebinding.example:443")
	if len(upstream.destinations) != 1 || upstream.destinations[0].String() != "8.8.8.8:443" || upstream.destinations[0].IsFqdn() {
		t.Fatalf("core must receive the exact validated literal: %+v", upstream.destinations)
	}
	if _, err := dial(context.Background(), "tcp", "rebinding.example:443"); !errors.Is(err, errBlockedAddress) {
		t.Fatalf("rebound address: %v", err)
	}
	if len(upstream.destinations) != 1 {
		t.Fatal("the rebound private address reached the core")
	}
	lookup = func(context.Context, string) ([]netip.Addr, error) {
		return []netip.Addr{netip.MustParseAddr("8.8.8.8"), netip.MustParseAddr("::ffff:10.0.0.1")}, nil
	}
	if _, err := publicDialContext(lookup, upstream)(context.Background(), "tcp", "mixed.example:443"); !errors.Is(err, errBlockedAddress) {
		t.Fatalf("mixed public/private DNS answer: %v", err)
	}
}

func TestPublicPlanAddressFamilyChecksAllAnswersBeforePreference(t *testing.T) {
	lookup := func(context.Context, string) ([]netip.Addr, error) {
		return []netip.Addr{netip.MustParseAddr("2606:4700::1111"), netip.MustParseAddr("8.8.8.8")}, nil
	}
	for _, strategy := range []string{"ipv4_only", "prefer_ipv4", "prefer_ipv6"} {
		address, err := resolvePublicAddress(context.Background(), "public.example", lookup, strategy)
		if err != nil || (strategy == "prefer_ipv6") != address.Is6() {
			t.Fatalf("address family %s: %v, %v", strategy, address, err)
		}
	}
	lookup = func(context.Context, string) ([]netip.Addr, error) {
		return []netip.Addr{netip.MustParseAddr("fd00::1"), netip.MustParseAddr("8.8.8.8")}, nil
	}
	if _, err := resolvePublicAddress(context.Background(), "mixed.example", lookup, "ipv4_only"); !errors.Is(err, errBlockedAddress) {
		t.Fatalf("private AAAA must not escape checking because IPv4 is preferred: %v", err)
	}
}

func guardPlan(t *testing.T, tree map[string]any, tags ...string) []byte {
	t.Helper()
	tree[publicNetworkEnvelope] = map[string]any{"version": 1, "endpointTags": tags}
	plan, err := json.Marshal(tree)
	if err != nil {
		t.Fatal(err)
	}
	return plan
}

func TestPublicPlanPinsDetoursAndPreservesHostNames(t *testing.T) {
	lookupCount := 0
	lookup := func(context.Context, string) ([]netip.Addr, error) {
		lookupCount++
		return []netip.Addr{netip.MustParseAddr("8.8.8.8")}, nil
	}
	for _, transport := range []map[string]any{
		{"type": "ws", "path": "/proxy"},
		{"type": "http", "path": "/proxy"},
		{"type": "grpc", "service_name": "proxy"},
	} {
		original := guardPlan(t, map[string]any{"outbounds": []any{
			map[string]any{"type": "vless", "tag": "exit", "server": "exit.example", "server_port": 443, "uuid": "fixture", "tls": map[string]any{"enabled": true}, "transport": transport, "detour": "entry"},
			map[string]any{"type": "socks", "tag": "entry", "server": "entry.example", "server_port": 1080, "version": "5"},
			map[string]any{"type": "socks", "tag": "local", "server": "127.0.0.1", "server_port": 1080, "version": "5"},
		}}, "exit")
		prepared, err := preparePublicPlan(original, lookup)
		if err != nil {
			t.Fatal(err)
		}
		var tree map[string]any
		_ = json.Unmarshal(prepared, &tree)
		if _, found := tree[publicNetworkEnvelope]; found {
			t.Fatal("host envelope was passed to sing-box")
		}
		outbounds := list(tree["outbounds"])
		exit, entry, local := outbounds[0].(map[string]any), outbounds[1].(map[string]any), outbounds[2].(map[string]any)
		if text(exit["server"]) != "8.8.8.8" || text(entry["server"]) != "8.8.8.8" || text(local["server"]) != "127.0.0.1" {
			t.Fatal("only guarded endpoints and their detours should be pinned")
		}
		if text(exit["tls"].(map[string]any)["server_name"]) != "exit.example" {
			t.Fatal("implicit TLS verification/SNI name was changed")
		}
		if text(transport["type"]) == "ws" && text(exit["transport"].(map[string]any)["headers"].(map[string]any)["Host"]) != "exit.example:443" {
			t.Fatal("implicit WebSocket Host authority was changed")
		}
		if !strings.Contains(string(original), "exit.example") {
			t.Fatal("the original plan must retain the hostname for a fresh next start")
		}
	}
	if lookupCount != 6 {
		t.Fatalf("one lookup per endpoint for each prepared instance: %d", lookupCount)
	}
}

func TestPublicPlanRejectsUncoveredOptionsAndPrivateDetours(t *testing.T) {
	for _, outbound := range []map[string]any{
		{"type": "socks", "tag": "x", "server": "127.0.0.1", "server_port": 80},
		{"type": "socks", "tag": "x", "server": "::ffff:192.168.1.1", "server_port": 80},
		{"type": "socks", "tag": "x", "server": "8.8.8.8", "server_port": 80, "protect_path": "/device/file"},
		{"type": "trojan", "tag": "x", "server": "8.8.8.8", "server_port": 443, "tls": map[string]any{"enabled": true, "certificate_path": "/device/file"}},
		{"type": "shadowsocks", "tag": "x", "server": "8.8.8.8", "server_port": 443, "plugin": "v2ray-plugin", "plugin_opts": "cert=/device/file"},
		{"type": "urltest", "tag": "x", "outbounds": []any{"local"}, "url": "http://127.0.0.1/"},
		{"type": "vless", "tag": "x", "server": "x.example", "server_port": 443, "transport": map[string]any{"type": "grpc"}},
	} {
		plan := guardPlan(t, map[string]any{"outbounds": []any{outbound}}, "x")
		if _, err := preparePublicPlan(plan, func(context.Context, string) ([]netip.Addr, error) {
			return []netip.Addr{netip.MustParseAddr("8.8.8.8")}, nil
		}); err == nil {
			t.Fatalf("uncovered endpoint was accepted: %v", outbound["type"])
		}
	}
	plan := guardPlan(t, map[string]any{"outbounds": []any{
		map[string]any{"type": "socks", "tag": "cloud", "server": "8.8.8.8", "server_port": 80, "detour": "group"},
		map[string]any{"type": "selector", "tag": "group", "outbounds": []any{"private"}},
		map[string]any{"type": "socks", "tag": "private", "server": "127.0.0.1", "server_port": 80},
	}}, "cloud")
	if _, err := preparePublicPlan(plan, systemPublicLookup); !errors.Is(err, errBlockedAddress) {
		t.Fatalf("private detour: %v", err)
	}
}

func TestRealCoreConsumesEnvelopeAndLeavesNormalTrafficUnchanged(t *testing.T) {
	e := newEngine(t)
	var tree map[string]any
	port := freePort(t)
	_ = json.Unmarshal([]byte(plan(port, "")), &tree)
	tree["outbounds"] = append(list(tree["outbounds"]), map[string]any{"type": "socks", "tag": "cloud", "server": "8.8.8.8", "server_port": 1080, "version": "5"})
	guarded := guardPlan(t, tree, "cloud")
	var session sessionResult
	if err := call(t, e, "start", startRequest{Plan: guarded, PlanHash: "guarded"}, &session); err != nil {
		t.Fatalf("real core did not consume the host envelope: %v", err)
	}
	server := origin(t)
	response, err := through(port).Get(server.URL)
	if err != nil {
		t.Fatalf("normal user traffic to local network was altered: %v", err)
	}
	response.Body.Close()
	// Reload validates before stopping a working session. A malicious
	// private endpoint cannot cost that session or reach its private origin.
	list(tree["outbounds"])[4].(map[string]any)["server"] = "127.0.0.1"
	if err := call(t, e, "reload", startRequest{SessionID: session.SessionID, Plan: guardPlan(t, tree, "cloud")}, nil); err == nil || err.Code != CodePlanInvalid {
		t.Fatalf("private endpoint reload: %v", err)
	}
	if current := snapshot(t, e); current.State != StateRunning || current.SessionID != session.SessionID {
		t.Fatal("a blocked reload must retain the previous working instance")
	}
}

func TestOlderHostCannotPassEnvelopeStraightToSingbox(t *testing.T) {
	plan := guardPlan(t, map[string]any{"outbounds": []any{
		map[string]any{"type": "socks", "tag": "cloud", "server": "127.0.0.1", "server_port": 1080},
	}}, "cloud")
	service := NewDesktopService(t.TempDir(), t.TempDir())
	defer service.CloseService()
	if err := service.CheckConfig(context.Background(), string(plan)); err == nil || !strings.Contains(err.Error(), publicNetworkEnvelope) {
		t.Fatalf("an older bridge must fail closed on the host envelope: %v", err)
	}
}

func TestRealCoreStartsPinnedUDPQUICEndpoints(t *testing.T) {
	for _, protocol := range []string{"hysteria2", "tuic"} {
		t.Run(protocol, func(t *testing.T) {
			e := newEngine(t)
			lookups := 0
			e.publicLookup = func(context.Context, string) ([]netip.Addr, error) {
				lookups++
				return []netip.Addr{netip.MustParseAddr("8.8.8.8")}, nil
			}
			outbound := map[string]any{"type": protocol, "tag": "cloud", "server": "public.example", "server_port": 443, "password": "fixture", "tls": map[string]any{"enabled": true}}
			if protocol == "tuic" {
				outbound["uuid"] = "00000000-0000-0000-0000-000000000001"
				outbound["congestion_control"] = "cubic"
			}
			guarded := guardPlan(t, map[string]any{"outbounds": []any{outbound}, "route": map[string]any{"final": "cloud"}}, "cloud")
			if err := call(t, e, "start", startRequest{Plan: guarded}, nil); err != nil {
				t.Fatalf("real core initialization: %v", err)
			}
			if lookups != 1 {
				t.Fatalf("hostname was not resolved exactly once for the instance: %d", lookups)
			}
		})
	}
}

func TestPublicFetchRejectsPrivateOriginWithoutFilesOrSecretErrors(t *testing.T) {
	e := newEngine(t)
	session := mustStart(t, e, freePort(t))
	var seen atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { seen.Add(1); _, _ = w.Write([]byte("private")) }))
	defer server.Close()
	dest := filepath.Join(t.TempDir(), "resource.srs")
	for i, address := range []string{server.URL + "/?token=fixture-secret", "http://[::ffff:127.0.0.1]/", "file:///device/file", "http://user:fixture-secret@8.8.8.8/", "http://8.8.8.8/#fragment"} {
		err := call(t, e, "fetch", fetchRequest{RequestID: fmt.Sprint(i), SessionID: session, OutboundTag: "proxy", URL: address, PublicOnly: true, DestPath: dest}, nil)
		if err == nil || strings.Contains(err.Error(), "fixture-secret") {
			t.Fatalf("unsafe or secret-bearing failure: %v", err)
		}
	}
	if seen.Load() != 0 {
		t.Fatal("the private origin received a guarded request")
	}
	if _, err := os.Stat(dest); !os.IsNotExist(err) {
		t.Fatal("a rejected download left a file")
	}
}

func TestPublicFetchRealCorePreservesHostAndBlocksRedirectBeforeSecondConnection(t *testing.T) {
	privateCalls := atomic.Int32{}
	private := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		privateCalls.Add(1)
		_, _ = w.Write([]byte("private"))
	}))
	defer private.Close()
	proxy, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()
	requests := make(chan [2]string, 1)
	failures := make(chan error, 1)
	go func() {
		connection, err := proxy.Accept()
		if err != nil {
			failures <- err
			return
		}
		defer connection.Close()
		_ = connection.SetDeadline(time.Now().Add(3 * time.Second))
		reader := bufio.NewReader(connection)
		connect, err := http.ReadRequest(reader)
		if err != nil {
			failures <- err
			return
		}
		_, _ = io.WriteString(connection, "HTTP/1.1 200 Connection Established\r\n\r\n")
		get, err := http.ReadRequest(reader)
		if err != nil {
			failures <- err
			return
		}
		requests <- [2]string{connect.Host, get.Host}
		_, _ = fmt.Fprintf(connection, "HTTP/1.1 302 Found\r\nLocation: %s/?token=fixture-secret\r\nContent-Length: 0\r\nConnection: close\r\n\r\n", private.URL)
	}()
	e := newEngine(t)
	e.publicLookup = func(context.Context, string) ([]netip.Addr, error) {
		return []netip.Addr{netip.MustParseAddr("8.8.8.8")}, nil
	}
	port := proxy.Addr().(*net.TCPAddr).Port
	plan := fmt.Sprintf(`{"outbounds":[{"type":"http","tag":"relay","server":"127.0.0.1","server_port":%d}],"route":{"final":"relay"}}`, port)
	var session sessionResult
	if err := call(t, e, "start", startRequest{Plan: json.RawMessage(plan)}, &session); err != nil {
		t.Fatal(err)
	}
	errBridge := call(t, e, "fetch", fetchRequest{SessionID: session.SessionID, OutboundTag: "relay", URL: "http://resource.example:8080/rules", PublicOnly: true}, nil)
	if errBridge == nil || !strings.Contains(errBridge.Message, "not a public") || strings.Contains(errBridge.Message, "fixture-secret") {
		t.Fatalf("private redirect was not safely rejected: %v", errBridge)
	}
	select {
	case request := <-requests:
		if request != [2]string{"8.8.8.8:8080", "resource.example:8080"} {
			t.Fatalf("core must dial the pinned literal, retaining HTTP Host: %v", request)
		}
	case err := <-failures:
		t.Fatal(err)
	case <-time.After(time.Second):
		t.Fatal("proxy request was not observed")
	}
	if privateCalls.Load() != 0 {
		t.Fatal("private redirect was followed")
	}
}
