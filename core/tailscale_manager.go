package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/netip"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"sync"
	"time"

	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
	"go4.org/netipx"
)

const managedTSName = "__avalon_managed_tailnet_v2"

type tsDevice struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	DNSName   string     `json:"dnsName"`
	OS        string     `json:"os"`
	IPs       []string   `json:"ips"`
	Online    bool       `json:"online"`
	LastSeen  *time.Time `json:"lastSeen,omitempty"`
	Exit      bool       `json:"exitNodeOption"`
	Routes    []string   `json:"routes"`
	Tags      []string   `json:"tags"`
	KeyExpiry *time.Time `json:"keyExpiry,omitempty"`
}
type tsRoute struct {
	Prefix     string   `json:"prefix"`
	Publishers []string `json:"publishers"`
	Conflict   bool     `json:"conflict"`
	Choice     string   `json:"choice"`
	Accepted   bool     `json:"accepted"`
	Captured   bool     `json:"captured"`
}
type tsProbe struct {
	State   string    `json:"state"`
	Type    string    `json:"type"`
	Latency float64   `json:"latencyMs"`
	Path    string    `json:"path"`
	At      time.Time `json:"at"`
}
type tsPreferences struct {
	AutoRoute     bool                `json:"autoRoute"`
	AcceptRoutes  bool                `json:"acceptRoutes"`
	ExitID        string              `json:"exitId"`
	ExitScope     string              `json:"exitScope"`
	FailurePolicy string              `json:"failurePolicy"`
	Bindings      map[string][]string `json:"bindings"`
	RouteChoices  map[string]string   `json:"routeChoices"`
}
type tsSnapshot struct {
	Supported       bool               `json:"supported"`
	Generation      uint64             `json:"generation"`
	Revision        uint64             `json:"revision"`
	Sequence        uint64             `json:"sequence"`
	Session         string             `json:"session"`
	Control         string             `json:"control"`
	AuthURL         string             `json:"authUrl,omitempty"`
	Error           string             `json:"error,omitempty"`
	Cached          bool               `json:"cached"`
	UpdatedAt       *time.Time         `json:"updatedAt,omitempty"`
	Self            *tsDevice          `json:"self,omitempty"`
	User            string             `json:"user"`
	Suffix          string             `json:"suffix"`
	Devices         []tsDevice         `json:"devices"`
	Routes          []tsRoute          `json:"routes"`
	Probes          map[string]tsProbe `json:"probes"`
	Prefs           tsPreferences      `json:"prefs"`
	Service         bool               `json:"service"`
	Capture         string             `json:"capture"`
	IPv6            bool               `json:"ipv6"`
	Split           string             `json:"split"`
	ExitState       string             `json:"exitState"`
	Reasons         []string           `json:"reasons"`
	Groups          []string           `json:"groups"`
	ProfileID       string             `json:"profileId"`
	CapturePrefixes []string           `json:"capturePrefixes"`
}
type tsBackendStatus struct {
	Session, AuthURL, Control, User, Suffix, ExitID, ErrorCode string
	Self                                                       *tsDevice
	Devices                                                    []tsDevice
	Health                                                     []string
	ExitOnline                                                 bool
}
type tsBackend interface {
	Login(context.Context, string) error
	Logout(context.Context) error
	Preferences(context.Context, tsPreferences) error
	Watch(context.Context, func(tsBackendStatus)) error
	Refresh(context.Context) (tsBackendStatus, error)
	Ping(context.Context, string) (tsProbe, error)
	ExitHealthy(context.Context) bool
	Proxy() C.Proxy
	Close() error
}
type tsFactory func(context.Context, string, string, func() bool) (tsBackend, error)
type tsDiskState struct {
	Control       string        `json:"control"`
	Paused        bool          `json:"paused"`
	Registered    bool          `json:"registered"`
	PendingLogout bool          `json:"pendingLogout,omitempty"`
	Prefs         tsPreferences `json:"prefs"`
	CachedSelf    *tsDevice     `json:"cachedSelf,omitempty"`
	CachedDevices []tsDevice    `json:"cachedDevices,omitempty"`
	CachedSuffix  string        `json:"cachedSuffix,omitempty"`
	CachedAt      *time.Time    `json:"cachedAt,omitempty"`
}

