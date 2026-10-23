package bridge

import (
	"encoding/json"
	"fmt"
	"net"
	"strings"
	"testing"
	"time"
)

// A plan with exits that behave differently: two that work, one whose
// server refuses connections, one whose server never answers.
func latencyPlan(t *testing.T, port int) (string, func()) {
	t.Helper()
	refused := freePort(t) // Nothing listens there.
	silent, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	// Accepts and says nothing, so a SOCKS handshake through it hangs.
	go func() {
		for {
			connection, err := silent.Accept()
			if err != nil {
				return
			}
			defer connection.Close()
		}
	}()
	plan := fmt.Sprintf(`{
  "log": {"level": "warn"},
  "inbounds": [{"type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": %d}],
  "outbounds": [
    {"type": "selector", "tag": "proxy", "outbounds": ["a", "b"], "default": "a"},
    {"type": "direct", "tag": "a"},
    {"type": "direct", "tag": "b"},
    {"type": "socks", "tag": "refused", "server": "127.0.0.1", "server_port": %d},
    {"type": "socks", "tag": "silent", "server": "127.0.0.1", "server_port": %d}
  ],
  "route": {"rules": [{"clash_mode": "direct", "outbound": "a"}], "final": "proxy"},
  "experimental": {"clash_api": {"default_mode": "rule"}}
}`, port, refused, silent.Addr().(*net.TCPAddr).Port)
	return plan, func() { silent.Close() }
}

func TestURLTestInTheRunningSession(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	server := origin(t)
	plan, done := latencyPlan(t, port)
	defer done()
	var session sessionResult
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(plan), "planHash": "h"}, &session); err != nil {
		t.Fatal(err)
	}

	var response urlTestResponse
	request := map[string]any{
		"requestId": "t1", "sessionId": session.SessionID,
		"tags": []string{"a", "b", "proxy", "refused", "silent", "nowhere"},
		"url":  server.URL, "timeoutMs": 400,
	}
	began := time.Now()
	if err := call(t, e, "urlTest", request, &response); err != nil {
		t.Fatalf("urlTest: %v", err)
	}
	// Measured side by side: the slowest sets the pace, not the sum.
	if took := time.Since(began); took > 2*time.Second {
		t.Fatalf("took %v", took)
	}
	for _, tag := range []string{"a", "b", "proxy"} {
		if r := response.Results[tag]; r.DelayMs <= 0 || r.Error != "" {
			t.Fatalf("%s should have answered: %+v", tag, r)
		}
	}
	if r := response.Results["silent"]; r.Error != "timeout" {
		t.Fatalf("an exit that never answers: %+v", r)
	}
	if r := response.Results["refused"]; r.Error == "" || r.Error == "timeout" || r.DelayMs != 0 {
		t.Fatalf("an exit that refuses: %+v", r)
	}
	if r := response.Results["nowhere"]; !strings.Contains(r.Error, "not found") {
		t.Fatalf("a tag the plan does not have: %+v", r)
	}
	// The session is the same one afterwards.
	if s := snapshot(t, e); s.State != StateRunning || s.SessionID != session.SessionID {
		t.Fatalf("after the test: %+v", s)
	}
	if err := call(t, e, "urlTest", map[string]any{"sessionId": "other", "tags": []string{"a"}, "url": server.URL}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("another session: %v", err)
	}
}

func TestURLTestWithNothingRunning(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	server := origin(t)
	plan, done := latencyPlan(t, port)
	defer done()

	var response urlTestResponse
	request := map[string]any{
		"requestId": "probe", "plan": json.RawMessage(plan),
		"tags": []string{"a", "silent"}, "url": server.URL, "timeoutMs": 300,
	}
	if err := call(t, e, "urlTest", request, &response); err != nil {
		t.Fatalf("urlTest: %v", err)
	}
	if r := response.Results["a"]; r.DelayMs <= 0 {
		t.Fatalf("a: %+v", r)
	}
	if r := response.Results["silent"]; r.Error != "timeout" {
		t.Fatalf("silent: %+v", r)
	}
	// Nothing was taken over: no session, and the plan's port is free.
	if s := snapshot(t, e); s.State != StateStopped || s.SessionID != "" {
		t.Fatalf("after a probe: %+v", s)
	}
	listener, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		t.Fatalf("the probe must not listen on the plan's port: %v", err)
	}
	listener.Close()

	// And a session can start right after.
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(plan), "planHash": "h"}, nil); err != nil {
		t.Fatalf("start after a probe: %v", err)
	}
	// While one runs, a probe is refused: test in the session instead.
	if err := call(t, e, "urlTest", request, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("a probe beside a session: %v", err)
	}
}

func TestProbePlan(t *testing.T) {
	probe, err := probePlan([]byte(`{
  "log": {"level": "info"},
  "dns": {"servers": [{"type": "udp", "tag": "direct", "server": "223.5.5.5"}],
          "rules": [{"rule_set": "geosite-cn", "server": "direct"}], "final": "direct"},
  "inbounds": [{"type": "tun", "tag": "tun-in"}],
  "outbounds": [{"type": "direct", "tag": "direct"}],
  "route": {"rules": [{"action": "sniff"}], "rule_set": [{"tag": "geosite-cn"}],
            "final": "direct", "auto_detect_interface": true, "default_domain_resolver": "direct"},
  "experimental": {"clash_api": {"external_controller": "127.0.0.1:9090"}}
}`))
	if err != nil {
		t.Fatal(err)
	}
	var tree map[string]any
	if err := json.Unmarshal(probe, &tree); err != nil {
		t.Fatal(err)
	}
	if _, has := tree["inbounds"]; has {
		t.Fatal("a probe has no inbounds")
	}
	if _, has := tree["experimental"]; has {
		t.Fatal("a probe has no controller")
	}
	route := tree["route"].(map[string]any)
	if route["rules"] != nil || route["rule_set"] != nil {
		t.Fatalf("a probe has no rules: %v", route)
	}
	if route["default_domain_resolver"] != "direct" || route["auto_detect_interface"] != true {
		t.Fatalf("what dialling needs stays: %v", route)
	}
	dns := tree["dns"].(map[string]any)
	if dns["rules"] != nil || dns["servers"] == nil {
		t.Fatalf("dns: %v", dns)
	}
	if tree["outbounds"] == nil {
		t.Fatal("the outbounds stay")
	}
}
