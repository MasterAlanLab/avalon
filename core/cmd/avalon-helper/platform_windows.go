package main

import (
	"crypto/sha256"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unsafe"

	"dev.avalon/core/bridge"
	"dev.avalon/core/internal/windowshost"
	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/mgr"
)

const privateSDDL = "O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)"
const installSDDL = "O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;FRFX;;;BU)"

type windowsPaths struct {
	SID             string `json:"sid"`
	StateDir        string `json:"stateDir"`
	UserStateDir    string `json:"userStateDir"`
	ServiceStateDir string `json:"serviceStateDir"`
	UserPipe        string `json:"userPipe"`
	ServicePipe     string `json:"servicePipe"`
	ServiceName     string `json:"serviceName"`
	Installed       bool   `json:"installed"`
	UpdateRequired  bool   `json:"updateRequired"`
	ServiceRunning  bool   `json:"serviceRunning"`
	ServicePID      uint32 `json:"servicePid"`
	ExecutablePath  string `json:"executablePath"`
	UserExecutable  string `json:"userExecutablePath"`
	privateRuntime  string
	installation    string
	serviceParent   string
}

func currentSID() (string, error) {
	u, err := windows.GetCurrentProcessToken().GetTokenUser()
	if err != nil {
		return "", err
	}
	return u.User.Sid.String(), nil
}

func pathsForSID(sid string) (windowsPaths, error) {
	var p windowsPaths
	if !windowshost.ValidSID(sid) {
		return p, errors.New("a canonical Windows user SID is required")
	}
	programData, err := windows.KnownFolderPath(windows.FOLDERID_ProgramData, 0)
	if err != nil {
		return p, err
	}
	programFiles, err := windows.KnownFolderPath(windows.FOLDERID_ProgramFiles, 0)
	if err != nil {
		return p, err
	}
	localData, err := windows.KnownFolderPath(windows.FOLDERID_LocalAppData, 0)
	if err != nil {
		return p, err
	}
	p.SID = sid
	p.UserStateDir = filepath.Join(localData, "Avalon", "host")
	p.StateDir = p.UserStateDir
	p.serviceParent = filepath.Join(programData, "Avalon", sid)
	p.ServiceStateDir = filepath.Join(p.serviceParent, "shared")
	p.privateRuntime = filepath.Join(p.serviceParent, "runtime")
	p.installation = filepath.Join(programFiles, "Avalon", "helper")
	p.ExecutablePath = filepath.Join(p.installation, "avalon-helper.exe")
	p.UserExecutable, err = os.Executable()
	if err != nil {
		return p, err
	}
	p.UserPipe = windowshost.PipeName(sid, false)
	p.ServicePipe = windowshost.PipeName(sid, true)
	p.ServiceName = windowshost.ServiceName(sid)
	return p, nil
}

