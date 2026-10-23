package bridge

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/sagernet/sing-box/adapter"
	C "github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/daemon"
	"github.com/sagernet/sing-box/log"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

const (
	logBufferSize   = 2000 // RUNTIME_HOST §6
	resultCacheSize = 64   // RUNTIME_HOST §2
)

// Engine runs one session on sing-box's daemon service and answers the
// bridge commands. Lifecycle commands (start, reload, stop) run one at a
// time; the others may be called at any moment.
type Engine struct {
	background sync.WaitGroup
	service    *daemon.StartedService
	platform   string

	lifecycle sync.Mutex

	mu             sync.Mutex
	state          State
	sessionID      string
	planHash       string
	clashAPIListen string
	lastError      *Error
	revision       int64
	startedAt      time.Time
	sampleAt       time.Time
	sampleUp       int64
	sampleDn       int64

	logs    *logBuffer
	results *resultCache
	today   *dayTotals
	cancel  context.CancelFunc
	// The plan's log level. The core hands a platform writer every line
	// whatever the level, so the engine keeps only what the plan asked for.
	logLevel atomic.Int32

	// Set by desktop hosts (ReportTun); nil on mobile.
	tunAvailable func() bool
	// Injectable only for package tests; production resolves through the OS.
	publicLookup publicLookup
}

// How often the day's traffic is written down (RUNTIME_HOST §6).
const trafficSaveInterval = 30 * time.Second

// NewEngine wraps a daemon service. The host builds the service: with the
// platform interface on Android and Apple, plain on desktop. stateDir is
// where the engine keeps its own files (the day's traffic); empty keeps
// them in memory.
// ReportTun makes capabilities say whether a TUN interface can be opened,
// as [available] tells; for hosts that know it by themselves.
func (e *Engine) ReportTun(available func() bool) { e.tunAvailable = available }

func NewEngine(service *daemon.StartedService, platform string, stateDir string) *Engine {
	ctx, cancel := context.WithCancel(context.Background())
	e := &Engine{
		service:  service,
		platform: platform,
		state:    StateStopped,
		logs:     newLogBuffer(logBufferSize),
		results:  newResultCache(resultCacheSize),
		today:    newDayTotals(stateDir),
		cancel:   cancel,
	}
	e.logLevel.Store(int32(log.LevelInfo))
	e.background.Add(2)
	go func() { defer e.background.Done(); e.collectLogs(ctx) }()
	go func() { defer e.background.Done(); e.keepTraffic(ctx) }()
	return e
}

// Close stops the session and the engine's own work.
func (e *Engine) Close() {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	// Like stop/reload, publish the transition before the daemon replaces
	// its instance, so a concurrent snapshot cannot sample it as running.
	e.setState(StateStopping, nil)
	e.countTraffic()
	_ = e.service.CloseService()
	e.today.sessionEnded()
	e.today.save()
	e.cancel()
	e.background.Wait()
	e.setState(StateStopped, nil)
}

// keepTraffic counts and saves the day's traffic while nobody asks for a
// snapshot (the app may be closed for hours).
func (e *Engine) keepTraffic(ctx context.Context) {
	ticker := time.NewTicker(trafficSaveInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			e.countTraffic()
			e.today.save()
		}
	}
}

// countTraffic adds what the running session carried since the last look
// to the day and returns the session's and the day's totals.
func (e *Engine) countTraffic() (sessionUp, sessionDown, dayUp, dayDown int64) {
	if instance := e.service.Instance(); instance != nil {
		if traffic := instance.TrafficManager(); traffic != nil {
			sessionUp, sessionDown = traffic.Total()
			dayUp, dayDown = e.today.sample(sessionUp, sessionDown)
			return
		}
	}
	dayUp, dayDown = e.today.totals()
	return
}

