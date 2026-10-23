package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"
	"unsafe"

	"dev.avalon/core/bridge"
	"dev.avalon/core/internal/windowshost"
	winio "github.com/tailscale/go-winio"
	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
)

type windowsService struct{ paths windowsPaths }

func (s *windowsService) Execute(_ []string, requests <-chan svc.ChangeRequest, changes chan<- svc.Status) (bool, uint32) {
	changes <- svc.Status{State: svc.StartPending}
	stop := make(chan struct{})
	done := make(chan error, 1)
	ready := make(chan struct{})
	go func() { done <- runWindowsPipeReady(s.paths, true, stop, ready) }()
	select {
	case <-ready:
		changes <- svc.Status{State: svc.Running, Accepts: svc.AcceptStop | svc.AcceptShutdown}
	case <-done:
		return false, 1
	}
	for {
		select {
		case err := <-done:
			if err != nil {
				return false, 1
			}
			return false, 0
		case request := <-requests:
			switch request.Cmd {
			case svc.Interrogate:
				changes <- request.CurrentStatus
			case svc.Stop, svc.Shutdown:
				changes <- svc.Status{State: svc.StopPending}
				close(stop)
				<-done
				return false, 0
			}
		}
	}
}

type windowsPipeHost struct {
	paths     windowsPaths
	service   bool
	state     string
	shared    string
	mu        sync.RWMutex
	lifecycle sync.Mutex
	engine    *bridge.Engine
	stop      func()
	tun       windows.Handle
	tunMu     sync.Mutex
	closing   bool
	unusable  bool
}

func (h *windowsPipeHost) newEngine() error {
	for _, dir := range []string{h.state, filepath.Join(h.state, "tmp"), filepath.Join(h.state, "rulesets"), filepath.Join(h.state, "tailscale")} {
		if err := os.MkdirAll(dir, 0o700); err != nil {
			return err
		}
	}
	h.engine = bridge.NewEngine(bridge.NewDesktopService(h.state, filepath.Join(h.state, "tmp")), "windows", h.state)
	h.engine.ReportTun(func() bool { return h.service })
	return nil
}

func runWindowsPipeReady(p windowsPaths, service bool, stop <-chan struct{}, ready chan<- struct{}) error {
	state, shared, pipe := p.UserStateDir, p.UserStateDir, p.UserPipe
	if service {
		state, shared, pipe = p.privateRuntime, p.ServiceStateDir, p.ServicePipe
		if err := rejectReparseChain(state); err != nil {
			return err
		}
		if err := rejectReparseChain(shared); err != nil {
			return err
		}
	}
	// go-winio uses NtCreateNamedPipeFile(FILE_CREATE) for its first sentinel
	// instance, and FILE_PIPE_REJECT_REMOTE_CLIENTS for every instance. This
	// prevents an existing endpoint from being silently adopted.
	// Ordinary helpers must themselves create server instances; services give
	// their user only data read/write, never FILE_CREATE_PIPE_INSTANCE.
	userRights := "0x00100083"
	if !service {
		userRights = "GA"
	}
	listener, err := winio.ListenPipe(pipe, &winio.PipeConfig{SecurityDescriptor: "D:P(A;;GA;;;SY)(A;;" + userRights + ";;;" + p.SID + ")", InputBufferSize: 64 << 10, OutputBufferSize: 64 << 10})
	if err != nil {
		return err
	}
	defer listener.Close()
	closed := make(chan struct{})
	var once sync.Once
	stopHost := func() { once.Do(func() { close(closed); _ = listener.Close() }) }
	host := &windowsPipeHost{paths: p, service: service, state: state, shared: shared, stop: stopHost}
	if err := host.newEngine(); err != nil {
		return err
	}
	defer func() {
		host.mu.Lock()
		defer host.mu.Unlock()
		host.engine.Close()
		host.releaseTun()
	}()
	if ready != nil {
		close(ready)
	}
	go func() {
		select {
		case <-stop:
			stopHost()
		case <-closed:
		}
	}()
	defer stopHost()
	for {
		connection, err := listener.Accept()
		if err != nil {
			select {
			case <-closed:
				return nil
			default:
				return err
			}
		}
		go host.handle(connection)
	}
}