func platformMain(action, sid, state, socket string) (bool, error) {
	if action == "" && socket == "" {
		return false, nil // Keep the explicit stdin/stdout developer entry.
	}
	selfSID, err := currentSID()
	if err != nil {
		return true, err
	}
	if sid == "" {
		sid = selfSID
	}
	p, err := pathsForSID(sid)
	if err != nil {
		return true, err
	}
	if action == "serve-service" {
		if selfSID != "S-1-5-18" || !strings.EqualFold(p.UserExecutable, p.ExecutablePath) {
			return true, windows.ERROR_ACCESS_DENIED
		}
		isService, err := svc.IsWindowsService()
		if err != nil || !isService {
			return true, errors.New("service entry requires the Service Control Manager")
		}
		return true, svc.Run(p.ServiceName, &windowsService{paths: p})
	}
	if action == "install" || action == "uninstall" {
		if !windows.GetCurrentProcessToken().IsElevated() {
			return true, windows.ERROR_ACCESS_DENIED
		}
		if action == "install" {
			err = installWindowsService(p)
		} else {
			err = uninstallWindowsService(p)
		}
		if err != nil {
			return true, err
		}
		writePlatformResult(map[string]any{})
		return true, nil
	}
	if selfSID != sid {
		return true, windows.ERROR_ACCESS_DENIED
	}
	switch action {
	case "init", "status":
		if action == "init" {
			if err := makeUserState(p); err != nil {
				return true, err
			}
		}
		if err := inspectWindowsService(&p); err != nil {
			return true, err
		}
		writePlatformResult(p)
		return true, nil
	case "start-service":
		if err := startWindowsService(p); err != nil {
			return true, err
		}
		if err := inspectWindowsService(&p); err != nil {
			return true, err
		}
		writePlatformResult(p)
		return true, nil
	case "":
		if !strings.EqualFold(filepath.Clean(state), p.UserStateDir) || !strings.EqualFold(socket, p.UserPipe) {
			return true, errors.New("user helper state and pipe must match this Windows account")
		}
		if err := makeUserState(p); err != nil {
			return true, err
		}
		return true, runWindowsPipeReady(p, false, nil, nil)
	default:
		return true, errors.New("unsupported Windows helper action")
	}
}

func writePlatformResult(value any) {
	_ = json.NewEncoder(os.Stdout).Encode(map[string]any{"result": value})
}

func writePlatformError(err error) {
	code := bridge.CodeCoreFailed
	if errors.Is(err, windows.ERROR_ACCESS_DENIED) || errors.Is(err, windows.ERROR_CANCELLED) {
		code = bridge.CodePermissionDenied
	}
	// CLI errors never contain plans, credentials or request bodies.
	_ = json.NewEncoder(os.Stdout).Encode(map[string]any{"error": map[string]any{"code": code, "message": err.Error()}})
}

func makeUserState(p windowsPaths) error {
	if err := os.MkdirAll(p.UserStateDir, 0o700); err != nil {
		return err
	}
	if err := setPathDACL(p.UserStateDir, "D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;"+p.SID+")"); err != nil {
		return err
	}
	return os.MkdirAll(filepath.Join(p.UserStateDir, "rulesets"), 0o700)
}

func setPathDACL(path, sddl string) error {
	sd, err := windows.SecurityDescriptorFromString(sddl)
	if err != nil {
		return err
	}
	dacl, _, err := sd.DACL()
	if err != nil {
		return err
	}
	return windows.SetNamedSecurityInfo(path, windows.SE_FILE_OBJECT, windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION, nil, nil, dacl, nil)
}

// secureDirectory creates each privileged directory atomically with its DACL.
// Existing directories must already belong to SYSTEM/Administrators. In
// particular, an unprivileged account cannot pre-create Avalon and have an
// elevated installer adopt a junction, hard link or user-controlled directory.
func secureDirectory(path, sddl string) error {
	parent := filepath.Dir(path)
	if err := rejectReparseChain(parent); err != nil {
		return err
	}
	sd, err := windows.SecurityDescriptorFromString(sddl)
	if err != nil {
		return err
	}
	sa := windows.SecurityAttributes{Length: uint32(unsafe.Sizeof(windows.SecurityAttributes{})), SecurityDescriptor: sd}
	name, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return err
	}
	err = windows.CreateDirectory(name, &sa)
	if err != nil && !errors.Is(err, windows.ERROR_ALREADY_EXISTS) {
		return err
	}
	if err := rejectReparseChain(path); err != nil {
		return err
	}
	info, err := windows.GetNamedSecurityInfo(path, windows.SE_FILE_OBJECT, windows.OWNER_SECURITY_INFORMATION)
	if err != nil {
		return err
	}
	owner, _, err := info.Owner()
	if err != nil || owner == nil || !owner.IsWellKnown(windows.WinLocalSystemSid) && !owner.IsWellKnown(windows.WinBuiltinAdministratorsSid) {
		return errors.New("privileged helper directory has an untrusted owner")
	}
	return setPathDACL(path, sddl)
}