// Call runs one command and returns its JSON response. It never panics
// the host: a failure is a response with an error.
func (e *Engine) Call(command string, request []byte) []byte {
	result, err := e.dispatch(command, request)
	response, encodeErr := json.Marshal(Response{Result: result, Error: err})
	if encodeErr != nil {
		response, _ = json.Marshal(Response{Error: &Error{
			Code: CodeCoreFailed, Message: "encode response: " + encodeErr.Error(),
		}})
	}
	return response
}

func (e *Engine) dispatch(command string, request []byte) (any, *Error) {
	if len(request) == 0 {
		request = []byte("{}")
	}
	switch command {
	case "capabilities":
		capabilities := Capabilities{
			PublicNetworkVersion: publicNetworkVersion,
			ProtocolVersion:      ProtocolVersion,
			CoreVersion:          C.Version,
			Platform:             e.platform,
		}
		if e.tunAvailable != nil {
			tun := e.tunAvailable()
			capabilities.Tun = &tun
		}
		return capabilities, nil
	case "tailnetStatus":
		return e.tailnetStatus()
	case "tailnetLogin", "tailnetLogout":
		var r stopRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.tailnetAccount(command == "tailnetLogin") })
	case "start":
		var r startRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.start(r) })
	case "reload":
		var r startRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.reload(r) })
	case "stop":
		var r stopRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.stop() })
	case "setMode":
		var r setModeRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.setMode(r) })
	case "select":
		var r selectRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.selectMember(r) })
	case "urlTest":
		var r urlTestRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.urlTest(r) })
	case "fetch":
		var r fetchRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.fetch(r) })
	case "connections":
		var r connectionsRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.connections(r)
	case "closeConnection", "closeAllConnections":
		var r closeConnectionRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		if command == "closeAllConnections" {
			r.ID = ""
		} else if r.ID == "" {
			return nil, &Error{Code: CodePlanInvalid, Message: "no connection id"}
		}
		return e.remembered(r.RequestID, func() (any, *Error) { return e.closeConnection(r) })
	case "queryCommand":
		var r queryRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.results.status(r.RequestID), nil
	case "snapshot":
		return e.Snapshot(), nil
	case "logs":
		var r logsRequest
		if err := decode(request, &r); err != nil {
			return nil, err
		}
		return e.logs.page(r.AfterSeq, r.Limit), nil
	default:
		return nil, &Error{Code: CodeUnsupported, Message: "unknown command: " + command}
	}
}

func decode(request []byte, into any) *Error {
	if err := json.Unmarshal(request, into); err != nil {
		return &Error{Code: CodePlanInvalid, Message: "malformed request", Detail: err.Error()}
	}
	return nil
}

// remembered runs a command and keeps its outcome for queryCommand.
func (e *Engine) remembered(requestID string, run func() (any, *Error)) (any, *Error) {
	e.results.begin(requestID)
	result, err := run()
	e.results.finish(requestID, result, err)
	return result, err
}

func (e *Engine) start(r startRequest) (any, *Error) {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	if state := e.currentState(); state == StateRunning {
		return nil, &Error{Code: CodeSessionMismatch, Message: "a session is already running"}
	}
	return e.run(r, StateStarting, "")
}

func (e *Engine) reload(r startRequest) (any, *Error) {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	// The daemon closes the running instance before it starts the next. A
	// plan the core cannot even load must not cost the session that works,
	// so it is loaded once on the side first (RUNTIME_HOST §5).
	if err := loadPlan(&r); err != nil {
		return nil, err
	}
	if err := e.preparePlan(&r); err != nil {
		return nil, err
	}
	if err := e.service.CheckConfig(context.Background(), string(r.corePlan)); err != nil {
		return nil, &Error{Code: CodePlanInvalid, Message: err.Error()}
	}
	return e.run(r, StateReloading, ReloadRestart)
}

// loadPlan reads the plan of a request that names a file.
func loadPlan(r *startRequest) *Error {
	if len(r.Plan) > 0 {
		return nil
	}
	if r.PlanPath == "" {
		return &Error{Code: CodePlanInvalid, Message: "no plan given"}
	}
	plan, err := os.ReadFile(r.PlanPath)
	if err != nil {
		return &Error{Code: CodePlanInvalid, Message: "the plan file cannot be read", Detail: err.Error()}
	}
	r.Plan = plan
	return nil
}

