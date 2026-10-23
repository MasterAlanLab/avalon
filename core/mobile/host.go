// Package mobile is the bridge as gomobile binds it for the Android
// service and the Apple network extension. It is bound together with
// sing-box's libbox, whose PlatformInterface the host implements (opening
// the TUN, protecting sockets, watching the default network).
package mobile

import (
	"os"
	"runtime"

	"dev.avalon/core/bridge"

	"github.com/sagernet/sing-box/experimental/libbox"
)

// Where the bridge keeps its own files; set by Setup.
var statePath string

// Setup prepares the process once, before NewHost: where sing-box keeps
// its files, and where a crash of the Go runtime is written.
func Setup(basePath string, workingPath string, tempPath string) error {
	statePath = workingPath
	return libbox.Setup(&libbox.SetupOptions{
		BasePath:          basePath,
		WorkingPath:       workingPath,
		TempPath:          tempPath,
		LogMaxLines:       2000,
		CrashReportSource: "host",
		// Calls from Android threads run on a goroutine of their own
		// (libbox's workaround for golang/go#68760).
		FixAndroidStack: runtime.GOOS == "android",
	})
}

// Host owns the session of this process.
type Host struct {
	engine *bridge.Engine
	server *libbox.CommandServer
}

// NewHost builds the bridge over the host's platform interface. platform
// names the host in capabilities ("android", "ios", "macos").
func NewHost(platformInterface libbox.PlatformInterface, platform string) (*Host, error) {
	// libbox's command server builds the daemon service around the platform
	// interface. Its own remote protocol is not started; the bridge calls
	// the service directly.
	server, err := libbox.NewCommandServer(silentHandler{}, platformInterface)
	if err != nil {
		return nil, err
	}
	return &Host{
		engine: bridge.NewEngine(server.StartedService, platform, statePath),
		server: server,
	}, nil
}

// Call runs one bridge command (RUNTIME_HOST §2) and returns its JSON
// response. Lifecycle commands block until done: call from a worker.
func (h *Host) Call(command string, request string) string {
	return string(h.engine.Call(command, []byte(request)))
}

// Close stops the session and releases the bridge.
func (h *Host) Close() {
	h.engine.Close()
	h.server.Close()
}

// silentHandler answers what libbox's remote protocol would ask the host
// app; nothing asks, since that protocol is not served.
type silentHandler struct{}

func (silentHandler) ServiceStop() error   { return nil }
func (silentHandler) ServiceReload() error { return nil }
func (silentHandler) GetSystemProxyStatus() (*libbox.SystemProxyStatus, error) {
	return &libbox.SystemProxyStatus{}, nil
}
func (silentHandler) SetSystemProxyEnabled(bool) error { return nil }
func (silentHandler) TriggerNativeCrash() error        { return nil }
func (silentHandler) WriteDebugMessage(string)         {}
func (silentHandler) ConnectSSHAgent() (int32, error)  { return 0, os.ErrInvalid }
