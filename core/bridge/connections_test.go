package bridge

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"strings"
	"testing"
	"time"
)

// TestConnections holds a connection open through the proxy, lists it,
// closes it, and closes everything.
func TestConnections(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	session := mustStart(t, e, port)

	// A server that keeps connections open until told otherwise.
	server, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	go func() {
		for {
			connection, err := server.Accept()
			if err != nil {
				return
			}
			go func() {
				defer connection.Close()
				reader := bufio.NewReader(connection)
				for {
					line, err := reader.ReadString('\n')
					if err != nil {
						return
					}
					_, _ = connection.Write([]byte(line))
				}
			}()
		}
	}()

	open := func() net.Conn {
		t.Helper()
		// An HTTP CONNECT tunnel through the mixed inbound.
		connection, err := net.Dial("tcp", fmt.Sprintf("127.0.0.1:%d", port))
		if err != nil {
			t.Fatal(err)
		}
		target := server.Addr().String()
		fmt.Fprintf(connection, "CONNECT %s HTTP/1.1\r\nHost: %s\r\n\r\n", target, target)
		reader := bufio.NewReader(connection)
		status, err := reader.ReadString('\n')
		if err != nil || !strings.Contains(status, "200") {
			t.Fatalf("CONNECT: %q %v", status, err)
		}
		for line, _ := reader.ReadString('\n'); line != "\r\n" && line != ""; line, _ = reader.ReadString('\n') {
		}
		fmt.Fprintf(connection, "hello\n")
		if echo, _ := reader.ReadString('\n'); echo != "hello\n" {
			t.Fatalf("echo: %q", echo)
		}
		return connection
	}
	list := func() []Connection {
		t.Helper()
		var response connectionsResponse
		if err := call(t, e, "connections", connectionsRequest{SessionID: session}, &response); err != nil {
			t.Fatal(err)
		}
		return response.Connections
	}
	waitFor := func(count int) []Connection {
		t.Helper()
		deadline := time.Now().Add(3 * time.Second)
		for {
			got := list()
			if len(got) == count || time.Now().After(deadline) {
				return got
			}
			time.Sleep(20 * time.Millisecond)
		}
	}

	first, second := open(), open()
	defer first.Close()
	defer second.Close()
	got := waitFor(2)
	if len(got) != 2 {
		t.Fatalf("two connections should be listed: %+v", got)
	}
	c := got[0]
	if c.ID == "" || c.Host != server.Addr().String() || c.Network != "tcp" || c.CreatedAt == 0 {
		t.Fatalf("connection: %+v", c)
	}
	// The plan's final target is the selector, which uses «a».
	if strings.Join(c.Chain, ">") != "proxy>a" || c.Rule != "" {
		t.Fatalf("route: chain %v, rule %q", c.Chain, c.Rule)
	}
	if c.Upload == 0 || c.Download == 0 {
		t.Fatalf("traffic is counted per connection: %+v", c)
	}

	// Closing one leaves the other.
	if err := call(t, e, "closeConnection", closeConnectionRequest{RequestID: "c1", SessionID: session, ID: c.ID}, nil); err != nil {
		t.Fatal(err)
	}
	if got = waitFor(1); len(got) != 1 || got[0].ID == c.ID {
		t.Fatalf("after closing one: %+v", got)
	}
	// Closing one that is already gone is not an error.
	if err := call(t, e, "closeConnection", closeConnectionRequest{SessionID: session, ID: c.ID}, nil); err != nil {
		t.Fatalf("closing a gone connection: %v", err)
	}
	if err := call(t, e, "closeAllConnections", closeConnectionRequest{RequestID: "all", SessionID: session}, nil); err != nil {
		t.Fatal(err)
	}
	if got = waitFor(0); len(got) != 0 {
		t.Fatalf("after closing all: %+v", got)
	}
	// The session goes on.
	if s := snapshot(t, e); s.State != StateRunning || s.SessionID != session {
		t.Fatalf("after closing: %+v", s)
	}
	if err := call(t, e, "connections", connectionsRequest{SessionID: "other"}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("another session: %v", err)
	}
	raw, _ := json.Marshal(connectionsResponse{Connections: []Connection{}})
	if string(raw) != `{"connections":[]}` {
		t.Fatalf("an empty list is a list: %s", raw)
	}
}