// run starts the plan as a new session. The daemon closes a running
// instance first, so a failed reload leaves nothing running.
func (e *Engine) run(r startRequest, during State, method string) (any, *Error) {
	if err := loadPlan(&r); err != nil {
		return nil, err
	}
	if err := e.preparePlan(&r); err != nil {
		return nil, err
	}
	// The daemon closes the running instance first: count what it carried.
	e.countTraffic()
	e.today.sessionEnded()
	if r.UTCOffsetSeconds != nil {
		e.today.setOffset(time.Duration(*r.UTCOffsetSeconds) * time.Second)
	}
	session := newSessionID()
	e.logLevel.Store(int32(planLogLevel(r.Plan)))
	e.mu.Lock()
	e.state = during
	e.sessionID = session
	e.planHash = ""
	e.lastError = nil
	e.sampleAt = time.Time{}
	e.mu.Unlock()

	err := e.service.StartOrReloadService(context.Background(), string(r.corePlan), nil)
	if err != nil {
		failure := classify(err)
		e.setState(StateFailed, failure)
		return nil, failure
	}
	e.applyPlanChoices(r.Plan)
	e.mu.Lock()
	e.state = StateRunning
	e.planHash = r.PlanHash
	e.clashAPIListen = planClashAPIListen(r.Plan)
	e.startedAt = time.Now()
	e.mu.Unlock()
	return sessionResult{SessionID: session, Method: method}, nil
}

func (e *Engine) lookupPublicAddress() publicLookup {
	if e.publicLookup != nil {
		return e.publicLookup
	}
	return systemPublicLookup
}

func (e *Engine) preparePlan(r *startRequest) *Error {
	if r.corePlan != nil {
		return nil
	}
	if err := checkTailnetPlan(r.Plan); err != nil {
		return err
	}
	plan, err := preparePublicPlan(r.Plan, e.lookupPublicAddress())
	if err != nil {
		return &Error{Code: CodePlanInvalid, Message: err.Error()}
	}
	r.corePlan = plan
	return nil
}

// applyPlanChoices makes the plan's own choices take effect. sing-box
// remembers the last selection of each group and the last mode in its
// cache file and prefers them to the plan's defaults; but the plan is
// compiled from what the user chose, possibly while nothing was running.
func (e *Engine) applyPlanChoices(plan []byte) {
	var choices struct {
		Outbounds []struct {
			Type    string `json:"type"`
			Tag     string `json:"tag"`
			Default string `json:"default"`
		} `json:"outbounds"`
		Experimental struct {
			ClashAPI struct {
				DefaultMode string `json:"default_mode"`
			} `json:"clash_api"`
		} `json:"experimental"`
	}
	if json.Unmarshal(plan, &choices) != nil {
		return
	}
	instance := e.service.Instance()
	if instance == nil {
		return
	}
	ctx := context.Background()
	for _, outbound := range choices.Outbounds {
		if outbound.Type != C.TypeSelector || outbound.Default == "" {
			continue
		}
		current, found := instance.Box().Outbound().Outbound(outbound.Tag)
		if !found {
			continue
		}
		if group, isGroup := current.(adapter.OutboundGroup); isGroup && group.Now() != outbound.Default {
			_, err := e.service.SelectOutbound(ctx, &daemon.SelectOutboundRequest{
				GroupTag: outbound.Tag, OutboundTag: outbound.Default,
			})
			if err != nil {
				e.logs.add("warn", "bridge: could not select "+outbound.Default+" in "+outbound.Tag+": "+err.Error())
			}
		}
	}
	if mode := choices.Experimental.ClashAPI.DefaultMode; mode != "" {
		status, err := e.service.GetClashModeStatus(ctx, &emptypb.Empty{})
		if err == nil && !strings.EqualFold(status.CurrentMode, mode) {
			_, _ = e.service.SetClashMode(ctx, &daemon.ClashMode{Mode: mode})
		}
	}
}

