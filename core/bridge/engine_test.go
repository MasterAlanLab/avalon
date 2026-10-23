package bridge

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/sagernet/sing-box/daemon"
	"github.com/sagernet/sing-box/log"
)

// A plan as the compiler writes them, small: a mixed inbound on the
// loopback, a selector over two exits, and the mode rules.
func plan(port int, extra string) string {
	return fmt.Sprintf(`{
  "log": {"level": "debug"},
  "inbounds": [{"type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": %d}],
  "outbounds": [
    {"type": "selector", "tag": "proxy", "outbounds": ["a", "b"], "default": "a"},
    {"type": "direct", "tag": "a"},
    {"type": "direct", "tag": "b"},
    {"type": "direct", "tag": "direct"}
  ],
  "route": {
    "rules": [
      {"clash_mode": "direct", "outbound": "direct"},
      {"clash_mode": "global", "outbound": "proxy"}
    ],
    "final": "proxy"
  },
  "experimental": {"clash_api": {"default_mode": "rule"}}%s
}`, port, extra)
}

func freePort(t *testing.T) int {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	return listener.Addr().(*net.TCPAddr).Port
}

func newEngine(t *testing.T) *Engine {
	t.Helper()
	engine := NewEngine(NewDesktopService(t.TempDir(), t.TempDir()), "test", t.TempDir())
	t.Cleanup(engine.Close)
	return engine
}

// call sends a command and decodes its result into out (when not nil).
func call(t *testing.T, e *Engine, command string, request any, out any) *Error {
	t.Helper()
	raw, err := json.Marshal(request)
	if err != nil {
		t.Fatal(err)
	}
	var response struct {
		Result json.RawMessage `json:"result"`
		Error  *Error          `json:"error"`
	}
	if err := json.Unmarshal(e.Call(command, raw), &response); err != nil {
		t.Fatalf("%s: malformed response: %v", command, err)
	}
	if response.Error == nil && out != nil {
		if err := json.Unmarshal(response.Result, out); err != nil {
			t.Fatalf("%s: malformed result: %v", command, err)
		}
	}
	return response.Error
}

func mustStart(t *testing.T, e *Engine, port int) string {
	t.Helper()
	var session sessionResult
	request := map[string]any{"requestId": "start-1", "plan": json.RawMessage(plan(port, "")), "planHash": "hash-1"}
	if err := call(t, e, "start", request, &session); err != nil {
		t.Fatalf("start: %v", err)
	}
	return session.SessionID
}

func snapshot(t *testing.T, e *Engine) Snapshot {
	t.Helper()
	var s Snapshot
	if err := call(t, e, "snapshot", struct{}{}, &s); err != nil {
		t.Fatalf("snapshot: %v", err)
	}
	return s
}

// through returns an HTTP client that goes through the mixed inbound.
func through(port int) *http.Client {
	proxy, _ := url.Parse(fmt.Sprintf("http://127.0.0.1:%d", port))
	return &http.Client{
		Timeout: 2 * time.Second,
		Transport: &http.Transport{
			Proxy:             http.ProxyURL(proxy),
			DisableKeepAlives: true,
		},
	}
}

func origin(t *testing.T) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, strings.Repeat("avalon ", 512))
	}))
	t.Cleanup(server.Close)
	return server
}