func clientToken(connection net.Conn, sid string, duplicate bool) (windows.Token, error) {
	file, ok := connection.(interface{ Fd() uintptr })
	if !ok {
		return 0, errors.New("pipe does not expose its authenticated client")
	}
	var pid uint32
	if err := windows.GetNamedPipeClientProcessId(windows.Handle(file.Fd()), &pid); err != nil {
		return 0, err
	}
	process, err := windows.OpenProcess(windows.PROCESS_QUERY_LIMITED_INFORMATION, false, pid)
	if err != nil {
		return 0, err
	}
	defer windows.CloseHandle(process)
	access := uint32(windows.TOKEN_QUERY)
	if duplicate {
		access |= windows.TOKEN_DUPLICATE
	}
	var token windows.Token
	if err := windows.OpenProcessToken(process, access, &token); err != nil {
		return 0, err
	}
	defer token.Close()
	user, err := token.GetTokenUser()
	if err != nil || user.User.Sid.String() != sid {
		return 0, windows.ERROR_ACCESS_DENIED
	}
	if !duplicate {
		return 0, nil
	}
	var impersonation windows.Token
	err = windows.DuplicateTokenEx(token, windows.TOKEN_QUERY|windows.TOKEN_IMPERSONATE, nil, windows.SecurityImpersonation, windows.TokenImpersonation, &impersonation)
	return impersonation, err
}

func (h *windowsPipeHost) handle(connection net.Conn) {
	defer connection.Close()
	token, err := clientToken(connection, h.paths.SID, h.service)
	if err != nil {
		return
	}
	if token != 0 {
		defer token.Close()
	}
	_ = connection.SetReadDeadline(time.Now().Add(10 * time.Second))
	input := bufio.NewScanner(connection)
	input.Buffer(make([]byte, 64<<10), 64<<20)
	if !input.Scan() {
		return
	}
	_ = connection.SetReadDeadline(time.Time{})
	var request line
	if json.Unmarshal(input.Bytes(), &request) != nil {
		_, _ = connection.Write(append(windowsFailure(bridge.CodePlanInvalid, "malformed command"), '\n'))
		return
	}
	response, shutdown := h.call(request, token)
	_ = connection.SetWriteDeadline(time.Now().Add(30 * time.Second))
	_, _ = connection.Write(append(response, '\n'))
	if shutdown {
		h.stop()
	}
}

func windowsFailure(code bridge.ErrorCode, message string) []byte {
	raw, _ := json.Marshal(bridge.Response{Error: &bridge.Error{Code: code, Message: message}})
	return raw
}

func windowsResult(value any) []byte {
	raw, _ := json.Marshal(map[string]any{"result": value})
	return raw
}

func (h *windowsPipeHost) stopped() bool {
	var response struct {
		Result struct {
			State string `json:"state"`
		} `json:"result"`
	}
	_ = json.Unmarshal(h.engine.Call("snapshot", []byte(`{}`)), &response)
	return response.Result.State == "stopped" || response.Result.State == "failed"
}