func rejectReparseChain(path string) error {
	for {
		ptr, err := windows.UTF16PtrFromString(path)
		if err != nil {
			return err
		}
		attrs, err := windows.GetFileAttributes(ptr)
		if err != nil {
			return err
		}
		if attrs&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 {
			return errors.New("helper paths cannot contain reparse points")
		}
		parent := filepath.Dir(path)
		if parent == path {
			return nil
		}
		path = parent
	}
}

func installWindowsService(p windowsPaths) error {
	for _, path := range []string{filepath.Dir(p.installation), p.installation} {
		if err := secureDirectory(path, installSDDL); err != nil {
			return err
		}
	}
	for _, path := range []string{filepath.Dir(p.serviceParent), p.serviceParent} {
		if err := secureDirectory(path, privateSDDL); err != nil {
			return err
		}
	}
	// Directory itself is not deletable/reconfigurable by the user. Files
	// inherit modify rights, while the pre-created rulesets directory has its
	// own protected DACL. SYSTEM never runs the core in this shared tree.
	sharedSDDL := "O:BAG:BAD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;;0x1200ab;;;" + p.SID + ")(A;OIIO;0x1301bf;;;" + p.SID + ")"
	for _, path := range []string{p.ServiceStateDir, filepath.Join(p.ServiceStateDir, "rulesets")} {
		if err := secureDirectory(path, sharedSDDL); err != nil {
			return err
		}
	}
	for _, path := range []string{p.privateRuntime, filepath.Join(p.privateRuntime, "tmp"), filepath.Join(p.privateRuntime, "rulesets"), filepath.Join(p.privateRuntime, "tailscale")} {
		if err := secureDirectory(path, privateSDDL); err != nil {
			return err
		}
	}
	manager, err := mgr.Connect()
	if err != nil {
		return err
	}
	defer manager.Disconnect()
	service, err := manager.OpenService(p.ServiceName)
	if err == nil {
		defer service.Close()
		status, err := service.Query()
		if err != nil {
			return err
		}
		if status.State != svc.Stopped {
			return errors.New("stop the Avalon helper before updating its service")
		}
	} else if !errors.Is(err, windows.ERROR_SERVICE_DOES_NOT_EXIST) {
		return err
	}
	if err := installSelf(p); err != nil {
		return err
	}
	args := []string{"-windows-action", "serve-service", "-sid", p.SID}
	if service == nil {
		service, err = manager.CreateService(p.ServiceName, p.ExecutablePath, mgr.Config{DisplayName: "Avalon tunnel (" + p.SID + ")", StartType: mgr.StartManual, ServiceStartName: "LocalSystem", ErrorControl: mgr.ErrorNormal}, args...)
		if err != nil {
			return err
		}
		defer service.Close()
	} else {
		config, err := service.Config()
		if err != nil {
			return err
		}
		config.BinaryPathName = windows.ComposeCommandLine(append([]string{p.ExecutablePath}, args...))
		config.ServiceStartName = "LocalSystem"
		config.StartType = mgr.StartManual
		if err := service.UpdateConfig(config); err != nil {
			return err
		}
	}
	// No restart-on-crash: a failure remains stopped until the user retries.
	if err := service.SetRecoveryActions(nil, 0); err != nil {
		return err
	}
	sd, err := windows.SecurityDescriptorFromString("D:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;CCLCSWRPWPLOCRRC;;;" + p.SID + ")")
	if err != nil {
		return err
	}
	dacl, _, err := sd.DACL()
	if err != nil {
		return err
	}
	return windows.SetSecurityInfo(service.Handle, windows.SE_SERVICE, windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION, nil, nil, dacl, nil)
}

