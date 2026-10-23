package bridge

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"net/netip"
	"net/url"
	"strconv"
	"strings"
	"time"

	M "github.com/sagernet/sing/common/metadata"
	N "github.com/sagernet/sing/common/network"
)

// This is a host-only plan envelope, consumed before sing-box sees the plan.
// It is not a sing-box option or a Cloud wire field. Keeping it in the saved
// plan makes cold host restarts enforce the same provenance as the app.
const publicNetworkEnvelope = "_avalon_public_network"

const publicNetworkVersion = 1

var errBlockedAddress = errors.New("cloud destination is not a public address")
var errGuardUnsupported = errors.New("cloud endpoint options need a supported network guard")

type publicLookup func(context.Context, string) ([]netip.Addr, error)

func systemPublicLookup(ctx context.Context, host string) ([]netip.Addr, error) {
	return net.DefaultResolver.LookupNetIP(ctx, "ip", host)
}

// Keep these ranges aligned with the Dart Fetcher. Unmap before checking:
// ::ffff:127.0.0.1 must never pass as an otherwise global IPv6 destination.
var nonPublicPrefixes = []netip.Prefix{
	netip.MustParsePrefix("0.0.0.0/8"), netip.MustParsePrefix("10.0.0.0/8"),
	netip.MustParsePrefix("100.64.0.0/10"), netip.MustParsePrefix("127.0.0.0/8"),
	netip.MustParsePrefix("169.254.0.0/16"), netip.MustParsePrefix("172.16.0.0/12"),
	netip.MustParsePrefix("192.0.0.0/24"), netip.MustParsePrefix("192.0.2.0/24"),
	netip.MustParsePrefix("192.88.99.0/24"), netip.MustParsePrefix("192.168.0.0/16"),
	netip.MustParsePrefix("198.18.0.0/15"), netip.MustParsePrefix("198.51.100.0/24"),
	netip.MustParsePrefix("203.0.113.0/24"), netip.MustParsePrefix("224.0.0.0/3"),
	netip.MustParsePrefix("2001::/23"), netip.MustParsePrefix("2001:db8::/32"),
	netip.MustParsePrefix("2002::/16"), netip.MustParsePrefix("3fff::/20"),
}

func isPublicAddress(address netip.Addr) bool {
	if !address.IsValid() || address.Zone() != "" {
		return false
	}
	address = address.Unmap()
	if address.Is6() && !netip.MustParsePrefix("2000::/3").Contains(address) {
		return false
	}
	// Azure's platform virtual address is globally numbered but is an
	// infrastructure endpoint, not a remote-authored proxy/resource target.
	if address == netip.MustParseAddr("168.63.129.16") {
		return false
	}
	for _, prefix := range nonPublicPrefixes {
		if prefix.Contains(address) {
			return false
		}
	}
	return true
}

func resolvePublicAddress(ctx context.Context, host string, lookup publicLookup, strategy ...string) (netip.Addr, error) {
	if address, err := netip.ParseAddr(host); err == nil {
		if !isPublicAddress(address) {
			return netip.Addr{}, errBlockedAddress
		}
		return address.Unmap(), nil
	}
	if host == "" || strings.ContainsAny(host, "\x00\r\n%:/\\@[]") {
		return netip.Addr{}, errBlockedAddress
	}
	addresses, err := lookup(ctx, host)
	if err != nil || len(addresses) == 0 {
		// Do not surface DNS errors containing names, URL tokens or proxy
		// credentials in logs; callers still get the real failure category.
		return netip.Addr{}, errors.New("cloud destination DNS lookup failed")
	}
	for _, address := range addresses {
		if !isPublicAddress(address) {
			return netip.Addr{}, errBlockedAddress
		}
	}
	if len(strategy) > 0 {
		switch strategy[0] {
		case "prefer_ipv4", "ipv4_only":
			for _, address := range addresses {
				if address.Unmap().Is4() {
					return address.Unmap(), nil
				}
			}
			if strategy[0] == "ipv4_only" {
				return netip.Addr{}, errors.New("cloud destination has no allowed address family")
			}
		case "prefer_ipv6", "ipv6_only":
			for _, address := range addresses {
				if address.Unmap().Is6() {
					return address, nil
				}
			}
			if strategy[0] == "ipv6_only" {
				return netip.Addr{}, errors.New("cloud destination has no allowed address family")
			}
		}
	}
	return addresses[0].Unmap(), nil
}

