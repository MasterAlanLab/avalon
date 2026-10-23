package bridge

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

// A failed rule-set download can wrap a certificate error from the proxy's
// own TLS connection. Exercise both disconnected tests and startup downloads
// through a real AnyTLS server whose certificate deliberately has no SANs.
func TestAnyTLSInsecurePreservesLegacyCertificateConnections(t *testing.T) {
	const password = "avalon-anytls-test-password"
	const serverName = "legacy.avalon.test"
	certificate, key := legacyAnyTLSCertificate(t, serverName)
	port := freePort(t)
	server := newEngine(t)
	serverPlan := testAnyTLSPlan(t, map[string]any{
		"inbounds": []any{map[string]any{
			"type": "anytls", "tag": "anytls-in", "listen": "127.0.0.1", "listen_port": port,
			"users": []any{map[string]any{"password": password}},
			"tls":   map[string]any{"enabled": true, "certificate": []string{certificate}, "key": []string{key}},
		}},
		"outbounds": []any{map[string]any{"type": "direct", "tag": "direct"}},
		"route":     map[string]any{"final": "direct"},
	})
	if err := call(t, server, "start", map[string]any{"plan": serverPlan, "planHash": "anytls-server"}, nil); err != nil {
		t.Fatalf("start local AnyTLS server: %v", err)
	}

	var probes, rules, pages atomic.Int32
	origin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/probe":
			probes.Add(1)
			w.WriteHeader(http.StatusNoContent)
		case "/geoip-cn.json":
			rules.Add(1)
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"version":1,"rules":[]}`))
		case "/page":
			pages.Add(1)
			_, _ = w.Write([]byte("through AnyTLS"))
		default:
			http.NotFound(w, r)
		}
	}))
	defer origin.Close()

	for _, fingerprint := range []string{"", "chrome"} {
		for _, insecure := range []bool{false, true} {
			name := "standard"
			if fingerprint != "" {
				name = "utls"
			}
			if insecure {
				name += "/insecure"
			} else {
				name += "/verify"
			}
			t.Run(name, func(t *testing.T) {
				beforeProbes, beforeRules, beforePages := probes.Load(), rules.Load(), pages.Load()
				// Trust this test certificate so verification fails specifically on
				// its missing SAN, rather than on its self-signed issuer.
				tls := map[string]any{"enabled": true, "server_name": serverName, "insecure": insecure, "certificate": []string{certificate}}
				if fingerprint != "" {
					tls["utls"] = map[string]any{"enabled": true, "fingerprint": fingerprint}
				}
				plan := testAnyTLSPlan(t, map[string]any{
					"outbounds": []any{
						map[string]any{"type": "selector", "tag": "proxy", "outbounds": []string{"node"}, "default": "node"},
						map[string]any{"type": "anytls", "tag": "node", "server": "127.0.0.1", "server_port": port, "password": password, "tls": tls},
						map[string]any{"type": "direct", "tag": "direct"},
					},
					"route": map[string]any{
						"final": "proxy",
						"rules": []any{map[string]any{"rule_set": "geoip-cn", "outbound": "direct"}},
						"rule_set": []any{map[string]any{
							"type": "remote", "tag": "geoip-cn", "format": "source",
							"url": origin.URL + "/geoip-cn.json", "download_detour": "proxy",
						}},
					},
				})
				client := newEngine(t)
				var probe urlTestResponse
				if err := call(t, client, "urlTest", map[string]any{
					"plan": plan, "tags": []string{"node"}, "url": origin.URL + "/probe", "timeoutMs": 2000,
				}, &probe); err != nil {
					t.Fatalf("disconnected AnyTLS test: %v", err)
				}
				result := probe.Results["node"]
				if insecure {
					if result.Error != "" || probes.Load() <= beforeProbes {
						t.Fatalf("insecure node should reach the HTTP origin: %+v", result)
					}
				} else {
					assertLegacyAnyTLSFailure(t, result.Error)
					if probes.Load() != beforeProbes {
						t.Fatal("certificate rejection must happen before reaching the HTTP origin")
					}
				}
				if rules.Load() != beforeRules {
					t.Fatal("a disconnected test must not download rule sets")
				}

				var session sessionResult
				failure := call(t, client, "start", map[string]any{"plan": plan, "planHash": "anytls-client"}, &session)
				if !insecure {
					if failure == nil {
						t.Fatal("rule-set startup must reject the proxy's legacy certificate")
					}
					assertLegacyAnyTLSFailure(t, failure.Message)
					if rules.Load() != beforeRules || snapshot(t, client).State == StateRunning {
						t.Fatal("a rejected proxy must neither reach the rule origin nor start a session")
					}
					return
				}
				if failure != nil {
					t.Fatalf("download rule set through the insecure AnyTLS node: %v", failure)
				}
				if rules.Load() != beforeRules+1 || snapshot(t, client).State != StateRunning {
					t.Fatal("startup must download the rule set through AnyTLS and accept the session")
				}
				var fetched fetchResponse
				if err := call(t, client, "fetch", fetchRequest{SessionID: session.SessionID, OutboundTag: "proxy", URL: origin.URL + "/page"}, &fetched); err != nil {
					t.Fatalf("fetch through the running AnyTLS session: %v", err)
				}
				if fetched.Status != http.StatusOK || fetched.Body != "through AnyTLS" || pages.Load() != beforePages+1 {
					t.Fatalf("unexpected AnyTLS origin response: %+v", fetched)
				}
			})
		}
	}
}

func testAnyTLSPlan(t *testing.T, value map[string]any) json.RawMessage {
	// Marshal, rather than interpolate, the ephemeral PEM strings into plans.
	t.Helper()
	value["log"] = map[string]any{"disabled": true}
	plan, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	return plan
}

func assertLegacyAnyTLSFailure(t *testing.T, message string) {
	t.Helper()
	if !strings.Contains(message, "failed to create session") || !strings.Contains(message, "certificate relies on legacy Common Name field") {
		t.Fatalf("expected the AnyTLS server's legacy certificate error, got: %s", message)
	}
}

func legacyAnyTLSCertificate(t *testing.T, commonName string) (string, string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	certificate := &x509.Certificate{
		SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: commonName},
		NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour),
		KeyUsage: x509.KeyUsageDigitalSignature, ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	}
	der, err := x509.CreateCertificate(rand.Reader, certificate, certificate, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	privateKey, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	return string(pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der})),
		string(pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: privateKey}))
}