func installSelf(p windowsPaths) error {
	if strings.EqualFold(p.UserExecutable, p.ExecutablePath) {
		return nil
	}
	directories, err := pinSourceDirectories(filepath.Dir(p.UserExecutable))
	if err != nil {
		return err
	}
	defer func() {
		for _, handle := range directories {
			_ = windows.CloseHandle(handle)
		}
	}()
	ptr, _ := windows.UTF16PtrFromString(p.UserExecutable)
	h, err := windows.CreateFile(ptr, windows.GENERIC_READ, windows.FILE_SHARE_READ, nil, windows.OPEN_EXISTING, windows.FILE_FLAG_OPEN_REPARSE_POINT, 0)
	if err != nil {
		return err
	}
	source := os.NewFile(uintptr(h), "helper-source")
	defer source.Close()
	if err := regularHandle(h); err != nil {
		return err
	}
	body, err := io.ReadAll(io.LimitReader(source, 128<<20+1))
	if err != nil || len(body) > 128<<20 {
		return errors.New("the helper image cannot be read safely")
	}
	if err := windowshost.ValidateImage(body, compiledImageSeal); err != nil {
		return err
	}
	if old, err := os.ReadFile(p.ExecutablePath); err == nil {
		if sha256.Sum256(old) == sha256.Sum256(body) {
			return nil
		}
	}
	// The private install directory is not writable by the requesting user.
	temp := p.ExecutablePath + ".next"
	_ = os.Remove(temp)
	dest, err := os.OpenFile(temp, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		return err
	}
	_, copyErr := dest.Write(body)
	closeErr := dest.Close()
	if copyErr != nil || closeErr != nil {
		_ = os.Remove(temp)
		return errors.Join(copyErr, closeErr)
	}
	// Helper must be executable/readable by a standard user too.
	if err := setPathDACL(temp, "D:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;FRFX;;;BU)"); err != nil {
		return err
	}
	return os.Rename(temp, p.ExecutablePath)
}

func pinSourceDirectories(path string) ([]windows.Handle, error) {
	chain := []string{}
	for current := path; ; current = filepath.Dir(current) {
		chain = append(chain, current)
		if filepath.Dir(current) == current {
			break
		}
	}
	handles := []windows.Handle{}
	for index := len(chain) - 1; index >= 0; index-- {
		ptr, err := windows.UTF16PtrFromString(chain[index])
		if err != nil {
			return nil, err
		}
		handle, err := windows.CreateFile(ptr, windows.FILE_READ_ATTRIBUTES, windows.FILE_SHARE_READ|windows.FILE_SHARE_WRITE, nil, windows.OPEN_EXISTING, windows.FILE_FLAG_BACKUP_SEMANTICS|windows.FILE_FLAG_OPEN_REPARSE_POINT, 0)
		if err == nil {
			var info windows.ByHandleFileInformation
			err = windows.GetFileInformationByHandle(handle, &info)
			if err == nil && (info.FileAttributes&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 || info.FileAttributes&windows.FILE_ATTRIBUTE_DIRECTORY == 0) {
				err = errors.New("the helper source directory cannot contain reparse points")
			}
			if err != nil {
				_ = windows.CloseHandle(handle)
			}
		}
		if err != nil {
			for _, previous := range handles {
				_ = windows.CloseHandle(previous)
			}
			return nil, err
		}
		handles = append(handles, handle)
	}
	return handles, nil
}

func openService(p windowsPaths, access uint32) (*mgr.Service, error) {
	name, _ := windows.UTF16PtrFromString(p.ServiceName)
	h, err := windows.OpenSCManager(nil, nil, windows.SC_MANAGER_CONNECT)
	if err != nil {
		return nil, err
	}
	defer windows.CloseServiceHandle(h)
	service, err := windows.OpenService(h, name, access)
	if err != nil {
		return nil, err
	}
	return &mgr.Service{Name: p.ServiceName, Handle: service}, nil
}

