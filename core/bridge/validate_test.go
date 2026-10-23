package bridge

import "testing"

func TestHostPreflightKeepsTheRunningSession(t *testing.T) {
	engine := newEngine(t)
	port := freePort(t)
	session := mustStart(t, engine, port)
	if err := engine.ValidatePlan([]byte(`{"outbounds":[{"type":"not-a-protocol"}]}`)); err == nil {
		t.Fatal("accepted invalid candidate")
	}
	if actual := snapshot(t, engine); actual.State != StateRunning || actual.SessionID != session {
		t.Fatalf("invalid preflight changed the active session: %+v", actual)
	}
	if err := engine.ValidatePlan([]byte(plan(port, ""))); err != nil {
		t.Fatal(err)
	}
	if actual := snapshot(t, engine); actual.State != StateRunning || actual.SessionID != session {
		t.Fatalf("successful preflight changed the active session: %+v", actual)
	}
}
