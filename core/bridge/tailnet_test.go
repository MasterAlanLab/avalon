//go:build with_gvisor && with_tailscale

package bridge

import (
	"encoding/json"
	"fmt"
	"net/netip"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/sagernet/tailscale/ipn/ipnstate"
	"github.com/sagernet/tailscale/types/key"
)

func TestTailnetInactiveCommands(t *testing.T) {
	e := newEngine(t)
	var status TailnetStatus
	if failure := call(t, e, "tailnetStatus", nil, &status); failure != nil || status.State != "disabled" {
		t.Fatal("inactive status failed")
	}
	request := map[string]any{"requestId": "no-tailnet"}
	if failure := call(t, e, "tailnetLogin", request, nil); failure == nil || failure.Code != CodeSessionMismatch {
		t.Fatal("login did not reject disabled endpoint")
	}
	var remembered CommandStatus
	if failure := call(t, e, "queryCommand", request, &remembered); failure != nil || remembered.Status != "failed" {
		t.Fatal("failed login outcome was not retained")
	}
}

func TestTailnetProjectionRejectsUnsafeLoginAndExpiredPeers(t *testing.T) {
	peer := &ipnstate.PeerStatus{ID: "stable-one", HostName: "device", OS: "linux", Online: true, Expired: true, ExitNodeOption: true, TailscaleIPs: []netip.Addr{netip.MustParseAddr("100.64.0.1")}}
	status := &ipnstate.Status{BackendState: "NeedsLogin", Peer: map[key.NodePublic]*ipnstate.PeerStatus{key.NewNode().Public(): peer}}
	for _, value := range []string{"http://login.tailscale.com/a", "https://evil.example/a", "https://user@login.tailscale.com/a", "https://login.tailscale.com:444/a", "https://login.tailscale.com/a#fragment"} {
		status.AuthURL = value
		if projectTailnet(status).LoginURL != "" {
			t.Fatal("unsafe authorization URL was exposed")
		}
	}
	status.AuthURL = "https://login.tailscale.com/a/fixture"
	result := projectTailnet(status)
	if result.LoginURL != status.AuthURL || len(result.Peers) != 1 || result.Peers[0].Online {
		t.Fatal("real peer state projection is wrong")
	}
	encoded, _ := json.Marshal(result)
	if strings.Contains(string(encoded), "PrivateKey") || strings.Contains(string(encoded), "User") {
		t.Fatal("private backend fields were exposed")
	}
}

func TestTailnetUnverifiedExitCannotStartOrProbe(t *testing.T) {
	e := newEngine(t)
	for _, settings := range []string{`"exit_node":"old-host"`, `"advertise_exit_node":true`} {
		plan := json.RawMessage(fmt.Sprintf(`{"endpoints":[{"type":"tailscale",%s}]}`, settings))
		for _, command := range []string{"start", "urlTest"} {
			failure := call(t, e, command, map[string]any{"requestId": command + settings, "plan": plan, "planHash": "h"}, nil)
			if failure == nil || failure.Code != CodeUnsupported {
				t.Fatal("unverified exit escaped the native gate")
			}
			if snapshot(t, e).State != StateStopped {
				t.Fatal("rejected exit changed session state")
			}
		}
	}
}

func TestTailnetLogsRedactAuthorization(t *testing.T) {
	for _, test := range []struct {
		name string
		url  string
	}{
		{"default_port", "https://login.tailscale.com/a/private-code"},
		{"explicit_default_port", "https://login.tailscale.com:443/a/private-code"},
		{"mixed_case", "HTTPS://LOGIN.TAILSCALE.COM:443/a/private-code"},
		{"query_without_path", "https://login.tailscale.com:443?code=private-code"},
	} {
		t.Run(test.name, func(t *testing.T) {
			buffer := newLogBuffer(1)
			buffer.add("info", "Waiting for authentication: "+test.url+" tskey-auth-private")
			page := buffer.page(0, 1)
			if len(page.Entries) != 1 {
				t.Fatal("authentication log entry was not buffered")
			}
			const want = "Waiting for authentication: [Tailscale authentication URL redacted] [Tailscale credential redacted]"
			if page.Entries[0].Message != want {
				t.Fatal("authorization data leaked into the log buffer")
			}
		})
	}
}

// Explicit opt-in: obtains an interactive URL from the real service without
// creating/logging into an account. No URL, key or backend file is printed.
func TestTailnetRealUnauthenticatedEndpoint(t *testing.T) {
	if os.Getenv("AVALON_TAILNET_AUTH_PROBE") != "1" {
		t.Skip("real control-plane probe was not requested")
	}
	e := newEngine(t)
	port := freePort(t)
	stateDir := t.TempDir() + "/tailnet"
	plan := json.RawMessage(fmt.Sprintf(`{
	 "log":{"level":"warn"},"dns":{"servers":[{"type":"local","tag":"local"}]},
	 "inbounds":[{"type":"mixed","tag":"mixed","listen":"127.0.0.1","listen_port":%d}],
	 "endpoints":[{"type":"tailscale","tag":"ts-ep","hostname":"avalon-auth-probe","state_directory":%q}],
	 "outbounds":[{"type":"direct","tag":"direct"}],
	 "route":{"default_domain_resolver":"local","rules":[{"ip_cidr":"100.64.0.0/10","outbound":"ts-ep"}],"final":"direct"}
	}`, port, stateDir))
	if failure := call(t, e, "start", map[string]any{"requestId": "tailnet-start", "plan": plan, "planHash": "test"}, nil); failure != nil {
		t.Fatalf("native endpoint start failed with %s", failure.Code)
	}
	deadline := time.Now().Add(25 * time.Second)
	var status TailnetStatus
	for time.Now().Before(deadline) {
		if failure := call(t, e, "tailnetStatus", nil, &status); failure != nil {
			t.Fatal("native status failed")
		}
		if status.LoginURL != "" {
			break
		}
		time.Sleep(200 * time.Millisecond)
	}
	if status.LoginURL == "" || status.State == "Running" {
		t.Fatal("real interactive authorization URL was not obtained")
	}
	info, err := os.Stat(stateDir)
	if err != nil || info.Mode().Perm()&0o077 != 0 {
		t.Fatal("native identity directory is not private")
	}
	client := through(port)
	client.Timeout = time.Second
	response, err := client.Get("http://100.64.0.55:12345/")
	if err == nil {
		defer response.Body.Close()
		if response.StatusCode < 400 {
			t.Fatal("unavailable Tailnet address unexpectedly succeeded")
		}
	}
	var logs LogPage
	if failure := call(t, e, "logs", map[string]any{"limit": 200}, &logs); failure != nil {
		t.Fatal("logs unavailable")
	}
	for _, entry := range logs.Entries {
		if strings.Contains(entry.Message, status.LoginURL) {
			t.Fatal("authorization URL leaked")
		}
	}
}
