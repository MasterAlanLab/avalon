package bridge

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestFetch(t *testing.T) {
	e := newEngine(t)
	port := freePort(t)
	session := mustStart(t, e, port)
	// The origin sees requests coming through the core.
	var paths []string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		if r.URL.Path == "/missing" {
			http.NotFound(w, r)
			return
		}
		_, _ = w.Write([]byte(strings.Repeat("x", 4096)))
	}))
	defer server.Close()

	// Into a file, through the selector.
	dest := filepath.Join(t.TempDir(), "rule.srs")
	var response fetchResponse
	request := fetchRequest{RequestID: "f1", SessionID: session, OutboundTag: "proxy", URL: server.URL + "/rule.srs", MaxBytes: 1 << 20, DestPath: dest}
	if err := call(t, e, "fetch", request, &response); err != nil {
		t.Fatalf("fetch: %v", err)
	}
	if response.Status != 200 || response.Size != 4096 || response.Path != dest {
		t.Fatalf("response: %+v", response)
	}
	if data, _ := os.ReadFile(dest); len(data) != 4096 {
		t.Fatalf("file: %d bytes", len(data))
	}

	// Small bodies come back in the answer; the status is passed on.
	request = fetchRequest{SessionID: session, OutboundTag: "b", URL: server.URL + "/missing"}
	if err := call(t, e, "fetch", request, &response); err != nil {
		t.Fatal(err)
	}
	if response.Status != 404 || response.Body == "" {
		t.Fatalf("not found: %+v", response)
	}

	// Over the limit: refused, and nothing is left behind.
	big := filepath.Join(t.TempDir(), "big.srs")
	request = fetchRequest{SessionID: session, OutboundTag: "proxy", URL: server.URL + "/rule.srs", MaxBytes: 100, DestPath: big}
	if err := call(t, e, "fetch", request, nil); err == nil || !strings.Contains(err.Message, "too large") {
		t.Fatalf("over the limit: %v", err)
	}
	if _, err := os.Stat(big); !os.IsNotExist(err) {
		t.Fatal("a refused download must leave no file")
	}
	entries, _ := os.ReadDir(filepath.Dir(big))
	if len(entries) != 0 {
		t.Fatalf("temporary files left: %v", entries)
	}

	if err := call(t, e, "fetch", fetchRequest{SessionID: session, OutboundTag: "nowhere", URL: server.URL}, nil); err == nil {
		t.Fatal("an outbound the plan does not have")
	}
	if err := call(t, e, "fetch", fetchRequest{SessionID: "other", OutboundTag: "proxy", URL: server.URL}, nil); err == nil || err.Code != CodeSessionMismatch {
		t.Fatalf("another session: %v", err)
	}
	if len(paths) != 3 {
		t.Fatalf("requests seen: %v", paths)
	}
}
