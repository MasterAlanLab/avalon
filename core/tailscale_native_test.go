//go:build with_gvisor && !no_tailscale

package main

import (
	"github.com/metacubex/tailscale/ipn"
	"github.com/metacubex/tailscale/ipn/ipnstate"
	"testing"
)

func TestTSControlValidation(t *testing.T) {
	control, err := tsValidateControl("")
	if err != nil || control != ipn.DefaultControlURL {
		t.Fatal("dependency default not used")
	}
	for _, s := range []string{"https://USER:PASS@HOST", "https://HOST?TOKEN=secret", "https://HOST#TOKEN", "http://remote.example", "not a url", "file:///state"} {
		if _, err := tsValidateControl(s); err == nil {
			t.Fatalf("bad control accepted: %s", s)
		}
	}
	if _, err := tsValidateControl("http://127.0.0.1:8080"); err != nil {
		t.Fatal(err)
	}
}
func TestTSBackendRealStateMapping(t *testing.T) {
	for state, want := range map[string]string{"NeedsMachineAuth": "waitingApproval", "Running": "running", "Stopped": "paused", "NeedsLogin": "needsLogin", "Starting": "starting"} {
		s := normalizeTSStatus(&ipnstate.Status{BackendState: state})
		if s.Session != want {
			t.Fatalf("%s => %s", state, s.Session)
		}
	}
	s := normalizeTSStatus(&ipnstate.Status{BackendState: "NeedsLogin", AuthURL: "https://HOST/a/TOKEN"})
	if s.Session != "authorizing" || s.AuthURL != "https://HOST/a/TOKEN" {
		t.Fatal("backend URL not preserved for controlled UI")
	}
}

func TestTSSwitchServerRevokesPreviousIdentity(t *testing.T) {
	m, b := testTSManager(t)
	runTS(t, m)
	if _, err := m.Begin("browser", "not a url", ""); err == nil || err.Error() != "invalid_control_url" {
		t.Fatal("invalid switch destination accepted")
	}
	b.mu.Lock()
	loggedOut := b.loggedOut
	b.mu.Unlock()
	if loggedOut || m.Snapshot().Session != "running" {
		t.Fatal("invalid switch revoked old identity")
	}
	if _, err := m.Begin("browser", " https://new.head.example/ ", ""); err != nil {
		t.Fatal(err)
	}
	eventuallyTS(t, func() bool { return m.Snapshot().Session == "running" })
	b.mu.Lock()
	loggedOut = b.loggedOut
	b.mu.Unlock()
	if !loggedOut {
		t.Fatal("server switch left old identity active")
	}
	if m.disk.Control != "https://new.head.example" {
		t.Fatal("server switch did not use validated destination")
	}
}
