package main

import (
	"encoding/json"
	"errors"
	"github.com/metacubex/mihomo/component/iface/anet"
	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/constant/features"
	"github.com/metacubex/mihomo/hub/executor"
	"github.com/metacubex/mihomo/listener"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/mihomo/tunnel/statistic"
	"go4.org/netipx"
	"gopkg.in/yaml.v3"
	"net"
	"net/netip"
	"os"
	"slices"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

var tsAndroidTun, tsAndroidIPv6, tsAndroidRoutesKnown atomic.Bool
var tsAndroidRoutes atomic.Value
var tsReconcileMu sync.Mutex
var tsReconcileTimer *time.Timer
var lastUsableTSYAML []byte
var tsBaseTun config.RawTun
var managedTS = newTSManager(newRealTSBackend, tsSupported, func(s tsSnapshot) { sendMessage(Message{Type: TailscaleMessage, Data: s}) })

func init() {
	tunnel.RuntimeRouteHook = managedTS.Route
	tunnel.RuntimeRouteNeedsIP = func() bool {
		managedTS.mu.Lock()
		defer managedTS.mu.Unlock()
		return managedTS.state.Supported && managedTS.disk.Registered && (managedTS.disk.Prefs.AutoRoute || managedTS.disk.Prefs.AcceptRoutes || managedTS.disk.Prefs.ExitID != "")
	}
}
func tsLocalPrefixes() []netip.Prefix {
	var out []netip.Prefix
	interfaces, err := anet.Interfaces()
	if err != nil {
		return out
	}
	for _, i := range interfaces {
		if i.Flags&net.FlagUp == 0 || i.Flags&net.FlagLoopback != 0 || strings.HasPrefix(i.Name, "utun") || strings.HasPrefix(i.Name, "tun") || strings.HasPrefix(i.Name, "tailscale") {
			continue
		}
		addrs, _ := anet.InterfaceAddrsByInterface(&i)
		for _, a := range addrs {
			if p, err := netip.ParsePrefix(a.String()); err == nil {
				out = append(out, p.Masked())
			}
		}
	}
	return out
}
func closeTSConnections() {
	statistic.DefaultManager.Range(func(t statistic.Tracker) bool {
		if slices.Contains(t.Chains(), managedTSName) {
			_ = t.Close()
		}
		return true
	})
}
func isPublicTSAddress(a netip.Addr) bool {
	if !a.IsValid() {
		return false
	}
	a = a.Unmap()
	if !a.IsGlobalUnicast() || a.IsPrivate() || a.IsLoopback() || a.IsLinkLocalUnicast() {
		return false
	}
	for _, s := range []string{"0.0.0.0/8", "100.64.0.0/10", "192.0.0.0/24", "192.0.2.0/24", "192.88.99.0/24", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "240.0.0.0/4", "2001:db8::/32", "2001::/23", "64:ff9b:1::/48", "64:ff9b::/96", "100::/64", "2002::/16", "3fff::/20", "5f00::/16", "fec0::/10"} {
		p := netip.MustParsePrefix(s)
		if p.Contains(a) {
			return false
		}
	}
	return true
}
func originalReject(p C.Proxy, md *C.Metadata) bool {
	seen := map[string]bool{}
	for i := 0; p != nil && i < 32; i++ {
		if p.Type() == C.Reject || p.Type() == C.RejectDrop {
			return true
		}
		if seen[p.Name()] {
			return false
		}
		seen[p.Name()] = true
		p = p.Unwrap(md, false)
	}
	return false
}
func (m *tsManager) Route(md *C.Metadata, original C.Proxy, rule C.Rule) (C.Proxy, error) {
	if original == nil {
		return original, nil
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	s := m.state
	p := m.disk.Prefs
	if !s.Supported || !m.disk.Registered && s.Session != "running" {
		return original, nil
	}
	if originalReject(original, md) {
		return original, nil
	}
	host := strings.TrimSuffix(strings.ToLower(md.Host), ".")
	tailnet := false
	if p.AutoRoute {
		if s.Suffix != "" && (host == strings.ToLower(s.Suffix) || strings.HasSuffix(host, "."+strings.ToLower(s.Suffix))) {
			tailnet = true
		}
		for _, prefix := range s.CapturePrefixes {
			if r, err := netip.ParsePrefix(prefix); err == nil && r.Contains(md.DstIP) {
				tailnet = true
				break
			}
		}
		for _, d := range s.Devices {
			if host != "" && host == strings.TrimSuffix(strings.ToLower(d.DNSName), ".") {
				tailnet = true
			}
		}
	}
	var best *tsRoute
	for i := range s.Routes {
		r := &s.Routes[i]
		prefix, err := netip.ParsePrefix(r.Prefix)
		if err == nil && prefix.Contains(md.DstIP) {
			if best == nil {
				best = r
			} else {
				prev, _ := netip.ParsePrefix(best.Prefix)
				if prefix.Bits() > prev.Bits() {
					best = r
				}
			}
		}
	}
	if best != nil {
		if best.Conflict && best.Choice != "remote" {
			return original, nil
		}
		if best.Accepted {
			tailnet = true
		}
	}
	if tailnet {
		if m.backend == nil || s.Session != "running" || m.disk.Paused {
			return nil, errors.New("tailnet_session_unavailable")
		}
		return m.backend.Proxy(), nil
	}
	if !md.DstIP.IsValid() && md.Host != "" && p.ExitID != "" && (p.ExitScope == "all" || slices.Contains(p.Bindings[s.ProfileID], original.Name())) {
		// Unresolved destinations are not proof of public/LAN classification.
		// Do not silently bypass an enabled exit when the original proxy might
		// resolve remotely; explicit unavailable-exit fallback remains original.
		if (!m.exitHealthy || !m.exitOnline) && p.FailurePolicy == "fallback" {
			return original, nil
		}
		return nil, errors.New("tailscale_destination_unresolved")
	}
	if !isPublicTSAddress(md.DstIP) || p.ExitID == "" {
		return original, nil
	}
	selected := p.ExitScope == "all" || slices.Contains(p.Bindings[s.ProfileID], original.Name())
	if !selected {
		return original, nil
	}
	if m.backend != nil && s.Session == "running" && m.exitHealthy && m.exitOnline {
		return &tsExitProxy{Proxy: m.backend.Proxy(), target: original.Name()}, nil
	}
	if p.FailurePolicy == "fallback" {
		return original, nil
	}
	return nil, errors.New("tailscale_exit_unavailable")
}
func (m *tsManager) ConfigStatus(profile int64, running, tun, ipv6 bool, groups []string, err error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.state.ProfileID = strconv.FormatInt(profile, 10)
	m.state.Service = running
	m.state.IPv6 = ipv6
	previousCapture := m.state.Capture
	m.state.Capture = "proxy"
	if tun {
		m.state.Capture = "tun"
	}
	if tun && previousCapture != "tun" && features.Android && m.disk.Registered && !m.disk.Paused {
		go func() { _, _ = m.Begin("resume", "", "") }()
	}
	m.state.Groups = groups
	m.cancelProbesLocked()
	m.state.Revision++
	if err != nil {
		m.state.Error = "config_apply_failed"
	} else if m.state.Error == "config_apply_failed" {
		m.state.Error = ""
	}
	m.publishLocked()
}
func tsReportConfig(profile int64, err error) {
	groups := []string{}
	for name, p := range tunnel.AllProxies() {
		switch p.Type() {
		case C.Selector, C.URLTest, C.Fallback, C.LoadBalance:
			if name != "GLOBAL" {
				groups = append(groups, name)
			}
		}
	}
	tun := listener.GetTunConf()
	active, ipv6 := tun.Enable, len(tun.Inet6Address) > 0
	if features.Android {
		active = tsAndroidTun.Load()
		ipv6 = tsAndroidIPv6.Load()
	}
	managedTS.mu.Lock()
	managedTS.capturedPrefixes = tun.RouteAddress
	managedTS.captureExclusions = tun.RouteExcludeAddress
	managedTS.captureKnown = true
	if features.Android {
		managedTS.captureKnown = tsAndroidRoutesKnown.Load()
		managedTS.capturedPrefixes = nil
		managedTS.captureExclusions = nil
		if value := tsAndroidRoutes.Load(); value != nil {
			for _, text := range value.([]string) {
				if p, e := netip.ParsePrefix(text); e == nil {
					managedTS.capturedPrefixes = append(managedTS.capturedPrefixes, p)
				}
			}
		}
	}
	managedTS.mu.Unlock()
	managedTS.ConfigStatus(profile, isRunning, active, ipv6, groups, err)
}
func tsParseConfig(path string) (*config.Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var raw map[string]any
	if err = yaml.Unmarshal(data, &raw); err != nil {
		return nil, err
	}
	if raw == nil {
		return nil, errors.New("empty config")
	}
	// This exact application namespace is reserved; rejecting a collision is
	// preferable to overwriting a user's resolver or taking ownership of it.
	for _, section := range []string{"proxies", "proxy-groups"} {
		entries, _ := raw[section].([]any)
		for _, entry := range entries {
			node, _ := entry.(map[string]any)
			if name, _ := node["name"].(string); name == managedTSName || strings.HasPrefix(name, tsExitMarker) {
				return nil, errors.New("reserved tailscale runtime name")
			}
		}
	}
	tsOverlayConfig(raw, managedTS.Snapshot())
	bytes, err := yaml.Marshal(raw)
	if err != nil {
		return nil, err
	}
	rc, err := config.UnmarshalRawConfig(bytes)
	if err != nil {
		return nil, err
	}
	return config.ParseRawConfig(rc)
}
func tsOverlayConfig(raw map[string]any, s tsSnapshot) {
	if !s.Supported || s.Session == "loggedOut" || raw["mode"] != nil && raw["mode"] != "rule" {
		return
	}
	if s.Prefs.AutoRoute && s.Suffix != "" {
		dns, _ := raw["dns"].(map[string]any)
		if dns == nil {
			dns = map[string]any{}
			raw["dns"] = dns
		}
		policy, _ := dns["nameserver-policy"].(map[string]any)
		if policy == nil {
			policy = map[string]any{}
			dns["nameserver-policy"] = policy
		}
		policy["+."+s.Suffix] = []string{"ts://" + managedTSName}
		for _, d := range s.Devices {
			name := strings.TrimSuffix(d.DNSName, ".")
			if name != "" {
				policy[name] = []string{"ts://" + managedTSName}
				short := strings.TrimSuffix(name, "."+s.Suffix)
				if short != name && !strings.Contains(short, ".") {
					policy[short] = []string{"ts://" + managedTSName}
				}
			}
		}
	}
	tun, _ := raw["tun"].(map[string]any)
	if tun != nil {
		tsCaptureExceptions(tun, s, raw["ipv6"] == true)
		routes, _ := tun["route-address"].([]any)
		if len(routes) > 0 {
			for _, p := range s.CapturePrefixes {
				a, err := netip.ParsePrefix(p)
				if err == nil && (!a.Addr().Is6() || raw["ipv6"] == true) {
					exists := false
					for _, r := range routes {
						if r == p {
							exists = true
						}
					}
					if !exists {
						routes = append(routes, p)
					}
				}
			}
			tun["route-address"] = routes
		}
	}
}
func requestTSReconcile() {
	tsReconcileMu.Lock()
	defer tsReconcileMu.Unlock()
	if tsReconcileTimer != nil {
		tsReconcileTimer.Stop()
	}
	tsReconcileTimer = time.AfterFunc(500*time.Millisecond, func() {
		if tsCurrentProfile() != 0 && isInit.Load() {
			_ = tsReloadConfig()
		}
	})
}
func tsCaptureExceptions(tun map[string]any, s tsSnapshot, ipv6 bool) {
	list, _ := tun["route-exclude-address"].([]any)
	if len(list) == 0 {
		return
	}
	var builder netipx.IPSetBuilder
	for _, v := range list {
		if text, ok := v.(string); ok {
			if p, err := netip.ParsePrefix(text); err == nil {
				builder.AddPrefix(p)
			}
		}
	}
	for _, v := range s.CapturePrefixes {
		if p, err := netip.ParsePrefix(v); err == nil && (!p.Addr().Is6() || ipv6) {
			builder.RemovePrefix(p)
		}
	}
	if set, err := builder.IPSet(); err == nil {
		values := []string{}
		for _, p := range set.Prefixes() {
			values = append(values, p.String())
		}
		tun["route-exclude-address"] = values
	}
}

func tsReloadConfig() error {
	runLock.Lock()
	defer runLock.Unlock()
	if currentConfig == nil || len(lastUsableTSYAML) == 0 {
		return nil
	}
	err := tsApplyNetworkOverlayLocked()
	tsReportConfig(tsCurrentProfile(), err)
	return err
}
func tsApplyNetworkOverlayLocked() error {
	if currentConfig == nil || len(lastUsableTSYAML) == 0 {
		return nil
	}
	var raw map[string]any
	if err := yaml.Unmarshal(lastUsableTSYAML, &raw); err != nil {
		return err
	}
	general := currentConfig.General
	raw["mode"] = general.Mode.String()
	raw["ipv6"] = general.IPv6
	tunBytes, _ := json.Marshal(tsBaseTun)
	var tun map[string]any
	_ = json.Unmarshal(tunBytes, &tun)
	raw["tun"] = tun
	tsOverlayConfig(raw, managedTS.Snapshot())
	bytes, err := yaml.Marshal(raw)
	if err != nil {
		return err
	}
	rc, err := config.UnmarshalRawConfig(bytes)
	if err != nil {
		return err
	}
	dns, nextTun, err := config.ParseRuntimeNetwork(rc, tunnel.RuleProviders(), *general)
	if err != nil {
		return err
	}
	previousTun := general.Tun
	if isRunning && !features.Android && !equalTunConfig(previousTun, nextTun) {
		if err = updateTunListener(nextTun); err != nil {
			_ = updateTunListener(previousTun)
			return err
		}
	}
	executor.ApplyRuntimeDNS(dns, general.IPv6)
	currentConfig.DNS = dns
	general.Tun = nextTun
	return nil
}

func tsCurrentProfile() int64 {
	managedTS.mu.Lock()
	profile := managedTS.state.ProfileID
	managedTS.mu.Unlock()
	id, err := strconv.ParseInt(profile, 10, 64)
	if err != nil {
		return 0
	}
	return id
}
func tsCurrentSelections() map[string]string {
	selected := map[string]string{}
	for name, p := range tunnel.AllProxies() {
		if child := p.Unwrap(&C.Metadata{}, false); child != nil {
			selected[name] = child.Name()
		}
	}
	return selected
}