func TestSessionLifecycle(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	server := origin(t)

	if s := snapshot(t, e); s.State != StateStopped || s.SessionID != "" {
		t.Fatalf("before start: %+v", s)
	}
	session := mustStart(t, e, port)

	s := snapshot(t, e)
	if s.State != StateRunning || s.SessionID != session || s.PlanHash != "hash-1" {
		t.Fatalf("after start: %+v", s)
	}
	if age := time.Since(time.UnixMilli(s.StartedAt)); age < 0 || age > 5*time.Second {
		t.Fatalf("startedAt should be now: %v ago", age)
	}
	if s.Selections["proxy"] != "a" {
		t.Fatalf("selector should start on its default: %+v", s.Selections)
	}
	if !strings.EqualFold(s.Mode, "rule") {
		t.Fatalf("mode should be the plan's default: %q", s.Mode)
	}

	// Traffic really flows through the core and is counted.
	response, err := through(port).Get(server.URL)
	if err != nil {
		t.Fatalf("request through the proxy: %v", err)
	}
	body, _ := io.ReadAll(response.Body)
	response.Body.Close()
	if !strings.HasPrefix(string(body), "avalon ") {
		t.Fatalf("unexpected body: %q", body[:16])
	}
	if s = snapshot(t, e); s.DownTotal < int64(len(body)) {
		t.Fatalf("download not counted: %d < %d", s.DownTotal, len(body))
	}

	// Selecting and switching the mode take effect without a restart.
	if err := call(t, e, "select", selectRequest{RequestID: "sel", SessionID: session, GroupTag: "proxy", MemberTag: "b"}, nil); err != nil {
		t.Fatalf("select: %v", err)
	}
	if err := call(t, e, "setMode", setModeRequest{RequestID: "mode", SessionID: session, Mode: "direct"}, nil); err != nil {
		t.Fatalf("setMode: %v", err)
	}
	s = snapshot(t, e)
	if s.Selections["proxy"] != "b" || !strings.EqualFold(s.Mode, "direct") || s.SessionID != session {
		t.Fatalf("after select and setMode: %+v", s)
	}
	if err := call(t, e, "select", selectRequest{SessionID: session, GroupTag: "proxy", MemberTag: "nowhere"}, nil); err == nil {
		t.Fatal("selecting a member the group does not have should fail")
	}
	if s = snapshot(t, e); s.Selections["proxy"] != "b" {
		t.Fatalf("a failed select must leave the choice alone: %+v", s.Selections)
	}

	// A command for another session is refused.
	if err := call(t, e, "setMode", setModeRequest{SessionID: "other", Mode: "global"}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("stale session: %v", err)
	}
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(plan(port, "")), "planHash": "x"}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("start over a running session: %v", err)
	}

	if err := call(t, e, "stop", stopRequest{RequestID: "stop-1"}, nil); err != nil {
		t.Fatalf("stop: %v", err)
	}
	if s = snapshot(t, e); s.State != StateStopped || s.SessionID != "" || s.PlanHash != "" || s.StartedAt != 0 {
		t.Fatalf("after stop: %+v", s)
	}
	if _, err := through(port).Get(server.URL); err == nil {
		t.Fatal("the port should be closed after stop")
	}
	if s.Revision <= 1 {
		t.Fatalf("revision should grow: %d", s.Revision)
	}
}

func TestSetModeReportsTheActualCoreResult(t *testing.T) {
	e := newEngine(t)
	// With no rule condition or rule default, the core only registers
	// direct and global. Its SetClashMode silently ignores rule.
	withoutRule := strings.Replace(plan(freePort(t), ""), `"default_mode": "rule"`, `"default_mode": "global"`, 1)
	var session sessionResult
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(withoutRule), "planHash": "without-rule"}, &session); err != nil {
		t.Fatal(err)
	}
	if err := call(t, e, "setMode", setModeRequest{SessionID: session.SessionID, Mode: "direct"}, nil); err != nil {
		t.Fatal(err)
	}
	request := setModeRequest{RequestID: "missing-rule", SessionID: session.SessionID, Mode: "rule"}
	if err := call(t, e, "setMode", request, nil); err == nil || err.Code != CodeCoreFailed {
		t.Fatalf("a mode the core ignores must fail: %v", err)
	}
	if s := snapshot(t, e); s.State != StateRunning || s.SessionID != session.SessionID || s.Mode != "direct" {
		t.Fatalf("a refused mode must leave the session and actual mode alone: %+v", s)
	}
	var command CommandStatus
	if err := call(t, e, "queryCommand", queryRequest{RequestID: request.RequestID}, &command); err != nil {
		t.Fatal(err)
	}
	if command.Status != "failed" || command.Error == nil || command.Error.Code != CodeCoreFailed {
		t.Fatalf("a refused mode must also be remembered as failed: %+v", command)
	}
	if err := call(t, e, "setMode", setModeRequest{SessionID: session.SessionID, Mode: "GLOBAL"}, nil); err != nil {
		t.Fatal(err)
	}
	if s := snapshot(t, e); s.SessionID != session.SessionID || !strings.EqualFold(s.Mode, "global") {
		t.Fatalf("an available mode must still take effect: %+v", s)
	}
}

