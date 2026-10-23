// Package bridge is the Avalon Core Bridge: one sing-box instance behind
// the JSON commands of docs/RUNTIME_HOST.md §2. Hosts (the Android service,
// the Apple network extension, the desktop helper) own an Engine and pass
// commands through Call; nothing here knows which host it runs in.
package bridge

import "encoding/json"

// ProtocolVersion is raised when a message field is removed or changes
// meaning; adding optional fields does not raise it (RUNTIME_HOST §3.1).
const ProtocolVersion = 1

// ErrorCode is the closed set of RUNTIME_HOST §2.
type ErrorCode string

const (
	CodePlanInvalid      ErrorCode = "PLAN_INVALID"
	CodePortInUse        ErrorCode = "PORT_IN_USE"
	CodePermissionDenied ErrorCode = "PERMISSION_DENIED"
	CodeSessionMismatch  ErrorCode = "SESSION_MISMATCH"
	CodeCoreFailed       ErrorCode = "CORE_FAILED"
	CodeTimeout          ErrorCode = "TIMEOUT"
	CodeUnsupported      ErrorCode = "UNSUPPORTED"
)

type Error struct {
	Code    ErrorCode `json:"code"`
	Message string    `json:"message"`
	Detail  string    `json:"detail,omitempty"`
}

func (e *Error) Error() string { return string(e.Code) + ": " + e.Message }

// Response is what every command answers with: a result or an error.
type Response struct {
	Result any    `json:"result,omitempty"`
	Error  *Error `json:"error,omitempty"`
}

// State of the session (RUNTIME_HOST §4).
type State string

const (
	StateStopped   State = "stopped"
	StateStarting  State = "starting"
	StateRunning   State = "running"
	StateReloading State = "reloading"
	StateStopping  State = "stopping"
	StateFailed    State = "failed"
)

// How a reload took effect. sing-box 1.14 closes the old instance and
// starts a new one, so it is always a restart (S1).
const (
	ReloadInPlace = "inPlace"
	ReloadRestart = "restart"
)

type startRequest struct {
	RequestID string `json:"requestId"`
	SessionID string `json:"sessionId,omitempty"`
	// The plan inline, or PlanPath: a file holding it. Hosts whose
	// commands cross a process boundary with a size limit (Android's
	// binder) pass the path; the file is also what a host restarts from.
	Plan     json.RawMessage `json:"plan,omitempty"`
	PlanPath string          `json:"planPath,omitempty"`
	PlanHash string          `json:"planHash"`
	// Prepared in process only; callers and restored plan files cannot
	// supply a previous DNS decision in place of a fresh host validation.
	corePlan []byte
	// The device's offset from UTC, for «today» in the traffic totals.
	UTCOffsetSeconds *int `json:"utcOffsetSeconds,omitempty"`
}

type sessionResult struct {
	SessionID string `json:"sessionId"`
	Method    string `json:"method,omitempty"`
}

type stopRequest struct {
	RequestID string `json:"requestId"`
}

type setModeRequest struct {
	RequestID string `json:"requestId"`
	SessionID string `json:"sessionId"`
	Mode      string `json:"mode"`
}

type selectRequest struct {
	RequestID string `json:"requestId"`
	SessionID string `json:"sessionId"`
	GroupTag  string `json:"groupTag"`
	MemberTag string `json:"memberTag"`
}

type queryRequest struct {
	RequestID string `json:"requestId"`
}

// CommandStatus answers queryCommand.
type CommandStatus struct {
	Status string `json:"status"` // pending, done, failed or unknown
	Result any    `json:"result,omitempty"`
	Error  *Error `json:"error,omitempty"`
}

type logsRequest struct {
	AfterSeq int64 `json:"afterSeq"`
	Limit    int   `json:"limit"`
}

type LogEntry struct {
	Seq int64 `json:"seq"`
	// When the line arrived, in milliseconds since the epoch.
	Time    int64  `json:"time"`
	Level   string `json:"level"`
	Message string `json:"message"`
}

type LogPage struct {
	Entries []LogEntry `json:"entries"`
	NextSeq int64      `json:"nextSeq"`
	// Entries after AfterSeq that the buffer no longer holds.
	Dropped int64 `json:"dropped"`
}

// Snapshot is the observable state (RUNTIME_HOST §6).
type Snapshot struct {
	SessionID string `json:"sessionId"`
	// Grows with every snapshot; a reader drops one older than it has.
	Revision int64 `json:"revision"`
	State    State `json:"state"`
	// Which parts of the successfully started session are active. Hosts
	// refine the OS-owned TUN and system proxy facts before forwarding.
	ProxyActive       bool `json:"proxyActive"`
	TailnetActive     bool `json:"tailnetActive"`
	TunActive         bool `json:"tunActive"`
	SystemProxyActive bool `json:"systemProxyActive"`
	// The accepted plan's controller address, without its secret. Empty
	// when disabled or no session is running.
	ClashAPIListen string `json:"clashApiListen"`
	// When the session started running, in milliseconds since the epoch;
	// zero unless running.
	StartedAt int64 `json:"startedAt,omitempty"`
	// Only while running.
	PlanHash string `json:"planHash,omitempty"`
	Mode     string `json:"mode,omitempty"`
	// What each group actually uses now, by tag.
	Selections map[string]string `json:"selections,omitempty"`
	UpBps      int64             `json:"upBps"`
	DownBps    int64             `json:"downBps"`
	// Since the session started.
	UpTotal   int64 `json:"upTotal"`
	DownTotal int64 `json:"downTotal"`
	// Since local midnight, across sessions.
	TodayUp   int64  `json:"todayUp"`
	TodayDown int64  `json:"todayDown"`
	Error     *Error `json:"error,omitempty"`
}

type Capabilities struct {
	PublicNetworkVersion int    `json:"publicNetworkVersion"`
	ProtocolVersion      int    `json:"protocolVersion"`
	CoreVersion          string `json:"coreVersion"`
	Platform             string `json:"platform"`
	// Whether this process may open a TUN interface, where the host knows
	// it by itself (the desktop helper: root or CAP_NET_ADMIN). Absent on
	// mobile hosts, which ask the system for consent instead.
	Tun *bool `json:"tun,omitempty"`
}