func (h *windowsPipeHost) call(command line, token windows.Token) ([]byte, bool) {
	if !windowshost.AllowedCommand(command.Command) {
		return windowsFailure(bridge.CodeUnsupported, "unsupported host command"), false
	}
	if err := windowshost.ValidateRequestKeys(command.Command, command.Request); err != nil {
		return windowsFailure(bridge.CodePlanInvalid, err.Error()), false
	}
	if command.Command == "hostShutdown" || command.Command == "hostImportState" || command.Command == "hostExportState" {
		h.mu.Lock()
		defer h.mu.Unlock()
		if h.closing || h.unusable && command.Command != "hostShutdown" {
			return windowsFailure(bridge.CodeCoreFailed, "the host must be restarted before it can accept runtime state"), false
		}
		if !h.stopped() {
			return windowsFailure(bridge.CodeSessionMismatch, "stop the current session before changing hosts"), false
		}
		switch command.Command {
		case "hostShutdown":
			h.closing = true
			return windowsResult(map[string]any{}), true
		case "hostExportState":
			files, err := h.exportState()
			if err != nil {
				return windowsFailure(bridge.CodeCoreFailed, err.Error()), false
			}
			return windowsResult(map[string]any{"version": 1, "files": files}), false
		case "hostImportState":
			var transfer struct {
				Version int               `json:"version"`
				Files   map[string][]byte `json:"files"`
			}
			if json.Unmarshal(command.Request, &transfer) != nil || transfer.Version != 1 {
				return windowsFailure(bridge.CodePlanInvalid, "invalid state transfer"), false
			}
			if err := h.importState(transfer.Files); err != nil {
				return windowsFailure(bridge.CodeCoreFailed, err.Error()), false
			}
			return windowsResult(map[string]any{}), false
		}
	}
	h.mu.RLock()
	defer h.mu.RUnlock()
	if h.unusable && command.Command == "snapshot" {
		var snapshot struct {
			Result map[string]any `json:"result"`
		}
		_ = json.Unmarshal(h.engine.Call("snapshot", []byte(`{}`)), &snapshot)
		snapshot.Result["state"] = "failed"
		snapshot.Result["proxyActive"] = false
		snapshot.Result["tunActive"] = false
		snapshot.Result["tailnetActive"] = false
		snapshot.Result["error"] = &bridge.Error{Code: bridge.CodeCoreFailed, Message: "the runtime state could not be reopened; restart the host"}
		return windowsResult(snapshot.Result), false
	}
	if h.closing || h.unusable {
		switch command.Command {
		case "snapshot", "capabilities", "queryCommand", "logs", "connections", "tailnetStatus":
			return h.engine.Call(command.Command, command.Request), false
		default:
			return windowsFailure(bridge.CodeCoreFailed, "restart the host before changing the runtime state"), false
		}
	}
	if command.Command == "start" || command.Command == "reload" || command.Command == "stop" {
		h.lifecycle.Lock()
		defer h.lifecycle.Unlock()
	}
	request := command.Request
	candidateTun := false
	hadTun := h.ownsTun()
	if command.Command == "start" || command.Command == "reload" || command.Command == "hostCheckPlan" || command.Command == "urlTest" {
		var decoded map[string]json.RawMessage
		if err := json.Unmarshal(request, &decoded); err != nil {
			return windowsFailure(bridge.CodePlanInvalid, "invalid plan request"), false
		}
		plan := decoded["plan"]
		if len(plan) == 0 || string(plan) == "null" {
			var path string
			_ = json.Unmarshal(decoded["planPath"], &path)
			if path != "" {
				var err error
				plan, err = h.readShared(path, false, token)
				if err != nil {
					return windowsFailure(bridge.CodePermissionDenied, "the candidate plan cannot be read safely"), false
				}
			}
		}
		if len(plan) > 0 {
			clean, tun, err := windowshost.RewritePlan(plan, h.state, func(path string) (string, error) { return h.snapshotRule(path, token) })
			candidateTun = tun
			if err != nil {
				return windowsFailure(bridge.CodePlanInvalid, err.Error()), false
			}
			if tun && !h.service {
				return windowsFailure(bridge.CodePermissionDenied, "TUN requires the installed Avalon tunnel service"), false
			}
			if command.Command == "hostCheckPlan" {
				if err := h.engine.ValidatePlan(clean); err != nil {
					return windowsFailure(err.Code, err.Message), false
				}
				return windowsResult(map[string]any{}), false
			}
			if tun && (command.Command == "start" && h.stopped() || command.Command == "reload") {
				if err := h.engine.ValidatePlan(clean); err != nil {
					return windowsFailure(err.Code, err.Message), false
				}
				if err := h.acquireTun(); err != nil {
					return windowsFailure(bridge.CodePermissionDenied, "another Windows account already owns the Avalon tunnel"), false
				}
			}
			decoded["plan"] = clean
			delete(decoded, "planPath")
			request, _ = json.Marshal(decoded)
		} else if command.Command != "urlTest" {
			return windowsFailure(bridge.CodePlanInvalid, "no candidate plan was supplied"), false
		}
	}
	if command.Command == "fetch" {
		return h.fetch(request, token), false
	}
	answer := h.engine.Call(command.Command, request)
	if command.Command == "stop" || command.Command == "start" || command.Command == "reload" {
		var result struct {
			Error *bridge.Error `json:"error"`
		}
		_ = json.Unmarshal(answer, &result)
		if h.stopped() || result.Error == nil && !candidateTun || result.Error != nil && !hadTun {
			h.releaseTun()
		}
	}
	return answer, false
}

