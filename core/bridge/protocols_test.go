package bridge

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// TestProtocolMatrix connects through a real sing-box server with every
// protocol, transport and security combination Avalon offers (spike S5).
// The client plan is what Avalon's compiler makes of the nodes; the server
// runs in a container (see check_protocols.sh). Skipped without it.
func TestProtocolMatrix(t *testing.T) {
	dir := os.Getenv("AVALON_MATRIX")
	if dir == "" {
		t.Skip("AVALON_MATRIX is not set; run core/check_protocols.sh")
	}
	plan, err := os.ReadFile(filepath.Join(dir, "plan.json"))
	if err != nil {
		t.Fatal(err)
	}
	var matrix struct {
		Group     string `json:"group"`
		MixedPort int    `json:"mixedPort"`
		Cases     []struct {
			Name      string `json:"name"`
			Tag       string `json:"tag"`
			RelaysUDP bool   `json:"relaysUdp"`
		} `json:"cases"`
	}
	raw, err := os.ReadFile(filepath.Join(dir, "cases.json"))
	if err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(raw, &matrix); err != nil {
		t.Fatal(err)
	}

	// Where the requests end up: this process, reached from the server's
	// container by the name Docker gives the host.
	const greeting = "avalon protocol matrix"
	origin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, greeting)
	}))
	defer origin.Close()
	target := "http://host.docker.internal:" + origin.URL[strings.LastIndex(origin.URL, ":")+1:] + "/"

	// And for UDP: an echo, reached the same way.
	echo, err := net.ListenPacket("udp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer echo.Close()
	go func() {
		buffer := make([]byte, 2048)
		for {
			n, from, err := echo.ReadFrom(buffer)
			if err != nil {
				return
			}
			_, _ = echo.WriteTo(buffer[:n], from)
		}
	}()
	echoPort := echo.LocalAddr().(*net.UDPAddr).Port

	e := newEngine(t)
	var session sessionResult
	if err := call(t, e, "start", map[string]any{"plan": json.RawMessage(plan), "planHash": "matrix"}, &session); err != nil {
		t.Fatalf("the core rejects the compiled plan: %v", err)
	}
	client := through(matrix.MixedPort)
	client.Timeout = 10 * time.Second

	for _, c := range matrix.Cases {
		t.Run(c.Name, func(t *testing.T) {
			request := selectRequest{SessionID: session.SessionID, GroupTag: matrix.Group, MemberTag: c.Tag}
			if err := call(t, e, "select", request, nil); err != nil {
				t.Fatalf("select: %v", err)
			}
			began := time.Now()
			response, err := client.Get(target)
			if err != nil {
				t.Fatalf("no answer through %s: %v%s", c.Tag, err, recentLogs(t, e))
			}
			body, _ := io.ReadAll(response.Body)
			response.Body.Close()
			if response.StatusCode != http.StatusOK || string(body) != greeting {
				t.Fatalf("unexpected answer: %d %q%s", response.StatusCode, body, recentLogs(t, e))
			}
			t.Logf("answered in %v", time.Since(began).Round(time.Millisecond))
			if !c.RelaysUDP {
				return
			}
			message := "avalon udp " + c.Name
			reply, err := udpThroughSocks(matrix.MixedPort, "host.docker.internal", echoPort, []byte(message))
			if err != nil {
				t.Fatalf("no UDP answer through %s: %v%s", c.Tag, err, recentLogs(t, e))
			}
			if string(reply) != message {
				t.Fatalf("unexpected UDP answer: %q", reply)
			}
			t.Logf("UDP echoed")
		})
	}
}

// recentLogs is the tail of the core's log, for a failed case.
func recentLogs(t *testing.T, e *Engine) string {
	t.Helper()
	page := e.logs.page(0, logBufferSize)
	from := len(page.Entries) - 8
	if from < 0 {
		from = 0
	}
	var out strings.Builder
	for _, entry := range page.Entries[from:] {
		fmt.Fprintf(&out, "\n    %s %s", entry.Level, entry.Message)
	}
	return out.String()
}

// udpThroughSocks sends one datagram to host:port through the SOCKS5
// side of the mixed inbound (UDP ASSOCIATE, RFC 1928) and returns the
// answer.
func udpThroughSocks(socksPort int, host string, port int, payload []byte) ([]byte, error) {
	control, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", socksPort), 5*time.Second)
	if err != nil {
		return nil, err
	}
	defer control.Close()
	_ = control.SetDeadline(time.Now().Add(10 * time.Second))
	reply := make([]byte, 262)
	// No authentication.
	if _, err := control.Write([]byte{5, 1, 0}); err != nil {
		return nil, err
	}
	if _, err := io.ReadFull(control, reply[:2]); err != nil || reply[1] != 0 {
		return nil, fmt.Errorf("greeting: %v %v", reply[:2], err)
	}
	// UDP ASSOCIATE from any address.
	if _, err := control.Write([]byte{5, 3, 0, 1, 0, 0, 0, 0, 0, 0}); err != nil {
		return nil, err
	}
	if _, err := io.ReadFull(control, reply[:4]); err != nil || reply[1] != 0 {
		return nil, fmt.Errorf("associate: %v %v", reply[:4], err)
	}
	var relayHost string
	switch reply[3] {
	case 1:
		if _, err := io.ReadFull(control, reply[:4]); err != nil {
			return nil, err
		}
		relayHost = net.IP(reply[:4]).String()
	case 4:
		if _, err := io.ReadFull(control, reply[:16]); err != nil {
			return nil, err
		}
		relayHost = net.IP(reply[:16]).String()
	default:
		return nil, fmt.Errorf("relay address type %d", reply[3])
	}
	if _, err := io.ReadFull(control, reply[:2]); err != nil {
		return nil, err
	}
	relayPort := int(reply[0])<<8 | int(reply[1])
	if ip := net.ParseIP(relayHost); ip == nil || ip.IsUnspecified() {
		relayHost = "127.0.0.1"
	}
	relay, err := net.Dial("udp", net.JoinHostPort(relayHost, fmt.Sprint(relayPort)))
	if err != nil {
		return nil, err
	}
	defer relay.Close()
	// RSV RSV FRAG ATYP=domain LEN host PORT data
	packet := []byte{0, 0, 0, 3, byte(len(host))}
	packet = append(packet, host...)
	packet = append(packet, byte(port>>8), byte(port))
	packet = append(packet, payload...)
	buffer := make([]byte, 2048)
	// UDP may be lost on the way: a few tries.
	for attempt := 0; attempt < 5; attempt++ {
		if _, err := relay.Write(packet); err != nil {
			return nil, err
		}
		_ = relay.SetReadDeadline(time.Now().Add(2 * time.Second))
		n, err := relay.Read(buffer)
		if err != nil {
			continue
		}
		// Skip the header the relay puts before the data.
		if n < 4 {
			return nil, fmt.Errorf("short answer")
		}
		offset := 4
		switch buffer[3] {
		case 1:
			offset += 4
		case 4:
			offset += 16
		case 3:
			offset += 1 + int(buffer[4])
		}
		offset += 2
		if offset > n {
			return nil, fmt.Errorf("malformed answer")
		}
		return append([]byte(nil), buffer[offset:n]...), nil
	}
	return nil, fmt.Errorf("no answer after 5 tries")
}
