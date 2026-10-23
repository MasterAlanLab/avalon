// avalon-helper is the Core Bridge as a process, for Windows and Linux
// (docs/RUNTIME_HOST.md §8). It answers bridge commands, one JSON object
// per line:
//
//	→ {"command": "start", "request": {"requestId": "…", "plan": {…}, "planHash": "…"}}
//	← {"result": {"sessionId": "…"}}
//
// With -socket the lines travel over a Unix socket only the user may open
// (Linux, and macOS for development); otherwise over standard input and
// output. Windows' transport and service come with spike S4's Windows half.
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	"dev.avalon/core/bridge"
)

type line struct {
	Command string          `json:"command"`
	Request json.RawMessage `json:"request"`
}

func main() {
	state := flag.String("state", "", "directory for the core's files (cache, Tailscale state)")
	socket := flag.String("socket", "", "serve on this Unix socket instead of standard input")
	allowUID := flag.Int("allow-uid", os.Getuid(), "the user whose processes may use the socket")
	windowsAction := flag.String("windows-action", "", "Windows helper lifecycle action")
	sid := flag.String("sid", "", "Windows account SID whose private host is used")
	flag.Parse()
	if handled, err := platformMain(*windowsAction, *sid, *state, *socket); handled {
		if err != nil {
			writePlatformError(err)
			os.Exit(1)
		}
		return
	}
	if *state == "" {
		fmt.Fprintln(os.Stderr, "avalon-helper: -state is required")
		os.Exit(2)
	}
	temp := filepath.Join(*state, "tmp")
	if err := os.MkdirAll(temp, 0o700); err != nil {
		fmt.Fprintln(os.Stderr, "avalon-helper:", err)
		os.Exit(1)
	}
	engine := bridge.NewEngine(bridge.NewDesktopService(*state, temp), runtime.GOOS, *state)
	defer engine.Close()
	engine.ReportTun(tunAvailable)

	if *socket != "" {
		if err := serve(engine, *socket, *allowUID); err != nil {
			fmt.Fprintln(os.Stderr, "avalon-helper:", err)
			os.Exit(1)
		}
		return
	}

	input := bufio.NewScanner(os.Stdin)
	input.Buffer(make([]byte, 0, 1<<20), 64<<20) // A plan can be megabytes.
	output := bufio.NewWriter(os.Stdout)
	for input.Scan() {
		var request line
		var response []byte
		if err := json.Unmarshal(input.Bytes(), &request); err != nil {
			response, _ = json.Marshal(bridge.Response{Error: &bridge.Error{
				Code: bridge.CodePlanInvalid, Message: "malformed line", Detail: err.Error(),
			}})
		} else {
			response = engine.Call(request.Command, request.Request)
		}
		_, _ = output.Write(response)
		_ = output.WriteByte('\n')
		_ = output.Flush()
	}
}