type tsManager struct {
	mu                sync.Mutex
	op                sync.Mutex
	factory           tsFactory
	backend           tsBackend
	cancel            context.CancelFunc
	probeCancel       context.CancelFunc
	ctx               context.Context
	root              string
	disk              tsDiskState
	state             tsSnapshot
	emit              func(tsSnapshot)
	localPrefixes     func() []netip.Prefix
	exitHealthy       bool
	exitOnline        bool
	capturedPrefixes  []netip.Prefix
	captureExclusions []netip.Prefix
	captureKnown      bool
	captureFailure    bool
}

func newTSManager(factory tsFactory, supported bool, emit func(tsSnapshot)) *tsManager {
	prefs := tsPreferences{AutoRoute: true, ExitScope: "groups", FailurePolicy: "stop", Bindings: map[string][]string{}, RouteChoices: map[string]string{}}
	return &tsManager{factory: factory, disk: tsDiskState{Prefs: prefs}, state: tsSnapshot{Supported: supported, Generation: uint64(time.Now().UnixMicro()), Session: "loggedOut", Control: "unknown", Capture: "none", Split: "inactive", ExitState: "off", Prefs: prefs, Devices: []tsDevice{}, Routes: []tsRoute{}, Groups: []string{}, Reasons: []string{}, Probes: map[string]tsProbe{}, CapturePrefixes: []string{}}, emit: emit, localPrefixes: tsLocalPrefixes}
}
func (m *tsManager) snapshotLocked() tsSnapshot {
	// RPC/event callers receive immutable copies, including slices and maps.
	data, _ := json.Marshal(m.state)
	var s tsSnapshot
	_ = json.Unmarshal(data, &s)
	return s
}
func (m *tsManager) Snapshot() tsSnapshot {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.snapshotLocked()
}
func (m *tsManager) publishLocked() {
	m.state.Sequence++
	m.state.Prefs = m.disk.Prefs
	m.evaluateLocked()
	if m.emit != nil {
		m.emit(m.snapshotLocked())
	}
}
func (m *tsManager) available() bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.state.Session == "running" && !m.disk.Paused
}
func (m *tsManager) persistLocked() error {
	if m.root == "" {
		return errors.New("not_initialized")
	}
	if err := os.MkdirAll(m.root, 0700); err != nil {
		return err
	}
	if err := os.Chmod(m.root, 0700); err != nil {
		return err
	}
	if err := markTSIdentityPrivate(m.root); err != nil {
		return err
	}
	data, _ := json.Marshal(m.disk)
	tmp := filepath.Join(m.root, "preferences.tmp")
	dest := filepath.Join(m.root, "preferences.json")
	if err := os.WriteFile(tmp, data, 0600); err != nil {
		return err
	}
	return os.Rename(tmp, dest)
}
func (m *tsManager) Init(home string) {
	m.mu.Lock()
	if m.root != "" {
		resume := m.backend == nil && m.disk.Registered && !m.disk.Paused && m.state.Supported
		m.mu.Unlock()
		if resume {
			_, _ = m.Begin("resume", "", "")
		}
		return
	}
	m.root = tsIdentityRoot(home)
	if data, err := os.ReadFile(filepath.Join(m.root, "preferences.json")); err == nil {
		var disk tsDiskState
		if json.Unmarshal(data, &disk) == nil {
			m.disk = disk
			if m.disk.Prefs.Bindings == nil {
				m.disk.Prefs.Bindings = map[string][]string{}
			}
			if m.disk.Prefs.RouteChoices == nil {
				m.disk.Prefs.RouteChoices = map[string]string{}
			}
		}
	}
	m.state.Prefs = m.disk.Prefs
	if m.disk.Registered || m.disk.PendingLogout {
		m.state.Self = m.disk.CachedSelf
		m.state.Devices = m.disk.CachedDevices
		m.state.Suffix = m.disk.CachedSuffix
		m.state.UpdatedAt = m.disk.CachedAt
		m.state.Cached = true
		m.state.Control = "unknown"
	}
	resume := m.disk.Registered && !m.disk.Paused && m.state.Supported
	if m.disk.PendingLogout {
		m.state.Session = "error"
		m.state.Error = "logout_failed"
		m.disk.Paused = true
		resume = false
	} else if m.disk.Paused {
		m.state.Session = "paused"
		if !m.disk.Registered {
			m.state.Session = "needsLogin"
		}
	}
	m.publishLocked()
	m.mu.Unlock()
	if resume {
		_, _ = m.Begin("resume", "", "")
	}
}
func (m *tsManager) invalidateLocked() uint64 {
	m.state.Generation++
	if m.cancel != nil {
		m.cancel()
		m.cancel = nil
	}
	if m.probeCancel != nil {
		m.probeCancel()
		m.probeCancel = nil
	}
	m.state.AuthURL = ""
	m.state.Error = ""
	m.state.Probes = map[string]tsProbe{}
	m.exitHealthy = false
	return m.state.Generation
}
func (m *tsManager) Begin(action, control, authKey string) (tsSnapshot, error) {
	// Switching servers first revokes the OLD identity, never passing the new
	// registration key to its backend. This also invalidates old browser callbacks.
	if action == "browser" || action == "key" {
		validated, err := tsValidateControl(control)
		if err != nil {
			return tsSnapshot{}, err
		}
		control = validated
		m.mu.Lock()
		switching := m.root != "" && m.disk.Control != control && (m.disk.Registered || m.backend != nil)
		m.mu.Unlock()
		if switching {
			if _, err = m.Stop("logout"); err != nil {
				return tsSnapshot{}, err
			}
		}
	}
	m.mu.Lock()
	if !m.state.Supported {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("unsupported")
	}
	if m.root == "" {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("not_initialized")
	}
	if m.disk.PendingLogout {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("logout_failed")
	}
	if action == "browser" || action == "key" {
		if m.state.Session == "authorizing" || m.state.Session == "starting" || m.state.Session == "waitingApproval" {
			m.mu.Unlock()
			return tsSnapshot{}, errors.New("operation_in_progress")
		}
		if action == "key" && strings.TrimSpace(authKey) == "" {
			m.mu.Unlock()
			return tsSnapshot{}, errors.New("empty_auth_key")
		}
	} else {
		if !m.disk.Registered {
			m.mu.Unlock()
			return tsSnapshot{}, errors.New("needs_login")
		}
		control = m.disk.Control
	}
	gen := m.invalidateLocked()
	ctx, cancel := context.WithCancel(context.Background())
	m.ctx = ctx
	m.cancel = cancel
	m.disk.Paused = false
	m.state.Session = "starting"
	if action != "resume" {
		m.state.Session = "authorizing"
		if m.disk.Control != control {
			m.disk.Prefs.ExitID = ""
			m.disk.Prefs.RouteChoices = map[string]string{}
			m.state.Self = nil
			m.state.Devices = []tsDevice{}
			m.state.Suffix = ""
			m.state.User = ""
			requestTSReconcile()
		}
		m.disk.Control = control
		// Keep ownership fail-closed while reauthenticating the same identity.
		// A server switch has already completed Stop(logout) above.
	}
	if err := m.persistLocked(); err != nil {
		m.mu.Unlock()
		cancel()
		return tsSnapshot{}, errors.New("identity_storage_failed")
	}
	m.publishLocked()
	result := m.snapshotLocked()
	m.mu.Unlock()
	go m.start(ctx, gen, action, control, authKey)
	return result, nil
}
func (m *tsManager) start(ctx context.Context, gen uint64, action, control, key string) {
	m.op.Lock()
	defer m.op.Unlock()
	m.mu.Lock()
	old := m.backend
	m.backend = nil
	prefs := m.disk.Prefs
	root := m.root
	valid := m.state.Generation == gen
	m.mu.Unlock()
	if old != nil {
		if err := old.Close(); err != nil {
			m.fail(gen, "backend_close_failed")
			return
		}
	}
	if !valid || ctx.Err() != nil {
		return
	}
	hash := sha256.Sum256([]byte(control))
	dir := filepath.Join(root, "identity-"+hex.EncodeToString(hash[:12]))
	backend, err := m.factory(ctx, dir, control, m.available)
	if err != nil {
		m.fail(gen, "backend_start_failed")
		return
	}
	m.mu.Lock()
	if m.state.Generation != gen {
		m.mu.Unlock()
		_ = backend.Close()
		return
	}
	m.backend = backend
	m.mu.Unlock()
	if err = backend.Preferences(ctx, prefs); err == nil && action != "resume" {
		err = backend.Login(ctx, key)
	}
	key = ""
	if err != nil {
		m.fail(gen, tsErrorCode(err))
		_ = backend.Close()
		m.mu.Lock()
		if m.backend == backend {
			m.backend = nil
		}
		m.mu.Unlock()
		return
	}
	go m.watch(ctx, gen, backend)
}
func tsErrorCode(err error) string {
	if err == nil {
		return "backend_error"
	}
	// Only categorical errors leave the backend; error bodies may contain keys/URLs.
	s := strings.ToLower(err.Error())
	switch {
	case strings.Contains(s, "expired"):
		return "auth_expired"
	case strings.Contains(s, "already used") || strings.Contains(s, "already been used") || strings.Contains(s, "used key"):
		return "auth_used"
	case strings.Contains(s, "invalid") || strings.Contains(s, "not valid"):
		return "auth_invalid"
	case strings.Contains(s, "denied") || strings.Contains(s, "unauthorized") || strings.Contains(s, "forbidden"):
		return "auth_rejected"
	case strings.Contains(s, "timeout") || strings.Contains(s, "connect") || strings.Contains(s, "no such host"):
		return "server_unreachable"
	default:
		return "backend_error"
	}
}
func (m *tsManager) fail(gen uint64, code string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if gen != m.state.Generation {
		return
	}
	m.state.Error = code
	m.state.Control = "degraded"
	m.state.Cached = true
	if m.state.Session != "running" {
		m.state.Session = "error"
	}
	m.publishLocked()
}
func (m *tsManager) ingest(gen uint64, s tsBackendStatus) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if gen != m.state.Generation || m.disk.Paused {
		return
	}
	previousSession := m.state.Session
	previousExitOnline := m.exitOnline
	previousSuffix := m.state.Suffix
	previousRoutes, _ := json.Marshal(m.state.Routes)
	previousDevices, _ := json.Marshal(m.state.Devices)
	m.state.Session = s.Session
	m.state.AuthURL = s.AuthURL
	if s.AuthURL != "" && !tsValidAuthURL(s.AuthURL) {
		m.state.AuthURL = ""
		m.state.Error = "invalid_auth_url"
	}
	m.state.Control = s.Control
	m.state.Cached = s.Control != "healthy"
	if s.Self != nil {
		m.state.Self = s.Self
	}
	if s.Devices != nil {
		m.state.Devices = s.Devices
	}
	m.state.User = s.User
	m.state.Suffix = s.Suffix
	if s.Session == "running" {
		m.state.AuthURL = ""
		m.disk.Registered = true

	}
	now := time.Now().UTC()
	currentDevices, _ := json.Marshal(m.state.Devices)
	if m.state.UpdatedAt == nil || string(previousDevices) != string(currentDevices) {
		m.state.UpdatedAt = &now
	}
	if m.disk.Registered {
		m.disk.CachedSelf = m.state.Self
		m.disk.CachedDevices = m.state.Devices
		m.disk.CachedSuffix = m.state.Suffix
		m.disk.CachedAt = m.state.UpdatedAt
		if err := m.persistLocked(); err != nil {
			m.state.Error = "identity_storage_failed"
		}
	}
	if s.ErrorCode != "" {
		m.state.Error = s.ErrorCode
	} else if len(s.Health) > 0 {
		m.state.Error = "control_health_warning"
	} else if m.state.Error == "control_health_warning" {
		m.state.Error = ""
	}
	m.exitOnline = s.ExitOnline && s.ExitID == m.disk.Prefs.ExitID
	if !m.exitOnline {
		m.exitHealthy = false
	}
	if previousSession == "running" && s.Session != "running" {
		closeTSConnections()
	} else if previousExitOnline && !m.exitOnline {
		closeTSExitConnections()
	}
	if strings.HasPrefix(s.ErrorCode, "auth_") {
		m.state.Session = "error"
		m.state.AuthURL = ""
		m.disk.Paused = true
		go func() {
			result, err := m.stopExpected("cancel", gen)
			if err == nil && result.Generation != 0 {
				m.mu.Lock()
				if m.state.Generation == result.Generation {
					m.state.Error = s.ErrorCode
					m.publishLocked()
				}
				m.mu.Unlock()
			}
		}()
	}
	m.publishLocked()
	currentRoutes, _ := json.Marshal(m.state.Routes)
	if previousSuffix != m.state.Suffix || string(previousRoutes) != string(currentRoutes) {
		requestTSReconcile()
	}
}
func (m *tsManager) watch(ctx context.Context, gen uint64, b tsBackend) {
	// Notifications are continuous; timed refresh reconciles missed events and network changes.
	done := make(chan error, 1)
	go func() { done <- b.Watch(ctx, func(s tsBackendStatus) { m.ingest(gen, s) }) }()
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	failures := 0
	var retry <-chan time.Time
	for {
		select {
		case <-ctx.Done():
			return
		case err := <-done:
			if ctx.Err() == nil {
				m.fail(gen, tsErrorCode(err))
			}
			retry = time.After(5 * time.Second)
		case <-retry:
			retry = nil
			go func() { done <- b.Watch(ctx, func(s tsBackendStatus) { m.ingest(gen, s) }) }()
		case <-ticker.C:
			m.refreshBackend(ctx, gen, b)
			m.mu.Lock()
			check := m.disk.Prefs.ExitID != "" && m.state.Session == "running" && m.exitOnline
			m.mu.Unlock()
			if check {
				probeCtx, cancel := context.WithTimeout(ctx, 12*time.Second)
				healthy := b.ExitHealthy(probeCtx)
				cancel()
				if healthy {
					failures = 0
				} else {
					failures++
				}
				m.mu.Lock()
				if gen == m.state.Generation {
					if healthy || failures >= 3 {
						if m.exitHealthy != healthy {
							closeTSExitConnections()
						}
						m.exitHealthy = healthy
					}
					m.publishLocked()
				}
				m.mu.Unlock()
			}
		}
	}
}
func (m *tsManager) refreshBackend(ctx context.Context, gen uint64, b tsBackend) {
	c, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	s, err := b.Refresh(c)
	if err != nil {
		m.fail(gen, tsErrorCode(err))
		return
	}
	m.ingest(gen, s)
}
func (m *tsManager) Refresh() tsSnapshot {
	m.mu.Lock()
	b, ctx, gen := m.backend, m.ctx, m.state.Generation
	m.mu.Unlock()
	if b != nil {
		go m.refreshBackend(ctx, gen, b)
	}
	return m.Snapshot()
}
func (m *tsManager) Stop(action string) (tsSnapshot, error) { return m.stopExpected(action, 0) }
func (m *tsManager) stopExpected(action string, expected uint64) (tsSnapshot, error) {
	m.mu.Lock()
	if expected != 0 && expected != m.state.Generation {
		m.mu.Unlock()
		return tsSnapshot{}, nil
	}
	if !m.state.Supported {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("unsupported")
	}
	if m.root == "" {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("not_initialized")
	}
	gen := m.invalidateLocked()
	m.disk.Paused = true
	needsLogout := action == "logout" || action == "cancel"
	wasRegistered := m.disk.Registered
	if needsLogout {
		m.disk.PendingLogout = true
	}
	if err := m.persistLocked(); err != nil {
		m.state.Session = "error"
		m.state.Error = "identity_storage_failed"
		m.publishLocked()
		m.mu.Unlock()
		return m.Snapshot(), errors.New("identity_storage_failed")
	}
	m.state.Session = "stopping"
	m.publishLocked()
	m.mu.Unlock()
	closeTSConnections()
	m.op.Lock()
	defer m.op.Unlock()
	m.mu.Lock()
	if gen != m.state.Generation {
		result := m.snapshotLocked()
		m.mu.Unlock()
		return result, nil
	}
	b := m.backend
	m.backend = nil
	control, root := m.disk.Control, m.root
	m.mu.Unlock()
	var err error
	var identityDir string
	if needsLogout {
		hash := sha256.Sum256([]byte(control))
		identityDir = filepath.Join(root, "identity-"+hex.EncodeToString(hash[:12]))
	}
	// Pause/restart has already closed the server. Reopen that same identity to
	// perform a real LocalClient.Logout, including retries after a failed logout.
	if b == nil && needsLogout {
		_, existsErr := os.Stat(identityDir)
		if wasRegistered || existsErr == nil {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			b, err = m.factory(ctx, identityDir, control, func() bool { return false })
			cancel()
		}
	}
	if b != nil {
		if needsLogout {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			err = b.Logout(ctx)
			cancel()
		}
		if closeErr := b.Close(); err == nil {
			err = closeErr
		}
	}
	if err != nil {
		m.fail(gen, "logout_failed")
		return m.Snapshot(), errors.New("logout_failed")
	}
	if needsLogout {
		err = os.RemoveAll(identityDir)
		if err != nil {
			m.fail(gen, "identity_cleanup_failed")
			return m.Snapshot(), errors.New("identity_cleanup_failed")
		}
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if gen != m.state.Generation {
		return m.snapshotLocked(), nil
	}
	if needsLogout {
		m.disk.Registered = false
		m.disk.PendingLogout = false
		m.disk.Paused = false
		m.disk.Prefs.ExitID = ""
		m.disk.CachedSelf = nil
		m.disk.CachedDevices = nil
		m.disk.CachedSuffix = ""
		m.disk.CachedAt = nil
		m.state.Session = "loggedOut"
		m.state.Self = nil
		m.state.Devices = []tsDevice{}
		m.state.Suffix = ""
		m.state.User = ""
	} else {
		m.state.Session = "paused"
	}
	if err = m.persistLocked(); err != nil {
		m.state.Error = "identity_storage_failed"
		m.publishLocked()
		return m.snapshotLocked(), errors.New("identity_storage_failed")
	}
	m.publishLocked()
	return m.snapshotLocked(), nil
}
func (m *tsManager) Shutdown() {
	m.mu.Lock()
	m.invalidateLocked()
	m.state.Session = "backendDisconnected"
	if m.disk.Paused {
		m.state.Session = "paused"
	}
	m.state.Control = "unknown"
	m.state.Cached = true
	m.state.Service = false
	m.state.Capture = "none"
	m.publishLocked()
	m.mu.Unlock()
	m.op.Lock()
	defer m.op.Unlock()
	m.mu.Lock()
	b := m.backend
	m.backend = nil
	m.mu.Unlock()
	if b != nil {
		_ = b.Close()
	}
}
func (m *tsManager) SetPreferences(p tsPreferences) (tsSnapshot, error) {
	if !m.Snapshot().Supported {
		return tsSnapshot{}, errors.New("unsupported")
	}
	if p.ExitScope != "groups" && p.ExitScope != "all" {
		return tsSnapshot{}, errors.New("invalid_scope")
	}
	if p.FailurePolicy != "stop" && p.FailurePolicy != "fallback" {
		return tsSnapshot{}, errors.New("invalid_failure_policy")
	}
	for prefix, choice := range p.RouteChoices {
		if _, err := netip.ParsePrefix(prefix); err != nil || choice != "local" && choice != "remote" {
			return tsSnapshot{}, errors.New("invalid_route_choice")
		}
	}
	m.op.Lock()
	defer m.op.Unlock()
	m.mu.Lock()
	previous := m.snapshotLocked()
	old := m.disk.Prefs
	for _, name := range p.Bindings[m.state.ProfileID] {
		if !slices.Contains(m.state.Groups, name) && !slices.Contains(old.Bindings[m.state.ProfileID], name) {
			m.mu.Unlock()
			return tsSnapshot{}, errors.New("unsupported_group")
		}
	}
	gen := m.state.Generation
	b, ctx := m.backend, m.ctx
	if p.ExitID != "" {
		found := false
		for _, d := range m.state.Devices {
			if d.ID == p.ExitID && d.Exit {
				found = true
			}
		}
		if !found {
			m.mu.Unlock()
			return tsSnapshot{}, errors.New("unapproved_exit")
		}
	}
	m.mu.Unlock()
	if b != nil {
		c, cancel := context.WithTimeout(ctx, 8*time.Second)
		err := b.Preferences(c, p)
		cancel()
		if err != nil {
			return m.Snapshot(), errors.New(tsErrorCode(err))
		}
	}
	m.mu.Lock()
	if gen != m.state.Generation {
		m.mu.Unlock()
		return m.Snapshot(), errors.New("stale_generation")
	}
	m.disk.Prefs = p
	if old.ExitID != p.ExitID {
		m.exitHealthy = false
	}
	if err := m.persistLocked(); err != nil {
		m.disk.Prefs = old
		m.mu.Unlock()
		if b != nil {
			_ = b.Preferences(ctx, old)
		}
		return m.Snapshot(), errors.New("identity_storage_failed")
	}
	m.cancelProbesLocked()
	m.state.Revision++
	m.publishLocked()
	m.mu.Unlock()
	closeTSChangedConnections(previous, m.Snapshot())
	return m.Snapshot(), nil
}
func (m *tsManager) Probe(ids []string) (tsSnapshot, error) {
	if !m.Snapshot().Supported {
		return tsSnapshot{}, errors.New("unsupported")
	}
	m.mu.Lock()
	if m.backend == nil || m.state.Session != "running" {
		m.mu.Unlock()
		return tsSnapshot{}, errors.New("session_not_running")
	}
	if m.probeCancel != nil {
		m.probeCancel()
	}
	ctx, cancel := context.WithCancel(m.ctx)
	m.probeCancel = cancel
	gen, rev := m.state.Generation, m.state.Revision
	b := m.backend
	targets := map[string]string{}
	for _, d := range m.state.Devices {
		for _, id := range ids {
			if id == d.ID && len(d.IPs) > 0 {
				targets[id] = d.IPs[0]
				m.state.Probes[id] = tsProbe{State: "testing", Type: "disco", Path: "unknown", At: time.Now().UTC()}
			}
		}
	}
	m.publishLocked()
	m.mu.Unlock()
	go func() {
		sem := make(chan struct{}, 4)
		var wg sync.WaitGroup
		for id, ip := range targets {
			if ctx.Err() != nil {
				break
			}
			select {
			case sem <- struct{}{}:
			case <-ctx.Done():
				return
			}
			wg.Add(1)
			go func(id, ip string) {
				defer wg.Done()
				defer func() { <-sem }()
				c, stop := context.WithTimeout(ctx, 5*time.Second)
				p, err := b.Ping(c, ip)
				stop()
				if err != nil {
					p = tsProbe{State: "failed", Type: "disco", Path: "unknown", At: time.Now().UTC()}
				}
				m.mu.Lock()
				defer m.mu.Unlock()
				if ctx.Err() == nil && gen == m.state.Generation && rev == m.state.Revision {
					m.state.Probes[id] = p
					m.publishLocked()
				}
			}(id, ip)
		}
		wg.Wait()
	}()
	return m.Snapshot(), nil
}
func (m *tsManager) cancelProbesLocked() {
	if m.probeCancel != nil {
		m.probeCancel()
		m.probeCancel = nil
	}
	for id, p := range m.state.Probes {
		if p.State == "testing" {
			p.State = "cancelled"
			m.state.Probes[id] = p
		}
	}
}
func (m *tsManager) CancelProbes() tsSnapshot {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.cancelProbesLocked()
	m.publishLocked()
	return m.snapshotLocked()
}
func (m *tsManager) evaluateLocked() {
	s := &m.state
	p := m.disk.Prefs
	s.Reasons = []string{}
	s.Split = "inactive"
	s.ExitState = "off"
	if !s.Supported {
		s.CapturePrefixes = []string{}
		s.Reasons = []string{"unsupported"}
		return
	}
	local := m.localPrefixes()
	routes := map[string]*tsRoute{}
	for _, d := range s.Devices {
		for _, prefix := range d.Routes {
			r := routes[prefix]
			if r == nil {
				r = &tsRoute{Prefix: prefix, Choice: p.RouteChoices[prefix]}
				routes[prefix] = r
				remote, err := netip.ParsePrefix(prefix)
				if err == nil {
					for _, l := range local {
						if remote.Overlaps(l) {
							r.Conflict = true
						}
					}
				}
				if r.Choice == "" {
					r.Choice = "local"
				}
				r.Accepted = p.AcceptRoutes && (!r.Conflict || r.Choice == "remote")
			}
			r.Publishers = append(r.Publishers, d.ID)
		}
	}
	s.Routes = []tsRoute{}
	for _, r := range routes {
		r.Captured = m.prefixCapturedLocked(r.Prefix)
		s.Routes = append(s.Routes, *r)
	}
	sort.Slice(s.Routes, func(i, j int) bool { return s.Routes[i].Prefix < s.Routes[j].Prefix })
	s.CapturePrefixes = []string{}
	if m.disk.Registered || s.Session == "running" {
		if p.AutoRoute {
			s.CapturePrefixes = append(s.CapturePrefixes, "100.64.0.0/10", "fd7a:115c:a1e0::/48")
			devices := append([]tsDevice(nil), s.Devices...)
			if s.Self != nil {
				devices = append(devices, *s.Self)
			}
			for _, d := range devices {
				for _, ip := range d.IPs {
					if a, err := netip.ParseAddr(ip); err == nil {
						s.CapturePrefixes = append(s.CapturePrefixes, netip.PrefixFrom(a, a.BitLen()).String())
					}
				}
			}
		}
		for _, r := range s.Routes {
			if r.Accepted {
				s.CapturePrefixes = append(s.CapturePrefixes, r.Prefix)
			}
		}
	}
	if !s.Service {
		s.Reasons = append(s.Reasons, "service_stopped")
	}
	if s.ProfileID == "" || s.ProfileID == "0" {
		s.Reasons = append(s.Reasons, "no_profile")
	}
	ruleMode := tunnel.Mode() == tunnel.Rule
	if !ruleMode {
		s.Reasons = append(s.Reasons, "rule_mode_required")
	}
	if s.Capture != "tun" {
		s.Reasons = append(s.Reasons, "proxy_apps_only")
	}
	if !s.IPv6 {
		s.Reasons = append(s.Reasons, "ipv6_not_captured")
	}
	for _, r := range s.Routes {
		if r.Conflict && !r.Accepted {
			s.Reasons = append(s.Reasons, "subnet_conflict")
			break
		}
	}
	if p.ExitID != "" && p.ExitScope == "groups" {
		bindings := p.Bindings[s.ProfileID]
		if len(bindings) == 0 {
			s.Reasons = append(s.Reasons, "exit_unbound")
		}
		for _, name := range bindings {
			if !slices.Contains(s.Groups, name) {
				s.Reasons = append(s.Reasons, "missing_exit_groups")
				break
			}
		}
	}
	if s.Capture == "tun" {
		if !m.captureKnown {
			s.Reasons = append(s.Reasons, "capture_pending")
		}
		if m.captureFailure {
			s.Reasons = append(s.Reasons, "capture_apply_failed")
		}
		for _, prefix := range s.CapturePrefixes {
			p, e := netip.ParsePrefix(prefix)
			if e == nil && p.Addr().Is6() && !s.IPv6 {
				continue
			}
			if !m.prefixCapturedLocked(prefix) {
				s.Reasons = append(s.Reasons, "capture_missing_prefix")
				break
			}
		}
	}
	base := s.Service && s.ProfileID != "" && s.ProfileID != "0" && ruleMode && s.Session == "running" && s.Error != "config_apply_failed"
	if base && (p.AutoRoute || p.AcceptRoutes) {
		s.Split = "active"
		if s.Capture != "tun" || !s.IPv6 || slices.Contains(s.Reasons, "subnet_conflict") || slices.Contains(s.Reasons, "capture_missing_prefix") || slices.Contains(s.Reasons, "capture_pending") || m.captureFailure {
			s.Split = "partial"
		}
	}
	if p.ExitID != "" {
		s.ExitState = "pending"
		if base {
			if m.exitHealthy && m.exitOnline && !slices.Contains(s.Reasons, "exit_unbound") {
				s.ExitState = "active"
				if slices.Contains(s.Reasons, "missing_exit_groups") {
					s.ExitState = "partial"
				}
			} else if p.FailurePolicy == "fallback" {
				s.ExitState = "fallback"
			} else {
				s.ExitState = "blocked"
			}
		}
	}
	for id, probe := range s.Probes {
		if probe.State == "success" && time.Since(probe.At) > time.Minute {
			probe.State = "expired"
			s.Probes[id] = probe
		}
	}
}
func tsValidAuthURL(text string) bool {
	if len(text) > 8192 {
		return false
	}
	u, err := url.Parse(text)
	if err != nil || u.User != nil || u.Hostname() == "" {
		return false
	}
	return u.Scheme == "https" || u.Scheme == "http" && (u.Hostname() == "localhost" || u.Hostname() == "127.0.0.1" || u.Hostname() == "::1")
}

func (m *tsManager) prefixCapturedLocked(text string) bool {
	if m.state.Capture != "tun" || !m.captureKnown {
		return false
	}
	p, err := netip.ParsePrefix(text)
	if err != nil || p.Addr().Is6() && !m.state.IPv6 {
		return false
	}
	var builder netipx.IPSetBuilder
	if len(m.capturedPrefixes) == 0 {
		builder.AddPrefix(netip.MustParsePrefix("0.0.0.0/0"))
		if m.state.IPv6 {
			builder.AddPrefix(netip.MustParsePrefix("::/0"))
		}
	} else {
		for _, p := range m.capturedPrefixes {
			builder.AddPrefix(p)
		}
	}
	for _, p := range m.captureExclusions {
		builder.RemovePrefix(p)
	}
	set, err := builder.IPSet()
	return err == nil && set.ContainsPrefix(p)
}