func checkPublicURL(u *url.URL) error {
	if u == nil || (u.Scheme != "http" && u.Scheme != "https") ||
		u.Opaque != "" || u.User != nil || u.Fragment != "" || u.Hostname() == "" {
		return errBlockedAddress
	}
	if p := u.Port(); p != "" {
		port, err := strconv.Atoi(p)
		if err != nil || port < 1 || port > 65535 {
			return errBlockedAddress
		}
	}
	if address, err := netip.ParseAddr(u.Hostname()); err == nil && !isPublicAddress(address) {
		return errBlockedAddress
	}
	return nil
}

// Pin the validated DNS answer into the actual request handed to the core.
// The upstream receives an IP, never a hostname it could resolve again.
func publicDialContext(lookup publicLookup, upstream N.Dialer) func(context.Context, string, string) (net.Conn, error) {
	return func(ctx context.Context, network, destination string) (net.Conn, error) {
		host, portText, err := net.SplitHostPort(destination)
		if err != nil {
			return nil, errBlockedAddress
		}
		port, err := strconv.Atoi(portText)
		if err != nil || port < 1 || port > 65535 {
			return nil, errBlockedAddress
		}
		address, err := resolvePublicAddress(ctx, host, lookup)
		if err != nil {
			return nil, err
		}
		return upstream.DialContext(ctx, network, M.SocksaddrFrom(address, uint16(port)))
	}
}

// preparePublicPlan resolves remote-authored endpoints before the engine
// starts, validates every answer, and pins the same address for the entire
// instance. TCP, UDP/QUIC retries and detour hops can then only dial that
// literal. User traffic destinations and trusted local endpoints are not
// rewritten. The original saved plan retains its names for the next start.
func preparePublicPlan(plan []byte, lookup publicLookup) ([]byte, error) {
	var tree map[string]any
	if err := json.Unmarshal(plan, &tree); err != nil {
		return nil, errors.New("malformed plan")
	}
	raw, exists := tree[publicNetworkEnvelope]
	if !exists {
		return plan, nil
	}
	encoded, err := json.Marshal(raw)
	if err != nil {
		return nil, errGuardUnsupported
	}
	var envelope struct {
		Version      int      `json:"version"`
		EndpointTags []string `json:"endpointTags"`
	}
	decoder := json.NewDecoder(strings.NewReader(string(encoded)))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&envelope) != nil || envelope.Version != publicNetworkVersion {
		return nil, errGuardUnsupported
	}
	delete(tree, publicNetworkEnvelope)
	outbounds := make(map[string]map[string]any)
	for _, raw := range list(tree["outbounds"]) {
		outbound, ok := raw.(map[string]any)
		if !ok || text(outbound["tag"]) == "" || outbounds[text(outbound["tag"])] != nil {
			return nil, errGuardUnsupported
		}
		outbounds[text(outbound["tag"])] = outbound
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	visiting, done := make(map[string]bool), make(map[string]bool)
	strategy := ""
	if dns, ok := tree["dns"].(map[string]any); ok {
		strategy = text(dns["strategy"])
	}
	var pin func(string) error
	pin = func(tag string) error {
		if done[tag] {
			return nil
		}
		out := outbounds[tag]
		if out == nil || visiting[tag] {
			return errGuardUnsupported
		}
		visiting[tag] = true
		switch text(out["type"]) {
		case "selector":
			for _, member := range list(out["outbounds"]) {
				if err := pin(text(member)); err != nil {
					return err
				}
			}
		case "direct":
			// A direct detour is safe because its caller receives a pinned IP.
			// Do not permit a local override to redirect that literal elsewhere.
			if !onlyKeys(out, "type", "tag") {
				return errGuardUnsupported
			}
		case "urltest":
			// Automatic probes are a distinct remote-authored destination.
			// Their private upstream callback cannot be guarded by this envelope.
			return errGuardUnsupported
		default:
			if err := pinPublicOutbound(ctx, out, lookup, strategy); err != nil {
				return err
			}
		}
		if detour := text(out["detour"]); detour != "" {
			if err := pin(detour); err != nil {
				return err
			}
		}
		visiting[tag], done[tag] = false, true
		return nil
	}
	for _, tag := range envelope.EndpointTags {
		if err := pin(tag); err != nil {
			return nil, err
		}
	}
	return json.Marshal(tree)
}

