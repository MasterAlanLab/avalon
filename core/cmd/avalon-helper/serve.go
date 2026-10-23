//go:build !windows

package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"syscall"

	"dev.avalon/core/bridge"
)

// serve answers bridge commands on a Unix socket, one JSON object per line
// each way, for as many connections as the app opens (docs/RUNTIME_HOST.md
// §8). The socket is the current user's only: its directory is 0700, the
// socket 0600, and each connection's peer must be the same user.
func serve(engine *bridge.Engine, path string, allowUID int) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	// A socket left by a helper that is gone: nobody answers it.
	if conn, err := net.Dial("unix", path); err == nil {
		conn.Close()
		return fmt.Errorf("another helper already answers on %s", path)
	}
	_ = os.Remove(path)
	old := syscall.Umask(0o177)
	listener, err := net.Listen("unix", path)
	syscall.Umask(old)
	if err != nil {
		return err
	}
	defer listener.Close()
	if err := os.Chmod(path, 0o600); err != nil {
		return err
	}
	for {
		conn, err := listener.Accept()
		if err != nil {
			if errors.Is(err, net.ErrClosed) {
				return nil
			}
			return err
		}
		go handle(engine, conn.(*net.UnixConn), allowUID)
	}
}

func handle(engine *bridge.Engine, conn *net.UnixConn, allowUID int) {
	defer conn.Close()
	uid, err := peerUID(conn)
	if err != nil || uid != allowUID {
		fmt.Fprintf(os.Stderr, "avalon-helper: refused a connection from uid %d (%v)\n", uid, err)
		return
	}
	input := bufio.NewScanner(conn)
	input.Buffer(make([]byte, 0, 1<<20), 64<<20) // A plan can be megabytes.
	output := bufio.NewWriter(conn)
	for input.Scan() {
		if _, err := output.Write(answer(engine, input.Bytes())); err != nil {
			return
		}
		_ = output.WriteByte('\n')
		if output.Flush() != nil {
			return
		}
	}
}

// answer runs one line: {"command": "…", "request": {…}}.
func answer(engine *bridge.Engine, line []byte) []byte {
	var request struct {
		Command string          `json:"command"`
		Request json.RawMessage `json:"request"`
	}
	if err := json.Unmarshal(line, &request); err != nil {
		response, _ := json.Marshal(bridge.Response{Error: &bridge.Error{
			Code: bridge.CodePlanInvalid, Message: "malformed line", Detail: err.Error(),
		}})
		return response
	}
	return engine.Call(request.Command, request.Request)
}
