package bridge

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"runtime"
	"strings"
	"sync"
	"testing"
)

func controllerPlan(t *testing.T, mixedPort int, controller string) json.RawMessage {
	t.Helper()
	var config map[string]any
	if err := json.Unmarshal([]byte(plan(mixedPort, "")), &config); err != nil {
		t.Fatal(err)
	}
	config["experimental"].(map[string]any)["clash_api"].(map[string]any)["external_controller"] = controller
	encoded, err := json.Marshal(config)
	if err != nil {
		t.Fatal(err)
	}
	return encoded
}

func assertInactive(t *testing.T, s Snapshot) {
	t.Helper()
	if s.ProxyActive || s.TailnetActive || s.TunActive || s.SystemProxyActive || s.ClashAPIListen != "" {
		t.Fatalf("no runtime should be active: %+v", s)
	}
}

func TestSnapshotReportsAcceptedRuntimeAfterRefusedReload(t *testing.T) {
	e := newEngine(t)
	assertInactive(t, snapshot(t, e))
	port := freePort(t)
	controller := fmt.Sprintf("127.0.0.1:%d", freePort(t))
	var session sessionResult
	request := map[string]any{
		"requestId": "start-controller", "plan": controllerPlan(t, port, controller), "planHash": "accepted",
	}
	if err := call(t, e, "start", request, &session); err != nil {
		t.Fatal(err)
	}
	s := snapshot(t, e)
	if !s.ProxyActive || s.TailnetActive || s.TunActive || s.SystemProxyActive || s.ClashAPIListen != controller {
		t.Fatalf("the mixed listener and controller should be active: %+v", s)
	}
	response, err := http.Get("http://" + controller + "/version")
	if err != nil {
		t.Fatalf("the reported controller is not listening: %v", err)
	}
	response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("the reported controller returned %d", response.StatusCode)
	}

	// Rejected before closing the core: the new plan's disabled controller
	// and desired runtime flags must not replace the working instance.
	if err := call(t, e, "reload", map[string]any{
		"requestId": "invalid-controller", "sessionId": session.SessionID,
		"plan": json.RawMessage(`{"outbounds":[{"type":"invalid"}]}`), "planHash": "rejected",
	}, nil); err == nil || err.Code != CodePlanInvalid {
		t.Fatalf("expected an invalid plan: %v", err)
	}
	s = snapshot(t, e)
	if s.SessionID != session.SessionID || s.PlanHash != "accepted" || !s.ProxyActive || s.ClashAPIListen != controller {
		t.Fatalf("the snapshot must still describe the old session: %+v", s)
	}
	// Once the replacement succeeds, disabling the controller must be
	// visible even though the old address was kept across the rejection.
	if err := call(t, e, "reload", map[string]any{
		"requestId": "controller-off", "sessionId": session.SessionID,
		"plan": json.RawMessage(plan(port, "")), "planHash": "controller-off",
	}, nil); err != nil {
		t.Fatal(err)
	}
	s = snapshot(t, e)
	if !s.ProxyActive || s.ClashAPIListen != "" || s.PlanHash != "controller-off" {
		t.Fatalf("a successful replacement should report its own listener: %+v", s)
	}
	if err := call(t, e, "stop", stopRequest{RequestID: "stop-controller"}, nil); err != nil {
		t.Fatal(err)
	}
	assertInactive(t, snapshot(t, e))
}

func TestSnapshotActivityClearsWhenReloadCostsTheSession(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	controller := fmt.Sprintf("127.0.0.1:%d", freePort(t))
	var session sessionResult
	if err := call(t, e, "start", map[string]any{
		"requestId": "start", "plan": controllerPlan(t, port, controller), "planHash": "accepted",
	}, &session); err != nil {
		t.Fatal(err)
	}
	holder, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer holder.Close()
	taken := holder.Addr().(*net.TCPAddr).Port
	if err := call(t, e, "reload", map[string]any{
		"requestId": "busy", "sessionId": session.SessionID,
		"plan": json.RawMessage(plan(taken, "")), "planHash": "cannot-start",
	}, nil); err == nil || err.Code != CodePortInUse {
		t.Fatalf("expected a taken port: %v", err)
	}
	s := snapshot(t, e)
	if s.State != StateFailed {
		t.Fatalf("expected a failed session: %+v", s)
	}
	assertInactive(t, s)
}

