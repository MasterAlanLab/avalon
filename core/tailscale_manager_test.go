package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/netip"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"slices"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
)

type fakeTSBackend struct {
	mu                sync.Mutex
	closed, loggedOut bool
	logoutErr         error
	status            tsBackendStatus
	pingStarted       chan struct{}
	pingRelease       chan struct{}
	p                 C.Proxy
}

func (b *fakeTSBackend) Login(context.Context, string) error { return nil }
func (b *fakeTSBackend) Logout(context.Context) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.loggedOut = true
	return b.logoutErr
}
func (b *fakeTSBackend) Preferences(context.Context, tsPreferences) error { return nil }
func (b *fakeTSBackend) Watch(ctx context.Context, fn func(tsBackendStatus)) error {
	b.mu.Lock()
	s := b.status
	b.mu.Unlock()
	fn(s)
	<-ctx.Done()
	return ctx.Err()
}
func (b *fakeTSBackend) Refresh(context.Context) (tsBackendStatus, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.status, nil
}
func (b *fakeTSBackend) Ping(ctx context.Context, ip string) (tsProbe, error) {
	if b.pingStarted != nil {
		select {
		case b.pingStarted <- struct{}{}:
		default:
		}
	}
	if b.pingRelease != nil {
		select {
		case <-b.pingRelease:
		case <-ctx.Done():
			return tsProbe{}, ctx.Err()
		}
	}
	return tsProbe{State: "success", Type: "disco", Path: "direct", Latency: 1, At: time.Now()}, nil
}
func (b *fakeTSBackend) ExitHealthy(context.Context) bool { return true }
func (b *fakeTSBackend) Proxy() C.Proxy                   { return b.p }
func (b *fakeTSBackend) Close() error                     { b.mu.Lock(); defer b.mu.Unlock(); b.closed = true; return nil }
func testTSManager(t *testing.T) (*tsManager, *fakeTSBackend) {
	t.Helper()
	b := &fakeTSBackend{status: tsBackendStatus{Session: "running", Control: "healthy", Devices: []tsDevice{}}, p: adapter.NewProxy(outbound.NewDirect())}
	m := newTSManager(func(context.Context, string, string, func() bool) (tsBackend, error) { return b, nil }, true, nil)
	m.captureKnown = true
	m.localPrefixes = func() []netip.Prefix { return nil }
	m.Init(t.TempDir())
	m.disk.Registered = true
	t.Cleanup(m.Shutdown)
	return m, b
}
func eventuallyTS(t *testing.T, fn func() bool) {
	t.Helper()
	deadline := time.Now().Add(time.Second * 3)
	for !fn() {
		if time.Now().After(deadline) {
			t.Fatal("condition did not settle")
		}
		time.Sleep(time.Millisecond * 5)
	}
}
func runTS(t *testing.T, m *tsManager) {
	t.Helper()
	_, err := m.Begin("resume", "", "")
	if err != nil {
		t.Fatal(err)
	}
	eventuallyTS(t, func() bool { return m.Snapshot().Session == "running" })
}
func TestTSLifecycleStaleGeneration(t *testing.T) {
	m, b := testTSManager(t)
	runTS(t, m)
	gen := m.Snapshot().Generation
	s, err := m.Stop("pause")
	if err != nil || s.Session != "paused" {
		t.Fatalf("pause: %v %+v", err, s)
	}
	m.ingest(gen, tsBackendStatus{Session: "running", AuthURL: "https://HOST/a/TOKEN"})
	if m.Snapshot().Session != "paused" || m.Snapshot().AuthURL != "" {
		t.Fatal("old event resurrected session")
	}
	b.mu.Lock()
	closed := b.closed
	loggedOut := b.loggedOut
	b.mu.Unlock()
	if !closed || loggedOut {
		t.Fatal("pause must close networking without logout")
	}
	runTS(t, m)
	m.ingest(gen, tsBackendStatus{Session: "needsLogin", Control: "healthy"})
	if m.Snapshot().Session != "running" {
		t.Fatal("previous generation replaced resumed session")
	}
	s, err = m.Stop("logout")
	if err != nil || s.Session != "loggedOut" {
		t.Fatal(err)
	}
	b.mu.Lock()
	loggedOut = b.loggedOut
	b.mu.Unlock()
	if !loggedOut {
		t.Fatal("missing real logout")
	}
}
func TestTSStateSeparation(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	tunnel.SetMode(tunnel.Rule)
	defer tunnel.SetMode(tunnel.Rule)
	for _, tc := range []struct {
		service, tun, ipv6 bool
		mode               tunnel.TunnelMode
		want               string
	}{{false, true, true, tunnel.Rule, "inactive"}, {true, false, true, tunnel.Rule, "partial"}, {true, true, false, tunnel.Rule, "partial"}, {true, true, true, tunnel.Rule, "active"}, {true, true, true, tunnel.Global, "inactive"}, {true, true, true, tunnel.Direct, "inactive"}} {
		tunnel.SetMode(tc.mode)
		m.ConfigStatus(7, tc.service, tc.tun, tc.ipv6, nil, nil)
		if got := m.Snapshot().Split; got != tc.want {
			t.Fatalf("%+v got %s", tc, got)
		}
	}
	m.ConfigStatus(0, true, true, true, nil, nil)
	if m.Snapshot().Split != "inactive" {
		t.Fatal("no profile reported active")
	}
}
func TestTSApprovalAndControlCache(t *testing.T) {
	m, _ := testTSManager(t)
	gen := m.Snapshot().Generation
	m.ingest(gen, tsBackendStatus{Session: "waitingApproval", AuthURL: "https://HOST/register/TOKEN", Control: "healthy"})
	if m.Snapshot().Session != "waitingApproval" {
		t.Fatal("approval state lost")
	}
	m.ingest(gen, tsBackendStatus{Session: "running", Control: "healthy", Devices: []tsDevice{{ID: "stable", Online: true, IPs: []string{"100.80.1.1"}}}})
	m.fail(gen, "server_unreachable")
	s := m.Snapshot()
	if !s.Cached || !s.Devices[0].Online || s.Session != "running" {
		t.Fatal("control failure must retain device state")
	}
	m.ingest(gen, tsBackendStatus{Session: "needsLogin", Control: "healthy"})
	if m.Snapshot().Session != "needsLogin" {
		t.Fatal("expiry not propagated")
	}
}
func TestTSConflictsContainmentAndPublisher(t *testing.T) {
	m, _ := testTSManager(t)
	m.localPrefixes = func() []netip.Prefix {
		return []netip.Prefix{netip.MustParsePrefix("192.168.1.0/24"), netip.MustParsePrefix("fd00:1::/64")}
	}
	m.mu.Lock()
	m.disk.Prefs.AcceptRoutes = true
	m.state.Devices = []tsDevice{{ID: "a", Routes: []string{"192.168.0.0/16", "fd00::/16"}}, {ID: "b", Routes: []string{"192.168.0.0/16"}}}
	m.publishLocked()
	m.mu.Unlock()
	s := m.Snapshot()
	if len(s.Routes) != 2 || s.Routes[0].Accepted || !s.Routes[0].Conflict || len(s.Routes[0].Publishers) != 2 {
		t.Fatalf("conflicts %+v", s.Routes)
	}
	p := s.Prefs
	p.RouteChoices["192.168.0.0/16"] = "remote"
	_, err := m.SetPreferences(p)
	if err != nil {
		t.Fatal(err)
	}
	if !m.Snapshot().Routes[0].Accepted {
		t.Fatal("explicit remote preference ignored")
	}
}
func TestTSRoutingOverlayPriorities(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	m.mu.Lock()
	m.state.ProfileID = "7"
	m.state.Suffix = "head.example"
	m.state.CapturePrefixes = []string{"100.64.0.0/10", "fd7a:115c:a1e0::/48", "10.20.0.0/16"}
	m.state.Routes = []tsRoute{{Prefix: "10.20.0.0/16", Accepted: true}}
	m.disk.Prefs.ExitID = "exit"
	m.disk.Prefs.ExitScope = "all"
	m.exitHealthy = true
	m.exitOnline = true
	m.mu.Unlock()
	original := adapter.NewProxy(outbound.NewDirect())
	reject := adapter.NewProxy(outbound.NewReject())
	for _, ip := range []string{"100.70.0.2", "fd7a:115c:a1e0::2", "10.20.2.1"} {
		md := &C.Metadata{DstIP: netip.MustParseAddr(ip)}
		p, err := m.Route(md, original, nil)
		if err != nil || p == original {
			t.Fatalf("tailnet %s not managed", ip)
		}
		p, err = m.Route(md, reject, nil)
		if err != nil || p != reject {
			t.Fatal("reject changed")
		}
	}
	for _, ip := range []string{"127.0.0.1", "192.168.2.1", "169.254.1.1", "224.0.0.1", "::1", "fe80::1", "ff00::1", "198.18.0.1", "2001:db8::1"} {
		p, err := m.Route(&C.Metadata{DstIP: netip.MustParseAddr(ip)}, original, nil)
		if err != nil || p != original {
			t.Fatalf("special address sent to exit: %s", ip)
		}
	}
	p, err := m.Route(&C.Metadata{DstIP: netip.MustParseAddr("8.8.8.8")}, original, nil)
	if err != nil || p == original {
		t.Fatal("public not covered")
	}
	if !strings.HasPrefix(p.Name(), tsExitMarker) {
		t.Fatal("exit connection ownership marker missing")
	}
	// Host ownership comes from backend names, not a fixed .ts.net suffix.
	m.mu.Lock()
	m.disk.Prefs.ExitID = ""
	m.state.Suffix = "custom.example"
	m.state.Devices = []tsDevice{{ID: "node", DNSName: "host.custom.example."}}
	m.mu.Unlock()
	if p, err := m.Route(&C.Metadata{Host: "host.custom.example"}, original, nil); err != nil || p == original {
		t.Fatal("backend domain not routed")
	}
	if p, err := m.Route(&C.Metadata{Host: "host.ts.net"}, original, nil); err != nil || p != original {
		t.Fatal("fixed suffix falsely routed")
	}
}
func TestTSSelectedGroupsAndFallbackIsolation(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	m.mu.Lock()
	m.state.ProfileID = "1"
	m.state.CapturePrefixes = []string{"100.64.0.0/10"}
	m.disk.Prefs.ExitID = "exit"
	m.disk.Prefs.Bindings = map[string][]string{"1": {"DIRECT"}}
	m.disk.Prefs.FailurePolicy = "stop"
	m.mu.Unlock()
	original := adapter.NewProxy(outbound.NewDirect())
	md := &C.Metadata{DstIP: netip.MustParseAddr("8.8.8.8")}
	if _, err := m.Route(md, original, nil); err == nil {
		t.Fatal("silent direct fallback")
	}
	m.mu.Lock()
	m.state.ProfileID = "2"
	m.mu.Unlock()
	if p, err := m.Route(md, original, nil); err != nil || p != original {
		t.Fatal("profile binding leaked")
	}
	m.mu.Lock()
	m.state.ProfileID = "1"
	m.disk.Prefs.FailurePolicy = "fallback"
	m.state.Session = "paused"
	m.backend = nil
	m.mu.Unlock()
	if p, err := m.Route(md, original, nil); err != nil || p != original {
		t.Fatal("current original route not restored")
	}
	if _, err := m.Route(&C.Metadata{DstIP: netip.MustParseAddr("100.70.0.1")}, original, nil); err == nil {
		t.Fatal("tailnet fell into public fallback")
	}
	m.mu.Lock()
	m.disk.Prefs.ExitScope = "all"
	m.disk.Prefs.FailurePolicy = "stop"
	m.mu.Unlock()
	unresolved := &C.Metadata{Host: "public.example"}
	if _, err := m.Route(unresolved, original, nil); err == nil {
		t.Fatal("unresolved public destination silently bypassed exit")
	}
	m.mu.Lock()
	m.disk.Prefs.FailurePolicy = "fallback"
	m.mu.Unlock()
	if p, err := m.Route(unresolved, original, nil); err != nil || p != original {
		t.Fatal("explicit unresolved fallback not restored")
	}
}
func TestTSFinalDNSOverlayIdempotent(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	s := m.Snapshot()
	s.Suffix = "custom.head.net"
	s.Devices = []tsDevice{{DNSName: "nas.custom.head.net."}}
	s.CapturePrefixes = []string{"100.64.0.0/10", "10.20.0.0/16", "fd7a:115c:a1e0::/48"}
	raw := map[string]any{"mode": "rule", "ipv6": false, "dns": map[string]any{"enhanced-mode": "fake-ip", "nameserver": []any{"https://DNS/dns-query"}, "nameserver-policy": map[string]any{"+.original.test": []any{"system://"}}}, "tun": map[string]any{"route-address": []any{"8.0.0.0/8"}, "route-exclude-address": []any{"10.0.0.0/8"}}, "rules": []any{"MATCH,DIRECT"}, "proxies": []any{map[string]any{"name": "imported", "type": "tailscale", "state-dir": "tailscale"}}}
	tsOverlayConfig(raw, s)
	first, _ := json.Marshal(raw)
	tsOverlayConfig(raw, s)
	second, _ := json.Marshal(raw)
	if string(first) != string(second) {
		t.Fatal("overlay not idempotent")
	}
	dns := raw["dns"].(map[string]any)
	policy := dns["nameserver-policy"].(map[string]any)
	if policy["nas"] == nil || policy["+.custom.head.net"] == nil || policy["+.original.test"] == nil || dns["enhanced-mode"] != "fake-ip" {
		t.Fatal("DNS overwrite lost policy or unrelated settings")
	}
	if strings.Contains(string(first), "authKey") || strings.Contains(string(first), "fd7a:") {
		t.Fatal("credential or disabled IPv6 emitted")
	}
	if !reflect.DeepEqual(raw["rules"], []any{"MATCH,DIRECT"}) {
		t.Fatal("original rule table mutated")
	}
}
func TestTSProbeCancellationRevision(t *testing.T) {
	m, b := testTSManager(t)
	b.pingStarted = make(chan struct{}, 1)
	b.pingRelease = make(chan struct{})
	runTS(t, m)
	m.mu.Lock()
	m.state.Devices = []tsDevice{{ID: "peer", IPs: []string{"100.70.1.1"}}}
	m.mu.Unlock()
	if _, err := m.Probe([]string{"peer"}); err != nil {
		t.Fatal(err)
	}
	<-b.pingStarted
	m.CancelProbes()
	close(b.pingRelease)
	time.Sleep(time.Millisecond * 30)
	if m.Snapshot().Probes["peer"].State != "cancelled" {
		t.Fatal("late probe overwrote cancellation")
	}
}
func TestTSAuthorizationURLIsTransientAndErrorsAreCategorical(t *testing.T) {
	// The RPC owns and clears the request buffer on every login return path.
	for _, raw := range []string{`{"authKey":"fixture-secret",BROKEN`, `{"kind":"invalid","authKey":"fixture-secret"}`} {
		data := json.RawMessage(raw)
		call := MethodCall{Method: tailscaleLoginMethod, Arguments: data}
		if !handleTailscaleCall(&call, MethodResponse{}) || call.Arguments != nil || !bytes.Equal(data, make([]byte, len(data))) {
			t.Fatal("login request buffer retained credentials")
		}
	}
	m, _ := testTSManager(t)
	runTS(t, m)
	authURL := "https://HOST/a/TOKEN"
	m.ingest(m.Snapshot().Generation, tsBackendStatus{Session: "authorizing", Control: "healthy", AuthURL: authURL})
	if m.Snapshot().AuthURL != authURL {
		t.Fatal("authorization URL never reached live state")
	}
	data, err := os.ReadFile(filepath.Join(m.root, "preferences.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(data), "TOKEN") || strings.Contains(string(data), "authUrl") {
		t.Fatal("live authorization URL persisted")
	}
	info, _ := os.Stat(filepath.Join(m.root, "preferences.json"))
	if runtime.GOOS != "windows" && info.Mode().Perm() != 0600 {
		t.Fatal("identity preferences mode")
	}
	if got := tsErrorCode(errors.New("invalid key tskey-fixture https://HOST/a/TOKEN")); got != "auth_invalid" {
		t.Fatal("error category leaked secret")
	}
}
func TestTSUnsupportedCapability(t *testing.T) {
	m := newTSManager(nil, false, nil)
	m.Init(t.TempDir())
	if _, err := m.Begin("browser", "", ""); err == nil || err.Error() != "unsupported" {
		t.Fatal("unsupported login accepted")
	}
	if _, err := m.Stop("logout"); err == nil || err.Error() != "unsupported" {
		t.Fatal("unsupported logout accepted")
	}
}
func TestTSLogoutFailureRetryAndRestart(t *testing.T) {
	m, b := testTSManager(t)
	runTS(t, m)
	b.mu.Lock()
	b.logoutErr = errors.New("backend unavailable")
	b.mu.Unlock()
	if s, err := m.Stop("logout"); err == nil || s.Session == "loggedOut" || s.Error != "logout_failed" {
		t.Fatalf("false logout success: %+v %v", s, err)
	}
	if _, err := m.Begin("resume", "", ""); err == nil {
		t.Fatal("pending logout reconnected")
	}
	other := newTSManager(m.factory, true, nil)
	other.localPrefixes = m.localPrefixes
	other.Init(filepath.Dir(m.root))
	defer other.Shutdown()
	if other.Snapshot().Error != "logout_failed" {
		t.Fatal("restart lost failed cleanup")
	}
	if _, err := other.Stop("logout"); err == nil {
		t.Fatal("retry skipped backend logout")
	}
	b.mu.Lock()
	b.logoutErr = nil
	b.mu.Unlock()
	if s, err := other.Stop("logout"); err != nil || s.Session != "loggedOut" {
		t.Fatalf("retry: %+v %v", s, err)
	}
}

func TestTSCaptureReflectsInstalledRoutes(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	m.mu.Lock()
	m.capturedPrefixes = []netip.Prefix{netip.MustParsePrefix("8.0.0.0/8")}
	m.mu.Unlock()
	m.ConfigStatus(7, true, true, true, nil, nil)
	if m.Snapshot().Split != "partial" || !slices.Contains(m.Snapshot().Reasons, "capture_missing_prefix") {
		t.Fatal("requested routes confused with installed routes")
	}
	m.mu.Lock()
	m.capturedPrefixes = nil
	m.captureExclusions = []netip.Prefix{netip.MustParsePrefix("100.64.0.0/10")}
	m.mu.Unlock()
	m.ConfigStatus(7, true, true, true, nil, nil)
	if m.Snapshot().Split != "partial" {
		t.Fatal("excluded tailnet reported captured")
	}
	m.mu.Lock()
	m.captureExclusions = nil
	m.captureFailure = true
	m.mu.Unlock()
	m.ConfigStatus(7, true, true, true, nil, nil)
	if !slices.Contains(m.Snapshot().Reasons, "capture_apply_failed") || m.Snapshot().Split != "partial" {
		t.Fatal("VPN rollback hid apply failure")
	}
}

func TestTSReservedNameDoesNotTakeUserOwnership(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.yaml")
	if err := os.WriteFile(path, []byte("mode: rule\nproxies:\n  - name: "+managedTSName+"\n    type: direct\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if _, err := tsParseConfig(path); err == nil || !strings.Contains(err.Error(), "reserved") {
		t.Fatal("user resolver namespace overwritten")
	}
}

func TestTSNetworkOverlayPreservesProxiesAndCurrentMode(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	oldManager, oldConfig, oldSource, oldTun, oldRunning := managedTS, currentConfig, lastUsableTSYAML, tsBaseTun, isRunning
	defer func() {
		managedTS, currentConfig, lastUsableTSYAML, tsBaseTun, isRunning = oldManager, oldConfig, oldSource, oldTun, oldRunning
	}()
	managedTS = m
	lastUsableTSYAML = []byte("mode: rule\nipv6: true\ndns:\n  enable: false\ntun:\n  enable: false\nproxies:\n  - name: ordinary-import\n    type: direct\n")
	raw, err := config.UnmarshalRawConfig(lastUsableTSYAML)
	if err != nil {
		t.Fatal(err)
	}
	tsBaseTun = raw.Tun
	currentConfig = &config.Config{General: &config.General{Mode: tunnel.Global, IPv6: false}}
	isRunning = false
	before := tunnel.AllProxies()
	if err = tsApplyNetworkOverlayLocked(); err != nil {
		t.Fatal(err)
	}
	if currentConfig.General.Mode != tunnel.Global || currentConfig.General.IPv6 {
		t.Fatal("overlay reverted current user mode/IPv6")
	}
	for name, p := range before {
		if tunnel.AllProxies()[name] != p {
			t.Fatal("ordinary proxy recreated")
		}
	}
	if _, ok := tunnel.AllProxies()["ordinary-import"]; ok {
		t.Fatal("network-only parser instantiated source proxies")
	}
	if len(currentConfig.General.Tun.Inet6Address) != 0 {
		t.Fatal("disabled IPv6 added silently")
	}
}

func TestTSPausedRestartRetainsCustomNetworkOwnership(t *testing.T) {
	m, _ := testTSManager(t)
	runTS(t, m)
	gen := m.Snapshot().Generation
	m.ingest(gen, tsBackendStatus{Session: "running", Control: "healthy", Suffix: "head.custom.example", Devices: []tsDevice{{ID: "custom", DNSName: "nas.head.custom.example.", IPs: []string{"172.22.1.1"}, Routes: []string{"10.99.0.0/16"}}}})
	m.mu.Lock()
	m.disk.Prefs.AcceptRoutes = true
	m.disk.Prefs.Bindings["7"] = []string{"selected"}
	m.mu.Unlock()
	if _, err := m.Stop("pause"); err != nil {
		t.Fatal(err)
	}
	other := newTSManager(m.factory, true, nil)
	other.localPrefixes = m.localPrefixes
	other.Init(filepath.Dir(m.root))
	defer other.Shutdown()
	s := other.Snapshot()
	if !s.Cached || s.Session != "paused" {
		t.Fatal("cached map implied authentication")
	}
	if !reflect.DeepEqual(s.Prefs.Bindings["7"], []string{"selected"}) {
		t.Fatal("restart dropped profile bindings")
	}
	original := adapter.NewProxy(outbound.NewDirect())
	for _, ip := range []string{"172.22.1.1", "10.99.2.1"} {
		if _, err := other.Route(&C.Metadata{DstIP: netip.MustParseAddr(ip)}, original, nil); err == nil {
			t.Fatal("paused custom network leaked to original", ip)
		}
	}
	if _, err := other.Route(&C.Metadata{Host: "nas.head.custom.example"}, original, nil); err == nil {
		t.Fatal("cached DNS ownership lost")
	}
}

func TestTSConcurrentResumeSupersedesQueuedPause(t *testing.T) {
	m, b := testTSManager(t)
	runTS(t, m)
	m.op.Lock()
	done := make(chan struct{})
	go func() { defer close(done); _, _ = m.Stop("pause") }()
	eventuallyTS(t, func() bool { return m.Snapshot().Session == "stopping" })
	_, err := m.Begin("resume", "", "")
	if err != nil {
		m.op.Unlock()
		t.Fatal(err)
	}
	m.op.Unlock()
	<-done
	eventuallyTS(t, func() bool { return m.Snapshot().Session == "running" })
	m.mu.Lock()
	active := m.backend == b
	m.mu.Unlock()
	if !active {
		t.Fatal("superseded pause stole newer backend ownership")
	}
}
