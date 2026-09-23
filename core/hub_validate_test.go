package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeConfig(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "config.yaml")
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatalf("write config: %v", err)
	}
	return path
}

func TestHandleValidateConfigAcceptsChainProxies(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: FIRST
    type: socks5
    server: 127.0.0.1
    port: 1080
  - name: SECOND
    type: socks5
    server: 127.0.0.1
    port: 1081
    dialer-proxy: FIRST
proxy-groups:
  - name: CHAIN
    type: select
    proxies:
      - SECOND
rules:
  - MATCH,CHAIN
`)
	if message := handleValidateConfig(path); message != "" {
		t.Fatalf("expected a valid config, got %q", message)
	}
}

func TestHandleValidateConfigAcceptsGlobalSelectorPointingAtProxyGroup(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: EXIT
    type: socks5
    server: 127.0.0.1
    port: 1080
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - EXIT
  - name: GLOBAL
    type: select
    proxies:
      - PROXY
rules:
  - MATCH,PROXY
`)
	if message := handleValidateConfig(path); message != "" {
		t.Fatalf("expected explicit GLOBAL selector to parse, got %q", message)
	}
}

func TestHandleValidateConfigRejectsInvalidProxy(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: BROKEN
    type: socks5
`)
	message := handleValidateConfig(path)
	if message == "" {
		t.Fatal("expected an invalid proxy to be rejected")
	}
	if !strings.Contains(message, "proxy 0") {
		t.Fatalf("expected the failing proxy index, got %q", message)
	}
}

func TestHandleValidateConfigRejectsUnknownProxyType(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: BROKEN
    type: not-a-protocol
    server: 127.0.0.1
    port: 1080
`)
	if message := handleValidateConfig(path); message == "" {
		t.Fatal("expected an unsupported proxy type to be rejected")
	}
}

func TestHandleValidateConfigRejectsDuplicateNames(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: NODE
    type: socks5
    server: 127.0.0.1
    port: 1080
  - name: NODE
    type: socks5
    server: 127.0.0.1
    port: 1081
`)
	message := handleValidateConfig(path)
	if !strings.Contains(message, "duplicate name") {
		t.Fatalf("expected a duplicate name error, got %q", message)
	}
}

func TestHandleValidateConfigRejectsGroupReusingProxyName(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: NODE
    type: socks5
    server: 127.0.0.1
    port: 1080
proxy-groups:
  - name: NODE
    type: select
    proxies:
      - NODE
`)
	message := handleValidateConfig(path)
	if !strings.Contains(message, "duplicate name") {
		t.Fatalf("expected a duplicate group name error, got %q", message)
	}
}

// Pins the SOCKS naming contract the Dart codec depends on: mihomo registers
// `socks5` only, so emitting a bare `socks` type breaks config apply at
// runtime even though assembly-level tests would not notice.
func TestHandleValidateConfigRejectsBareSocksType(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: NODE
    type: socks
    server: 127.0.0.1
    port: 1080
rules:
  - MATCH,DIRECT
`)
	message := handleValidateConfig(path)
	if !strings.Contains(message, "unsupport proxy type") {
		t.Fatalf("expected a bare socks type to be rejected, got %q", message)
	}
}

func TestHandleValidateConfigAcceptsSocks5WithVersion(t *testing.T) {
	path := writeConfig(t, `
proxies:
  - name: NODE
    type: socks5
    server: 127.0.0.1
    port: 1080
    version: 4
    username: u
    password: p
rules:
  - MATCH,DIRECT
`)
	if message := handleValidateConfig(path); message != "" {
		t.Fatalf("expected socks5 with a SOCKS4 version marker to be valid, got %q", message)
	}
}

func TestHandleValidateConfigRejectsMissingFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "missing.yaml")
	if message := handleValidateConfig(path); message == "" {
		t.Fatal("expected a missing config file to be rejected")
	}
}

func TestHandleUpdateConfigReportsMissingConfig(t *testing.T) {
	previous := currentConfig
	currentConfig = nil
	defer func() { currentConfig = previous }()

	if message := handleUpdateConfig(&UpdateParams{}); message != "config is not loaded" {
		t.Fatalf("expected update error to reach the method boundary, got %q", message)
	}
}