// Open only direct shared plan/ruleset files, under the verified caller token.
// The handle has OPEN_REPARSE_POINT and no delete sharing; the service root
// and rulesets directory cannot be deleted, renamed or reconfigured by the user.
func (h *windowsPipeHost) readShared(path string, rule bool, token windows.Token) ([]byte, error) {
	root := h.shared
	if rule {
		root = filepath.Join(root, "rulesets")
	}
	if err := directChild(path, root); err != nil {
		return nil, err
	}
	var file *os.File
	err := asUser(token, func() error {
		var err error
		file, err = openRegular(path, windows.GENERIC_READ, windows.OPEN_EXISTING)
		return err
	})
	if err != nil {
		return nil, err
	}
	defer file.Close()
	body, err := io.ReadAll(io.LimitReader(file, 32<<20+1))
	if len(body) > 32<<20 {
		return nil, errors.New("shared host file is too large")
	}
	return body, err
}

func directChild(path, root string) error {
	// Reject DOS device namespaces, UNC, ADS, dot aliases and alternate drive
	// spellings before cleaning. The final component must be a plain filename.
	if strings.ContainsAny(path, "\x00") || strings.HasPrefix(path, `\\`) || len(path) < 4 || path[1] != ':' || strings.Contains(path[2:], ":") || strings.Contains(path, "/../") || strings.Contains(path, `\..\`) {
		return errors.New("invalid host file path")
	}
	clean := filepath.Clean(path)
	base := filepath.Base(clean)
	if !strings.EqualFold(filepath.Dir(clean), filepath.Clean(root)) || strings.HasSuffix(base, ".") || strings.HasSuffix(base, " ") || base == "." || base == ".." {
		return errors.New("host file lies outside its protected directory")
	}
	return rejectReparseChain(root)
}

func regularHandle(handle windows.Handle) error {
	var info windows.ByHandleFileInformation
	if err := windows.GetFileInformationByHandle(handle, &info); err != nil {
		return err
	}
	if info.FileAttributes&(windows.FILE_ATTRIBUTE_REPARSE_POINT|windows.FILE_ATTRIBUTE_DIRECTORY) != 0 || info.NumberOfLinks != 1 {
		return errors.New("host files must be regular, unlinked files")
	}
	return nil
}

func openRegular(path string, access, disposition uint32) (*os.File, error) {
	ptr, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return nil, err
	}
	handle, err := windows.CreateFile(ptr, access, windows.FILE_SHARE_READ, nil, disposition, windows.FILE_FLAG_OPEN_REPARSE_POINT, 0)
	if err != nil {
		return nil, err
	}
	if err := regularHandle(handle); err != nil {
		windows.CloseHandle(handle)
		return nil, err
	}
	return os.NewFile(uintptr(handle), path), nil
}

func asUser(token windows.Token, run func() error) (err error) {
	if token == 0 {
		return run()
	}
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()
	if err := windows.SetThreadToken(nil, token); err != nil {
		return err
	}
	defer func() {
		// Returning an impersonated thread to the Go scheduler is unsafe.
		if revertErr := windows.RevertToSelf(); revertErr != nil {
			os.Exit(1)
		}
	}()
	return run()
}

func (h *windowsPipeHost) snapshotRule(path string, token windows.Token) (string, error) {
	body, err := h.readShared(path, true, token)
	if err != nil {
		return "", errors.New("the rule-set file cannot be read safely")
	}
	sum := sha256.Sum256(body)
	ext := strings.ToLower(filepath.Ext(path))
	if ext != ".json" && ext != ".srs" {
		return "", errors.New("unsupported rule-set file format")
	}
	private := filepath.Join(h.state, "rulesets", hex.EncodeToString(sum[:])+ext)
	if strings.EqualFold(private, filepath.Clean(path)) && !h.service {
		return private, nil
	}
	if err := os.WriteFile(private, body, 0o600); err != nil {
		return "", err
	}
	return private, nil
}

func (h *windowsPipeHost) fetch(request []byte, token windows.Token) []byte {
	var decoded map[string]json.RawMessage
	if json.Unmarshal(request, &decoded) != nil {
		return windowsFailure(bridge.CodePlanInvalid, "invalid download request")
	}
	var destination string
	_ = json.Unmarshal(decoded["destPath"], &destination)
	if destination == "" {
		return h.engine.Call("fetch", request)
	}
	if err := directChild(destination, filepath.Join(h.shared, "rulesets")); err != nil {
		return windowsFailure(bridge.CodePermissionDenied, "download destination is outside the host rule-set directory")
	}
	private, err := os.CreateTemp(filepath.Join(h.state, "tmp"), "fetch-*")
	if err != nil {
		return windowsFailure(bridge.CodeCoreFailed, "cannot prepare the download")
	}
	path := private.Name()
	_ = private.Close()
	defer os.Remove(path)
	decoded["destPath"], _ = json.Marshal(path)
	cleanRequest, _ := json.Marshal(decoded)
	response := h.engine.Call("fetch", cleanRequest)
	var result struct {
		Result map[string]any `json:"result"`
		Error  *bridge.Error  `json:"error"`
	}
	if json.Unmarshal(response, &result) != nil || result.Error != nil {
		return response
	}
	source, err := os.Open(path)
	if err != nil {
		return windowsFailure(bridge.CodeCoreFailed, "cannot read the completed download")
	}
	defer source.Close()
	var target *os.File
	err = asUser(token, func() error {
		var err error
		// ResourceService supplies a new random temporary filename. Existing
		// files, hard links and reparse targets are never overwritten.
		target, err = openRegular(destination, windows.GENERIC_WRITE, windows.CREATE_NEW)
		return err
	})
	if err != nil {
		return windowsFailure(bridge.CodePermissionDenied, "the download destination cannot be created safely")
	}
	_, copyErr := io.Copy(target, source)
	closeErr := target.Close()
	if copyErr != nil || closeErr != nil {
		return windowsFailure(bridge.CodeCoreFailed, "cannot save the completed download")
	}
	result.Result["path"] = destination
	return windowsResult(result.Result)
}

func (h *windowsPipeHost) acquireTun() error {
	h.tunMu.Lock()
	defer h.tunMu.Unlock()
	if h.tun != 0 {
		return nil
	}
	name, _ := windows.UTF16PtrFromString(`Global\AvalonTunnelOwner-v1`)
	sd, _ := windows.SecurityDescriptorFromString("D:P(A;;GA;;;SY)(A;;GA;;;BA)")
	sa := windows.SecurityAttributes{Length: uint32(unsafe.Sizeof(windows.SecurityAttributes{})), SecurityDescriptor: sd}
	mutex, err := windows.CreateMutex(&sa, false, name)
	if err != nil && !errors.Is(err, windows.ERROR_ALREADY_EXISTS) {
		return err
	}
	// A held handle, rather than an owned mutex, is enough: the object lives
	// until its sole owning helper closes the handle or the process dies.
	if errors.Is(err, windows.ERROR_ALREADY_EXISTS) {
		windows.CloseHandle(mutex)
		return errors.New("another account owns the TUN session")
	}
	h.tun = mutex
	return nil
}

func (h *windowsPipeHost) ownsTun() bool {
	h.tunMu.Lock()
	defer h.tunMu.Unlock()
	return h.tun != 0
}

func (h *windowsPipeHost) releaseTun() {
	h.tunMu.Lock()
	defer h.tunMu.Unlock()
	if h.tun != 0 {
		_ = windows.CloseHandle(h.tun)
		h.tun = 0
	}
}

func (h *windowsPipeHost) exportState() (map[string][]byte, error) {
	h.engine.Close()
	files, readErr := h.readRuntimeState()
	if err := h.newEngine(); err != nil {
		h.unusable = true
		return nil, errors.New("the host could not reopen its runtime state; restart the host")
	}
	return files, readErr
}

func (h *windowsPipeHost) readRuntimeState() (map[string][]byte, error) {
	files := map[string][]byte{}
	for _, name := range windowshost.TransferFiles {
		file, err := openRegular(filepath.Join(h.state, filepath.FromSlash(name)), windows.GENERIC_READ, windows.OPEN_EXISTING)
		if errors.Is(err, windows.ERROR_FILE_NOT_FOUND) || errors.Is(err, windows.ERROR_PATH_NOT_FOUND) {
			continue
		}
		if err != nil {
			return nil, errors.New("cannot safely read the runtime state")
		}
		body, readErr := io.ReadAll(io.LimitReader(file, windowshost.MaxTransferBytes+1))
		_ = file.Close()
		if readErr != nil {
			return nil, errors.New("cannot read the runtime state")
		}
		files[name] = body
	}
	return files, windowshost.ValidTransfer(files)
}

func (h *windowsPipeHost) importState(files map[string][]byte) error {
	if err := windowshost.ValidTransfer(files); err != nil {
		return err
	}
	// Stage the complete inventory before altering the stopped runtime.
	staged := map[string]string{}
	defer func() {
		for _, temp := range staged {
			_ = os.Remove(temp)
		}
	}()
	for name, body := range files {
		file, err := os.CreateTemp(filepath.Join(h.state, "tmp"), "state-*")
		if err != nil {
			return errors.New("cannot stage the runtime state")
		}
		staged[name] = file.Name()
		_, writeErr := file.Write(body)
		closeErr := file.Close()
		if writeErr != nil || closeErr != nil {
			return errors.New("cannot stage the runtime state")
		}
	}
	h.engine.Close()
	original, err := h.readRuntimeState()
	if err != nil {
		if h.newEngine() != nil {
			h.unusable = true
		}
		return err
	}
	rollback := func() error {
		for _, name := range windowshost.TransferFiles {
			destination := filepath.Join(h.state, filepath.FromSlash(name))
			body, ok := original[name]
			if !ok {
				if err := os.Remove(destination); err != nil && !errors.Is(err, os.ErrNotExist) {
					return err
				}
				continue
			}
			temp, err := os.CreateTemp(filepath.Join(h.state, "tmp"), "restore-*")
			if err != nil {
				return err
			}
			_, writeErr := temp.Write(body)
			closeErr := temp.Close()
			if writeErr != nil || closeErr != nil {
				_ = os.Remove(temp.Name())
				return errors.Join(writeErr, closeErr)
			}
			if err := os.Rename(temp.Name(), destination); err != nil {
				_ = os.Remove(temp.Name())
				return err
			}
		}
		return h.newEngine()
	}
	failure := func() error {
		if err := rollback(); err != nil {
			h.unusable = true
			return errors.New("runtime state could not be restored; the host remains stopped")
		}
		return errors.New("the runtime state was not accepted; its original state was restored")
	}
	for _, name := range windowshost.TransferFiles {
		destination := filepath.Join(h.state, filepath.FromSlash(name))
		if temp, ok := staged[name]; ok {
			if err := os.Rename(temp, destination); err != nil {
				return failure()
			}
		} else if err := os.Remove(destination); err != nil && !errors.Is(err, os.ErrNotExist) {
			return failure()
		}
	}
	if err := h.newEngine(); err != nil {
		return failure()
	}
	return nil
}
