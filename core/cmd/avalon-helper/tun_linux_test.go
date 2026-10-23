package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

// TestTunThroughSocket opens a TUN interface through the socket, sends a
// request through it and closes it again (spike S4, Linux). It needs
// CAP_NET_ADMIN and /dev/net/tun; core/check_linux_helper.sh runs it in a
// container. AVALON_TUN_TARGET is an address outside the container.
func TestTunThroughSocket(t *testing.T) {
	target := os.Getenv("AVALON_TUN_TARGET")
	if target == "" {
		t.Skip("AVALON_TUN_TARGET is not set; run core/check_linux_helper.sh")
	}
	socket := startServing(t, os.Getuid())
	call := func(command string, request any) map[string]any {
		t.Helper()
		line, _ := json.Marshal(map[string]any{"command": command, "request": request})
		answer, err := exchange(t, socket, string(line))
		if err != nil {
			t.Fatalf("%s: %v", command, err)
		}
		var response map[string]any
		if err := json.Unmarshal([]byte(answer), &response); err != nil {
			t.Fatalf("%s: %v %q", command, err, answer)
		}
		if response["error"] != nil {
			t.Fatalf("%s: %v", command, response["error"])
		}
		result, _ := response["result"].(map[string]any)
		return result
	}

	if tun, _ := call("capabilities", nil)["tun"].(bool); !tun {
		t.Fatal("the helper does not report TUN although it may open one")
	}
	const name = "avtun0"
	plan := map[string]any{
		"log": map[string]any{"level": "info"},
		"inbounds": []any{map[string]any{
			"type": "tun", "tag": "tun-in", "interface_name": name,
			"address": []string{"172.19.0.1/30"}, "mtu": 1500,
			"auto_route": true, "stack": "gvisor",
		}},
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
		"route":     map[string]any{"final": "direct", "auto_detect_interface": true},
	}
	session := call("start", map[string]any{"requestId": "tun-1", "plan": plan, "planHash": "tun"})
	sessionID, _ := session["sessionId"].(string)
	if _, err := net.InterfaceByName(name); err != nil {
		t.Fatalf("no %s after start: %v", name, err)
	}

	// Through the tunnel: the core sees the connection come in on it.
	client := &http.Client{Timeout: 5 * time.Second}
	response, err := client.Get(target)
	if err != nil {
		t.Fatalf("no answer through the tunnel: %v", err)
	}
	response.Body.Close()
	host := strings.TrimPrefix(strings.TrimPrefix(target, "http://"), "https://")
	host = host[:strings.IndexAny(host+"/", ":/")]
	logs := call("logs", map[string]any{"afterSeq": 0, "limit": 500})
	raw, _ := json.Marshal(logs)
	if !strings.Contains(string(raw), "inbound/tun[tun-in]") {
		t.Fatalf("the request did not come in on the tunnel (%s): %s", host, raw)
	}

	call("stop", map[string]any{"requestId": "tun-2", "sessionId": sessionID})
	for i := 0; i < 50; i++ {
		if _, err := net.InterfaceByName(name); err != nil {
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatalf("%s is still there after stop", name)
}

// TestNoTunWithoutTheCapability: an unprivileged helper says so, and the
// app then asks for the capability rather than fail on start.
func TestNoTunWithoutTheCapability(t *testing.T) {
	if os.Getenv("AVALON_TUN_EXPECT_NONE") == "" {
		t.Skip("run by core/check_linux_helper.sh as an unprivileged user")
	}
	if tunAvailable() {
		t.Fatal("reports TUN without CAP_NET_ADMIN")
	}
	fmt.Println("no TUN without the capability, as expected")
}