func TestReloadIsARestart(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	server := origin(t)
	session := mustStart(t, e, port)
	var reloaded sessionResult
	request := map[string]any{
		"requestId": "reload-1", "sessionId": session,
		"plan": json.RawMessage(plan(port, "")), "planHash": "hash-2",
	}
	if err := call(t, e, "reload", request, &reloaded); err != nil {
		t.Fatalf("reload: %v", err)
	}
	if reloaded.Method != ReloadRestart {
		t.Fatalf("method: %q", reloaded.Method)
	}
	if reloaded.SessionID == session || reloaded.SessionID == "" {
		t.Fatalf("a restart is a new session: %q", reloaded.SessionID)
	}
	s := snapshot(t, e)
	if s.State != StateRunning || s.SessionID != reloaded.SessionID || s.PlanHash != "hash-2" {
		t.Fatalf("after reload: %+v", s)
	}
	response, err := through(port).Get(server.URL)
	if err != nil {
		t.Fatalf("the reloaded proxy did not answer: %v", err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil || string(body) != strings.Repeat("avalon ", 512) {
		t.Fatalf("the reloaded proxy returned an invalid response: %v", err)
	}
	// The old session's id no longer works.
	if err := call(t, e, "select", selectRequest{SessionID: session, GroupTag: "proxy", MemberTag: "b"}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("old session: %v", err)
	}
}

func TestPlanFromAFile(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	path := filepath.Join(t.TempDir(), "plan.json")
	if err := os.WriteFile(path, []byte(plan(port, "")), 0o600); err != nil {
		t.Fatal(err)
	}
	var session sessionResult
	if err := call(t, e, "start", map[string]any{"requestId": "f", "planPath": path, "planHash": "file"}, &session); err != nil {
		t.Fatalf("start from a file: %v", err)
	}
	if s := snapshot(t, e); s.State != StateRunning || s.PlanHash != "file" {
		t.Fatalf("after start: %+v", s)
	}
	// A reload reads the file again.
	if err := call(t, e, "reload", map[string]any{"sessionId": session.SessionID, "planPath": path, "planHash": "file2"}, nil); err != nil {
		t.Fatalf("reload from a file: %v", err)
	}
	// Neither a plan nor a readable file: refused before anything stops.
	running := snapshot(t, e).SessionID
	for _, request := range []map[string]any{
		{"sessionId": running, "planHash": "x"},
		{"sessionId": running, "planPath": filepath.Join(t.TempDir(), "missing.json"), "planHash": "x"},
	} {
		if err := call(t, e, "reload", request, nil); err == nil || err.Code != CodePlanInvalid {
			t.Fatalf("a reload without a plan: %v", err)
		}
	}
	if s := snapshot(t, e); s.State != StateRunning || s.SessionID != running {
		t.Fatalf("the session should still run: %+v", s)
	}
}

func TestThePlanWinsOverTheCoreMemory(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	session := mustStart(t, e, port)

	// Changed while running: the core stores both in its cache file.
	if err := call(t, e, "select", selectRequest{SessionID: session, GroupTag: "proxy", MemberTag: "b"}, nil); err != nil {
		t.Fatal(err)
	}
	if err := call(t, e, "setMode", setModeRequest{SessionID: session, Mode: "direct"}, nil); err != nil {
		t.Fatal(err)
	}

	// The next plan says otherwise (the user chose again), and it rules.
	request := map[string]any{"sessionId": session, "plan": json.RawMessage(plan(port, "")), "planHash": "h2"}
	if err := call(t, e, "reload", request, nil); err != nil {
		t.Fatal(err)
	}
	s := snapshot(t, e)
	if s.Selections["proxy"] != "a" || !strings.EqualFold(s.Mode, "rule") {
		t.Fatalf("the plan's choices should apply: %+v", s)
	}
}

func TestLogsFollowThePlanLevel(t *testing.T) {
	e := newEngine(t)
	// The helper plan asks for debug; this one for warnings only.
	quiet := strings.Replace(plan(freePort(t), ""), `"level": "debug"`, `"level": "warn"`, 1)
	if level := planLogLevel([]byte(quiet)); level != log.LevelWarn {
		t.Fatalf("the plan's log level: %v, want warn", level)
	}
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(quiet), "planHash": "q"}, nil); err != nil {
		t.Fatal(err)
	}
	// Exercise the real stream receiver with known lines. Info also checks
	// that start loaded warn instead of keeping NewEngine's default info.
	after := e.logs.page(0, logBufferSize).NextSeq
	stream := logStream{engine: e}
	if err := stream.Send(&daemon.Log{Messages: []*daemon.Log_Message{
		{Level: daemon.LogLevel(log.LevelDebug), Message: "debug entry"},
		{Level: daemon.LogLevel(log.LevelInfo), Message: "info entry"},
		{Level: daemon.LogLevel(log.LevelWarn), Message: "warn entry"},
		{Level: daemon.LogLevel(log.LevelError), Message: "error entry"},
	}}); err != nil {
		t.Fatal(err)
	}
	page := e.logs.page(after, logBufferSize)
	if len(page.Entries) != 2 ||
		page.Entries[0].Level != "warn" || page.Entries[0].Message != "warn entry" ||
		page.Entries[1].Level != "error" || page.Entries[1].Message != "error entry" {
		t.Fatalf("warn-level plan must retain exactly warn/error: %+v", page.Entries)
	}
}

