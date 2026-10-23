//go:build !windows

package main

import (
	"bufio"
	"encoding/json"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"dev.avalon/core/bridge"
)

func startServing(t *testing.T, allowUID int) string {
	t.Helper()
	dir := t.TempDir()
	// Unix socket paths are short (104 bytes on macOS): not under TempDir.
	short, err := os.MkdirTemp("/tmp", "avh")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(short) })
	socket := filepath.Join(short, "run", "host.sock")
	engine := bridge.NewEngine(bridge.NewDesktopService(dir, dir), runtime.GOOS, dir)
	t.Cleanup(engine.Close)
	engine.ReportTun(tunAvailable)
	go func() { _ = serve(engine, socket, allowUID) }()
	for i := 0; i < 100; i++ {
		if _, err := os.Stat(socket); err == nil {
			return socket
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("the socket did not appear")
	return ""
}

func exchange(t *testing.T, socket, line string) (string, error) {
	t.Helper()
	conn, err := net.Dial("unix", socket)
	if err != nil {
		return "", err
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
	if _, err := conn.Write([]byte(line + "\n")); err != nil {
		return "", err
	}
	return bufio.NewReader(conn).ReadString('\n')
}

func TestSocketAnswersTheUser(t *testing.T) {
	socket := startServing(t, os.Getuid())
	info, err := os.Stat(socket)
	if err != nil {
		t.Fatal(err)
	}
	if mode := info.Mode().Perm(); mode != 0o600 {
		t.Fatalf("socket mode %o, want 600", mode)
	}
	if dir, _ := os.Stat(filepath.Dir(socket)); dir.Mode().Perm() != 0o700 {
		t.Fatalf("directory mode %o, want 700", dir.Mode().Perm())
	}
	answer, err := exchange(t, socket, `{"command": "capabilities"}`)
	if err != nil {
		t.Fatal(err)
	}
	var response struct {
		Result bridge.Capabilities `json:"result"`
	}
	if err := json.Unmarshal([]byte(answer), &response); err != nil {
		t.Fatalf("%v: %q", err, answer)
	}
	if response.Result.ProtocolVersion != bridge.ProtocolVersion || response.Result.Tun == nil || *response.Result.Tun != tunAvailable() {
		t.Fatalf("capabilities: %+v", response.Result)
	}
	// A malformed line is answered, not fatal.
	answer, err = exchange(t, socket, `not json`)
	if err != nil || len(answer) == 0 {
		t.Fatalf("malformed line: %q %v", answer, err)
	}
}

func TestSocketRefusesOtherUsers(t *testing.T) {
	socket := startServing(t, os.Getuid()+1)
	if answer, err := exchange(t, socket, `{"command": "capabilities"}`); err == nil && answer != "" {
		t.Fatalf("answered another user: %q", answer)
	}
}

func TestSocketKeepsAnotherHelpersPlace(t *testing.T) {
	socket := startServing(t, os.Getuid())
	dir := t.TempDir()
	engine := bridge.NewEngine(bridge.NewDesktopService(dir, dir), runtime.GOOS, dir)
	defer engine.Close()
	if err := serve(engine, socket, os.Getuid()); err == nil {
		t.Fatal("a second helper took the socket")
	}
}