func pinPublicOutbound(ctx context.Context, out map[string]any, lookup publicLookup, strategy string) error {
	keys := []string{"type", "tag", "server", "server_port", "detour", "tls", "transport"}
	switch text(out["type"]) {
	case "anytls":
		keys = append(keys, "password", "idle_session_check_interval")
	case "vless":
		keys = append(keys, "uuid", "flow")
	case "vmess":
		keys = append(keys, "uuid", "security", "alter_id")
	case "trojan":
		keys = append(keys, "password")
	case "http", "socks":
		keys = append(keys, "username", "password", "version")
	case "shadowsocks":
		keys = append(keys, "method", "password")
		// SIP003 plugin options can name certificate files and introduce
		// transports not covered by this bounded pinning implementation.
	case "hysteria2":
		keys = append(keys, "password", "up_mbps", "down_mbps", "server_ports", "obfs")
		if obfs, ok := out["obfs"].(map[string]any); ok && !onlyKeys(obfs, "type", "password") {
			return errGuardUnsupported
		}
	case "tuic":
		keys = append(keys, "uuid", "password", "congestion_control", "udp_relay_mode")
	default:
		return errGuardUnsupported
	}
	if !onlyKeys(out, keys...) {
		return errGuardUnsupported
	}
	host := text(out["server"])
	address, err := resolvePublicAddress(ctx, host, lookup, strategy)
	if err != nil {
		return err
	}
	tls, hasTLS := out["tls"].(map[string]any)
	if hasTLS {
		if !onlyKeys(tls, "enabled", "server_name", "insecure", "alpn", "utls", "reality") {
			return errGuardUnsupported
		}
		if utls, ok := tls["utls"].(map[string]any); ok && !onlyKeys(utls, "enabled", "fingerprint") {
			return errGuardUnsupported
		}
		if reality, ok := tls["reality"].(map[string]any); ok && !onlyKeys(reality, "enabled", "public_key", "short_id") {
			return errGuardUnsupported
		}
		if text(tls["server_name"]) == "" {
			tls["server_name"] = host
		}
	}
	if transport, ok := out["transport"].(map[string]any); ok {
		switch text(transport["type"]) {
		case "ws":
			if !onlyKeys(transport, "type", "path", "headers", "max_early_data", "early_data_header_name") {
				return errGuardUnsupported
			}
			headers, ok := transport["headers"].(map[string]any)
			if !ok {
				headers = make(map[string]any)
				transport["headers"] = headers
			}
			if !onlyKeys(headers, "Host") {
				return errGuardUnsupported
			}
			if text(headers["Host"]) == "" {
				headers["Host"] = net.JoinHostPort(host, strconv.Itoa(int(number(out["server_port"]))))
			}
		case "http":
			if !onlyKeys(transport, "type", "path", "host") {
				return errGuardUnsupported
			}
			// HTTP/2's upstream empty-host default is www.example.com; only
			// plain HTTP's implicit Host is the original endpoint hostname.
			if !hasTLS && len(list(transport["host"])) == 0 {
				transport["host"] = []any{host}
			}
		case "grpc":
			if !onlyKeys(transport, "type", "service_name") {
				return errGuardUnsupported
			}
			// Without TLS the gRPC authority is implicit in its dial address
			// and upstream exposes no separate authority option.
			if !hasTLS && host != address.String() {
				return errGuardUnsupported
			}
		default:
			return errGuardUnsupported
		}
	}
	out["server"] = address.String()
	return nil
}

func onlyKeys(tree map[string]any, allowed ...string) bool {
	keys := make(map[string]bool, len(allowed))
	for _, key := range allowed {
		keys[key] = true
	}
	for key := range tree {
		if !keys[key] {
			return false
		}
	}
	return true
}

func text(value any) string    { result, _ := value.(string); return result }
func list(value any) []any     { result, _ := value.([]any); return result }
func number(value any) float64 { result, _ := value.(float64); return result }