func TestFailures(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)

	// Not a plan at all.
	bad := map[string]any{"requestId": "bad", "plan": json.RawMessage(`{"inbounds": [{"type": "nonsense"}]}`), "planHash": "x"}
	err := call(t, e, "start", bad, nil)
	if err == nil || err.Code != CodePlanInvalid {
		t.Fatalf("invalid plan: %v", err)
	}
	if s := snapshot(t, e); s.State != StateFailed || s.Error == nil || s.PlanHash != "" {
		t.Fatalf("after a failed start: %+v", s)
	}

	// The port is taken by someone else.
	taken, listenErr := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if listenErr != nil {
		t.Fatal(listenErr)
	}
	err = call(t, e, "start", map[string]any{"requestId": "busy", "plan": json.RawMessage(plan(port, "")), "planHash": "x"}, nil)
	taken.Close()
	if err == nil || err.Code != CodePortInUse {
		t.Fatalf("port in use: %v", err)
	}

	// A failed start does not block the next one.
	session := mustStart(t, e, port)

	// A reload with a plan the core cannot load is refused and the session
	// goes on (RUNTIME_HOST §5).
	request := map[string]any{"requestId": "r", "sessionId": session, "plan": json.RawMessage(`{"outbounds": [{"type": "nonsense"}]}`), "planHash": "y"}
	if err := call(t, e, "reload", request, nil); err == nil || err.Code != CodePlanInvalid {
		t.Fatalf("reload with a bad plan: %v", err)
	}
	if s := snapshot(t, e); s.State != StateRunning || s.SessionID != session || s.PlanHash != "hash-1" {
		t.Fatalf("the session should have survived: %+v", s)
	}
	server := origin(t)
	if response, err := through(port).Get(server.URL); err != nil {
		t.Fatalf("traffic should still flow: %v", err)
	} else {
		response.Body.Close()
	}

	// One that loads but cannot start has cost the old instance: the daemon
	// closed it first. Here the new plan wants a port someone else holds.
	other := freePort(t)
	holder, listenErr := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", other))
	if listenErr != nil {
		t.Fatal(listenErr)
	}
	defer holder.Close()
	request = map[string]any{"requestId": "r2", "sessionId": session, "plan": json.RawMessage(plan(other, "")), "planHash": "z"}
	if err := call(t, e, "reload", request, nil); err == nil || err.Code != CodePortInUse {
		t.Fatalf("reload onto a taken port: %v", err)
	}
	if s := snapshot(t, e); s.State != StateFailed {
		t.Fatalf("after a failed restart: %+v", s)
	}

	if err := call(t, e, "nonsense", struct{}{}, nil); err == nil || err.Code != CodeUnsupported {
		t.Fatalf("unknown command: %v", err)
	}
}