func inspectWindowsService(p *windowsPaths) error {
	service, err := openService(*p, windows.SERVICE_QUERY_STATUS|windows.SERVICE_QUERY_CONFIG)
	if errors.Is(err, windows.ERROR_SERVICE_DOES_NOT_EXIST) {
		return nil
	}
	if err != nil {
		return err
	}
	defer service.Close()
	config, err := service.Config()
	if err != nil {
		return err
	}
	args, err := windows.DecomposeCommandLine(config.BinaryPathName)
	if err != nil || len(args) != 5 || !strings.EqualFold(args[0], p.ExecutablePath) || args[1] != "-windows-action" || args[2] != "serve-service" || args[3] != "-sid" || args[4] != p.SID || !strings.EqualFold(config.ServiceStartName, "LocalSystem") || config.StartType != mgr.StartManual {
		return errors.New("the installed Avalon service has an unexpected configuration")
	}
	if err := rejectReparseChain(p.ExecutablePath); err != nil {
		return err
	}
	installed, err := openRegular(p.ExecutablePath, windows.GENERIC_READ, windows.OPEN_EXISTING)
	if err != nil {
		return err
	}
	body, readErr := io.ReadAll(io.LimitReader(installed, 128<<20+1))
	closeErr := installed.Close()
	if readErr != nil || closeErr != nil || len(body) > 128<<20 {
		return errors.New("the installed helper image cannot be read safely")
	}
	// Compare with the current bundle's loaded image, without disrupting an
	// active session. Updating remains an explicit elevated install action.
	p.UpdateRequired = windowshost.ValidateImage(body, compiledImageSeal) != nil
	status, err := service.Query()
	if err != nil {
		return err
	}
	p.Installed = true
	// Pending and paused states still own the service image/runtime. Clients
	// may only update it after SCM reports the fully stopped state.
	p.ServiceRunning = status.State != svc.Stopped
	p.ServicePID = status.ProcessId
	return nil
}

func startWindowsService(p windowsPaths) error {
	if err := inspectWindowsService(&p); err != nil {
		return err
	}
	if !p.Installed {
		return errors.New("the Avalon tunnel service is not installed")
	}
	service, err := openService(p, windows.SERVICE_START|windows.SERVICE_QUERY_STATUS)
	if err != nil {
		return err
	}
	defer service.Close()
	if err := service.Start(); err != nil && !errors.Is(err, windows.ERROR_SERVICE_ALREADY_RUNNING) {
		return err
	}
	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		status, err := service.Query()
		if err != nil {
			return err
		}
		if status.State == svc.Running {
			return nil
		}
		if status.State == svc.Stopped {
			return errors.New("the Avalon tunnel service failed to start")
		}
		time.Sleep(50 * time.Millisecond)
	}
	return errors.New("timed out starting the Avalon tunnel service")
}

func uninstallWindowsService(p windowsPaths) error {
	manager, err := mgr.Connect()
	if err != nil {
		return err
	}
	defer manager.Disconnect()
	service, err := manager.OpenService(p.ServiceName)
	if errors.Is(err, windows.ERROR_SERVICE_DOES_NOT_EXIST) {
		return nil
	}
	if err != nil {
		return err
	}
	defer service.Close()
	status, err := service.Query()
	if err != nil {
		return err
	}
	if status.State != svc.Stopped {
		if _, err := service.Control(svc.Stop); err != nil {
			return err
		}
		deadline := time.Now().Add(10 * time.Second)
		for status.State != svc.Stopped {
			if time.Now().After(deadline) {
				return errors.New("timed out stopping the Avalon tunnel service")
			}
			time.Sleep(50 * time.Millisecond)
			status, err = service.Query()
			if err != nil {
				return err
			}
		}
	}
	// State and the shared installation are retained; another SID may use the
	// same binary. The elevated uninstaller removes this account's service.
	return service.Delete()
}

// Keep the old stdin build entry compilable; Windows socket mode is dispatched
// before constructing a core so its privilege boundary always runs first.
func serve(*bridge.Engine, string, int) error {
	return errors.New("use the Windows account pipe entry")
}
func tunAvailable() bool { return false }
