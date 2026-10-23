package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"dev.avalon/core/bridge"
	"dev.avalon/core/internal/windowshost"
	winio "github.com/tailscale/go-winio"
	"golang.org/x/sys/windows"
)

func TestWindowsPipeAuthenticatesTheAccount(t *testing.T) {
	sid, err := currentSID()
	if err != nil {
		t.Fatal(err)
	}
	name := windowshost.PipeName(sid, false) + "-test"
	l, err := winio.ListenPipe(name, &winio.PipeConfig{SecurityDescriptor: "D:P(A;;GA;;;SY)(A;;GA;;;" + sid + ")"})
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	done := make(chan error, 1)
	go func() {
		connection, err := l.Accept()
		if err != nil {
			done <- err
			return
		}
		defer connection.Close()
		_, err = clientToken(connection, sid, false)
		done <- err
	}()
	connection, err := winio.DialPipe(name, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer connection.Close()
	if err := <-done; err != nil {
		t.Fatal(err)
	}
	if _, err := winio.ListenPipe(name, nil); err == nil {
		t.Fatal("a second pipe listener adopted the existing endpoint")
	}
}

func TestWindowsSharedFilesRejectHardlinksAndTraversal(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "plan.json")
	if err := os.WriteFile(file, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	for _, path := range []string{filepath.Join(dir, "..", "outside.json"), file + ":stream", `\\server\share\plan.json`, file + "."} {
		if err := directChild(path, dir); err == nil {
			t.Fatalf("accepted %s", path)
		}
	}
	linked := filepath.Join(dir, "linked.json")
	if err := os.Link(file, linked); err != nil {
		t.Fatal(err)
	}
	if f, err := openRegular(file, windows.GENERIC_READ, windows.OPEN_EXISTING); err == nil {
		f.Close()
		t.Fatal("accepted a multiply-linked plan")
	}
}

func TestWindowsStateTransferRetainsIdentity(t *testing.T) {
	from := &windowsPipeHost{state: t.TempDir()}
	to := &windowsPipeHost{state: t.TempDir()}
	if err := from.newEngine(); err != nil {
		t.Fatal(err)
	}
	defer func() { from.engine.Close() }()
	if err := to.newEngine(); err != nil {
		t.Fatal(err)
	}
	defer func() { to.engine.Close() }()
	identity := []byte(`{"test-identity":"retained"}`)
	if err := os.WriteFile(filepath.Join(from.state, "tailscale", "tailscaled.state"), identity, 0o600); err != nil {
		t.Fatal(err)
	}
	files, err := from.exportState()
	if err != nil {
		t.Fatal(err)
	}
	if err := to.importState(files); err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile(filepath.Join(to.state, "tailscale", "tailscaled.state"))
	if err != nil || string(got) != string(identity) {
		t.Fatalf("identity changed: %s, %v", got, err)
	}
	answer, _ := to.call(line{Command: "hostImportState", Request: json.RawMessage(`{"version":1,"files":{"../outside":"eA=="}}`)}, 0)
	var response bridge.Response
	if json.Unmarshal(answer, &response) != nil || response.Error == nil {
		t.Fatalf("accepted arbitrary transfer path: %s", answer)
	}
}

func TestWindowsStateReopenFailureIsVisibleAndCanShutDown(t *testing.T) {
	host := &windowsPipeHost{state: t.TempDir()}
	if err := host.newEngine(); err != nil {
		t.Fatal(err)
	}
	defer host.engine.Close()
	// A stopped user host can lose a directory (for example during disk or
	// filesystem recovery). Export must not report a healthy replacement
	// engine when its runtime cannot be reopened.
	temp := filepath.Join(host.state, "tmp")
	if err := os.Remove(temp); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(temp, []byte("not a directory"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := host.exportState(); err == nil {
		t.Fatal("reported a successful export after runtime reopen failed")
	}
	answer, _ := host.call(line{Command: "snapshot", Request: json.RawMessage(`{}`)}, 0)
	var snapshot struct {
		Result struct {
			State string        `json:"state"`
			Error *bridge.Error `json:"error"`
		} `json:"result"`
	}
	if err := json.Unmarshal(answer, &snapshot); err != nil || snapshot.Result.State != "failed" || snapshot.Result.Error == nil {
		t.Fatalf("unusable host did not expose its failure: %s, %v", answer, err)
	}
	answer, _ = host.call(line{Command: "start", Request: json.RawMessage(`{}`)}, 0)
	var response bridge.Response
	if err := json.Unmarshal(answer, &response); err != nil || response.Error == nil {
		t.Fatalf("unusable host accepted a start: %s, %v", answer, err)
	}
	answer, shutdown := host.call(line{Command: "hostShutdown", Request: json.RawMessage(`{}`)}, 0)
	response = bridge.Response{}
	if err := json.Unmarshal(answer, &response); err != nil || !shutdown || response.Error != nil {
		t.Fatalf("unusable host could not shut down: %s, %v", answer, err)
	}
}

func TestWindowsInstallerPinsSourceAncestorsUntilCopyCompletes(t *testing.T) {
	root := t.TempDir()
	source := filepath.Join(root, "source")
	if err := os.Mkdir(source, 0o700); err != nil {
		t.Fatal(err)
	}
	handles, err := pinSourceDirectories(source)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		for _, handle := range handles {
			_ = windows.CloseHandle(handle)
		}
	}()
	if err := os.Rename(source, filepath.Join(root, "replaced")); err == nil {
		t.Fatal("source directory could be replaced while the installer was copying")
	}
}