func TestQueryCommand(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	mustStart(t, e, port)

	var status CommandStatus
	if err := call(t, e, "queryCommand", queryRequest{RequestID: "start-1"}, &status); err != nil {
		t.Fatal(err)
	}
	if status.Status != "done" {
		t.Fatalf("a finished command: %+v", status)
	}
	_ = call(t, e, "select", selectRequest{RequestID: "sel-bad", SessionID: "other", GroupTag: "proxy", MemberTag: "b"}, nil)
	if err := call(t, e, "queryCommand", queryRequest{RequestID: "sel-bad"}, &status); err != nil {
		t.Fatal(err)
	}
	if status.Status != "failed" || status.Error == nil || status.Error.Code != CodeSessionMismatch {
		t.Fatalf("a failed command: %+v", status)
	}
	if err := call(t, e, "queryCommand", queryRequest{RequestID: "never-sent"}, &status); err != nil {
		t.Fatal(err)
	}
	if status.Status != "unknown" {
		t.Fatalf("an unknown command: %+v", status)
	}
}

func TestLogs(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	server := origin(t)
	session := mustStart(t, e, port)
	response, err := through(port).Get(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()

	var first LogPage
	deadline := time.Now().Add(3 * time.Second)
	for {
		if err := call(t, e, "logs", logsRequest{AfterSeq: 0, Limit: 500}, &first); err != nil {
			t.Fatal(err)
		}
		if len(first.Entries) > 0 || time.Now().After(deadline) {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if len(first.Entries) == 0 {
		t.Fatal("the core's log lines should arrive")
	}
	for i, entry := range first.Entries {
		if age := time.Since(time.UnixMilli(entry.Time)); age < 0 || age > time.Minute {
			t.Fatalf("entry %d has no time of its own: %+v", i, entry)
		}
		if entry.Seq != int64(i+1) || entry.Level == "" || entry.Message == "" {
			t.Fatalf("entry %d: %+v", i, entry)
		}
	}
	if first.NextSeq != first.Entries[len(first.Entries)-1].Seq {
		t.Fatalf("nextSeq: %d", first.NextSeq)
	}

	// Sequence numbers go on across a reload; earlier lines stay.
	request := map[string]any{"sessionId": session, "plan": json.RawMessage(plan(port, "")), "planHash": "h"}
	if err := call(t, e, "reload", request, nil); err != nil {
		t.Fatal(err)
	}
	var next LogPage
	deadline = time.Now().Add(3 * time.Second)
	for {
		if err := call(t, e, "logs", logsRequest{AfterSeq: first.NextSeq, Limit: 500}, &next); err != nil {
			t.Fatal(err)
		}
		if len(next.Entries) > 0 || time.Now().After(deadline) {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if len(next.Entries) == 0 || next.Entries[0].Seq != first.NextSeq+1 || next.Dropped != 0 {
		t.Fatalf("after reload: %d entries, first %+v, dropped %d", len(next.Entries), next.Entries, next.Dropped)
	}
}
