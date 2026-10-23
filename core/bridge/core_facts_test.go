package bridge

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLongURLTestIntervalNeedsIdleTimeoutAtStart(t *testing.T) {
	server := origin(t)
	for _, interval := range []int{7200, 86400} {
		t.Run(fmt.Sprint(interval), func(t *testing.T) {
			e := newEngine(t)
			port := freePort(t)
			config := fmt.Sprintf(`{
				"inbounds": [{"type":"mixed","listen":"127.0.0.1","listen_port":%d}],
				"outbounds": [
					{"type":"direct","tag":"direct"},
					{"type":"urltest","tag":"auto","outbounds":["direct"],"url":%q,"interval":"%ds"}
				],
				"route":{"final":"auto"}
			}`, port, server.URL, interval)
			request := map[string]any{"plan": json.RawMessage(config), "planHash": "long-interval"}
			startErr := call(t, e, "start", request, nil)
			if startErr == nil || !strings.Contains(startErr.Message, "interval must be less or equal than idle_timeout") {
				t.Fatalf("the actual start must reproduce the interval constraint: %v", startErr)
			}
			if s := snapshot(t, e); s.State != StateFailed || s.ProxyActive || s.TunActive {
				t.Fatalf("the failed start must not leave active proxy or TUN: %+v", s)
			}
			fixed := strings.Replace(config, fmt.Sprintf(`"interval":"%ds"`, interval),
				fmt.Sprintf(`"interval":"%ds","idle_timeout":"%ds"`, interval, interval), 1)
			request["plan"] = json.RawMessage(fixed)
			var session sessionResult
			if err := call(t, e, "start", request, &session); err != nil {
				t.Fatal(err)
			}
			if s := snapshot(t, e); s.State != StateRunning || s.SessionID != session.SessionID {
				t.Fatalf("the fixed group must actually run: %+v", s)
			}
			response, err := through(port).Get(server.URL)
			if err != nil {
				t.Fatal(err)
			}
			defer response.Body.Close()
			body, err := io.ReadAll(response.Body)
			if err != nil || string(body) != strings.Repeat("avalon ", 512) {
				t.Fatalf("the fixed group must carry the local request: %v", err)
			}
		})
	}
}

// The Dart converter's source format must remain loadable by the pinned core.
func TestConvertedRuleSetLoads(t *testing.T) {
	path := filepath.Join(t.TempDir(), "provider.json")
	source := `{"version": 2, "rules": [
		{"domain": ["a.com"], "domain_suffix": ["b.com", ".c.com"], "domain_keyword": ["k"],
		 "domain_regex": ["^[^.]+\\.d\\.com$"]},
		{"ip_cidr": ["1.2.3.0/24", "2001:db8::/32"]},
		{"source_ip_cidr": ["10.0.0.0/8"]},
		{"process_name": ["curl"]},
		{"process_path": ["/usr/bin/curl"]},
		{"port": [443]},
		{"port_range": ["8000:9000"]}
	]}`
	if err := os.WriteFile(path, []byte(source), 0o600); err != nil {
		t.Fatal(err)
	}
	config := `{"outbounds": [{"type": "direct", "tag": "direct"}],
		"route": {"rule_set": [{"type": "local", "tag": "p", "format": "source", "path": "` + path + `"}],
		"rules": [{"rule_set": "p", "outbound": "direct"}]}}`
	if err := NewDesktopService(t.TempDir(), t.TempDir()).CheckConfig(context.Background(), config); err != nil {
		t.Fatalf("the core rejects converted rule-set fields: %v", err)
	}
}