func (e *Engine) stop() (any, *Error) {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	e.setState(StateStopping, nil)
	e.countTraffic()
	err := e.service.CloseService()
	e.today.sessionEnded()
	e.today.save()
	if err != nil {
		failure := classify(err)
		e.setState(StateFailed, failure)
		return nil, failure
	}
	e.mu.Lock()
	e.state = StateStopped
	e.sessionID = ""
	e.planHash = ""
	e.mu.Unlock()
	return nil, nil
}

func (e *Engine) setMode(r setModeRequest) (any, *Error) {
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	_, err := e.service.SetClashMode(context.Background(), &daemon.ClashMode{Mode: r.Mode})
	if err != nil {
		return nil, classify(err)
	}
	// The core silently ignores modes missing from the plan's mode list.
	// Confirm what took effect before acknowledging the user's choice.
	actual, err := e.service.GetClashModeStatus(context.Background(), &emptypb.Empty{})
	if err != nil {
		return nil, classify(err)
	}
	if !strings.EqualFold(actual.CurrentMode, r.Mode) {
		return nil, &Error{Code: CodeCoreFailed, Message: "the core did not apply the requested mode"}
	}
	return nil, nil
}

func (e *Engine) selectMember(r selectRequest) (any, *Error) {
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	_, err := e.service.SelectOutbound(context.Background(), &daemon.SelectOutboundRequest{
		GroupTag:    r.GroupTag,
		OutboundTag: r.MemberTag,
	})
	if err != nil {
		return nil, classify(err)
	}
	return nil, nil
}

// Snapshot reads the state now.
func (e *Engine) Snapshot() Snapshot {
	e.mu.Lock()
	e.revision++
	snapshot := Snapshot{
		SessionID: e.sessionID,
		Revision:  e.revision,
		State:     e.state,
		PlanHash:  e.planHash,
		Error:     e.lastError,
	}
	running := e.state == StateRunning
	var instance *daemon.Instance
	if running {
		snapshot.StartedAt = e.startedAt.UnixMilli()
		// Every lifecycle transition takes mu before replacing the daemon
		// instance. Read these short-lived facts while holding the same
		// lock, so a concurrent reload cannot pair a previous session and
		// controller with the next instance's active inbounds/endpoints.
		instance = e.service.Instance()
		if instance != nil {
			snapshot.ClashAPIListen = e.clashAPIListen
			for _, inbound := range instance.Box().Inbound().Inbounds() {
				switch inbound.Type() {
				case C.TypeMixed, C.TypeHTTP, C.TypeSOCKS:
					snapshot.ProxyActive = true
				case C.TypeTun:
					snapshot.TunActive = true
				}
			}
			for _, endpoint := range instance.Box().Endpoint().Endpoints() {
				if endpoint.Type() == C.TypeTailscale {
					snapshot.TailnetActive = true
				}
			}
		}
	}
	e.mu.Unlock()
	if !running || instance == nil {
		snapshot.TodayUp, snapshot.TodayDown = e.today.totals()
		return snapshot
	}
	if mode, err := e.service.GetClashModeStatus(context.Background(), &emptypb.Empty{}); err == nil {
		snapshot.Mode = mode.CurrentMode
	}
	snapshot.Selections = map[string]string{}
	for _, outbound := range instance.Box().Outbound().Outbounds() {
		if group, isGroup := outbound.(adapter.OutboundGroup); isGroup {
			snapshot.Selections[group.Tag()] = group.Now()
		}
	}
	up, down, dayUp, dayDown := e.countTraffic()
	now := time.Now()
	e.mu.Lock()
	if elapsed := now.Sub(e.sampleAt); !e.sampleAt.IsZero() && elapsed > 0 {
		snapshot.UpBps = int64(float64(up-e.sampleUp) / elapsed.Seconds())
		snapshot.DownBps = int64(float64(down-e.sampleDn) / elapsed.Seconds())
	}
	e.sampleAt, e.sampleUp, e.sampleDn = now, up, down
	e.mu.Unlock()
	snapshot.UpTotal, snapshot.DownTotal = up, down
	snapshot.TodayUp, snapshot.TodayDown = dayUp, dayDown
	return snapshot
}