func TestSnapshotWireIncludesInactiveFactsWithoutControllerSecrets(t *testing.T) {
	e := newEngine(t)
	var response struct {
		Result map[string]any `json:"result"`
	}
	raw := e.Call("snapshot", nil)
	if err := json.Unmarshal(raw, &response); err != nil {
		t.Fatal(err)
	}
	for _, field := range []string{"proxyActive", "tailnetActive", "tunActive", "systemProxyActive"} {
		if value, ok := response.Result[field]; !ok || value != false {
			t.Fatalf("inactive fact %s missing or not false: %s", field, raw)
		}
	}
	if listen, ok := response.Result["clashApiListen"]; !ok || listen != "" {
		t.Fatalf("disabled controller must be reported: %s", raw)
	}
	controller := fmt.Sprintf("127.0.0.1:%d", freePort(t))
	var config map[string]any
	if err := json.Unmarshal(controllerPlan(t, freePort(t), controller), &config); err != nil {
		t.Fatal(err)
	}
	config["experimental"].(map[string]any)["clash_api"].(map[string]any)["secret"] = "private-value"
	if err := call(t, e, "start", map[string]any{
		"requestId": "secret", "plan": config, "planHash": "controller",
	}, nil); err != nil {
		t.Fatal(err)
	}
	raw = e.Call("snapshot", nil)
	if strings.Contains(string(raw), "private-value") || strings.Contains(string(raw), `"secret"`) {
		t.Fatalf("the snapshot leaked controller credentials: %s", raw)
	}
	if s := snapshot(t, e); s.ClashAPIListen != controller {
		t.Fatalf("the listener fact must contain only its address: %+v", s)
	}
}

func TestSnapshotActivityStaysWithItsSessionDuringReloads(t *testing.T) {
	e := newEngine(t)
	controller := fmt.Sprintf("127.0.0.1:%d", freePort(t))
	proxyPlan := controllerPlan(t, freePort(t), controller)
	var noProxyConfig map[string]any
	if err := json.Unmarshal(proxyPlan, &noProxyConfig); err != nil {
		t.Fatal(err)
	}
	noProxyConfig["inbounds"] = []any{}
	delete(noProxyConfig["experimental"].(map[string]any)["clash_api"].(map[string]any), "external_controller")
	noProxyPlan, err := json.Marshal(noProxyConfig)
	if err != nil {
		t.Fatal(err)
	}
	var session sessionResult
	if err := call(t, e, "start", map[string]any{
		"requestId": "start-concurrent", "plan": proxyPlan, "planHash": "proxy-on",
	}, &session); err != nil {
		t.Fatal(err)
	}

	done := make(chan struct{})
	inconsistent := make(chan Snapshot, 1)
	var readers sync.WaitGroup
	for range 8 {
		readers.Go(func() {
			for {
				select {
				case <-done:
					return
				default:
				}
				s := e.Snapshot()
				if s.State == StateRunning {
					wantProxy := s.PlanHash == "proxy-on"
					wantController := ""
					if wantProxy {
						wantController = controller
					}
					if s.ProxyActive != wantProxy || s.ClashAPIListen != wantController || s.SessionID == "" || s.TunActive || s.TailnetActive || s.SystemProxyActive {
						select {
						case inconsistent <- s:
						default:
						}
						return
					}
				}
				runtime.Gosched()
			}
		})
	}
	stopReaders := sync.OnceFunc(func() {
		close(done)
		readers.Wait()
	})
	t.Cleanup(stopReaders)
	for i := range 12 {
		nextPlan := json.RawMessage(noProxyPlan)
		hash := "proxy-off"
		if i%2 == 1 {
			nextPlan, hash = proxyPlan, "proxy-on"
		}
		if err := call(t, e, "reload", map[string]any{
			"requestId": fmt.Sprintf("reload-%d", i), "sessionId": session.SessionID,
			"plan": nextPlan, "planHash": hash,
		}, &session); err != nil {
			t.Fatal(err)
		}
		// Keep polling during real starts and closes rather than queueing
		// snapshots behind the lifecycle lock.
		runtime.Gosched()
	}
	stopReaders()
	select {
	case s := <-inconsistent:
		t.Fatalf("activity from another instance was paired with the session: %+v", s)
	default:
	}
}