// Keep only the listener of the plan the core accepted, never its
// credentials or any of the next plan's requested settings.
func planClashAPIListen(plan []byte) string {
	var config struct {
		Experimental struct {
			ClashAPI struct {
				ExternalController string `json:"external_controller"`
			} `json:"clash_api"`
		} `json:"experimental"`
	}
	if json.Unmarshal(plan, &config) != nil {
		return ""
	}
	return config.Experimental.ClashAPI.ExternalController
}

func (e *Engine) currentState() State {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.state
}

func (e *Engine) setState(state State, failure *Error) {
	e.mu.Lock()
	e.state = state
	e.lastError = failure
	if state == StateFailed || state == StateStopped {
		e.planHash = ""
	}
	e.mu.Unlock()
}

// checkSession refuses a command meant for a session that is gone.
func (e *Engine) checkSession(sessionID string) *Error {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.state != StateRunning || sessionID != e.sessionID {
		return &Error{Code: CodeSessionMismatch, Message: "no such running session"}
	}
	return nil
}

func newSessionID() string {
	var raw [16]byte
	_, _ = rand.Read(raw[:])
	return hex.EncodeToString(raw[:])
}

// classify maps a core error to the bridge's codes.
func classify(err error) *Error {
	message := err.Error()
	code := CodeCoreFailed
	switch {
	case errors.Is(err, syscall.EADDRINUSE), strings.Contains(message, "address already in use"),
		strings.Contains(message, "Only one usage of each socket address"):
		code = CodePortInUse
	case errors.Is(err, os.ErrPermission), errors.Is(err, syscall.EPERM),
		strings.Contains(message, "operation not permitted"):
		code = CodePermissionDenied
	case strings.HasPrefix(message, "decode config"), strings.HasPrefix(message, "initialize "),
		strings.HasPrefix(message, "create "), strings.HasPrefix(message, "parse "):
		code = CodePlanInvalid
	case status.Code(err) == codes.NotFound && strings.Contains(message, "clash mode"):
		code = CodeUnsupported
	}
	return &Error{Code: code, Message: message}
}

// planLogLevel reads `log.level` of a plan; info when it says nothing.
func planLogLevel(plan []byte) log.Level {
	var options struct {
		Log struct {
			Disabled bool   `json:"disabled"`
			Level    string `json:"level"`
		} `json:"log"`
	}
	if json.Unmarshal(plan, &options) != nil {
		return log.LevelInfo
	}
	if options.Log.Disabled {
		return log.LevelPanic
	}
	if level, err := log.ParseLevel(options.Log.Level); err == nil {
		return level
	}
	return log.LevelInfo
}

// collectLogs copies the daemon's log stream into the engine's buffer.
func (e *Engine) collectLogs(ctx context.Context) {
	_ = e.service.SubscribeLog(&emptypb.Empty{}, &logStream{ctx: ctx, engine: e})
}

// logStream receives what the daemon would send a remote log subscriber.
type logStream struct {
	ctx    context.Context
	engine *Engine
}

func (s *logStream) Send(batch *daemon.Log) error {
	limit := log.Level(s.engine.logLevel.Load())
	for _, message := range batch.Messages {
		// Levels count up from panic to trace.
		if level := log.Level(message.Level); level <= limit {
			s.engine.logs.add(log.FormatLevel(level), message.Message)
		}
	}
	return nil
}

func (s *logStream) Context() context.Context     { return s.ctx }
func (s *logStream) SetHeader(metadata.MD) error  { return nil }
func (s *logStream) SendHeader(metadata.MD) error { return nil }
func (s *logStream) SetTrailer(metadata.MD)       {}
func (s *logStream) SendMsg(any) error            { return nil }
func (s *logStream) RecvMsg(any) error            { return nil }
