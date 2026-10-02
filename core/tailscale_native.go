//go:build with_gvisor && !no_tailscale

package main

import (
	"context"
	"errors"
	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/tailscale/client/local"
	"github.com/metacubex/tailscale/ipn"
	"github.com/metacubex/tailscale/ipn/ipnstate"
	"github.com/metacubex/tailscale/tailcfg"
	"net/netip"
	"net/url"
	"os"
	"slices"
	"sort"
	"strings"
	"time"
)

const tsSupported = true

func tsValidateControl(s string) (string, error) {
	if strings.TrimSpace(s) == "" {
		return ipn.DefaultControlURL, nil
	}
	u, err := url.Parse(strings.TrimSpace(s))
	if err != nil || u.Hostname() == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" {
		return "", errors.New("invalid_control_url")
	}
	if u.Scheme != "https" && !(u.Scheme == "http" && (u.Hostname() == "localhost" || u.Hostname() == "127.0.0.1" || u.Hostname() == "::1")) {
		return "", errors.New("control_requires_https")
	}
	return strings.TrimRight(u.String(), "/"), nil
}

type realTSBackend struct {
	t     *outbound.Tailscale
	lc    *local.Client
	proxy C.Proxy
}

func newRealTSBackend(ctx context.Context, dir, control string, available func() bool) (tsBackend, error) {
	if err := os.MkdirAll(dir, 0700); err != nil {
		return nil, err
	}
	if err := os.Chmod(dir, 0700); err != nil {
		return nil, err
	}
	host, _ := os.Hostname()
	t, err := outbound.NewTailscale(outbound.TailscaleOption{Name: managedTSName, Hostname: "avalon-" + host, StateDir: dir, ControlURL: control, UDP: true})
	if err != nil {
		return nil, err
	}
	lc, err := t.StartManaged(available)
	if err != nil {
		_ = t.Close()
		return nil, err
	}
	return &realTSBackend{t: t, lc: lc, proxy: adapter.NewProxy(t)}, nil
}
func (b *realTSBackend) Login(ctx context.Context, key string) error {
	if key != "" {
		err := b.lc.Start(ctx, ipn.Options{AuthKey: key})
		key = ""
		return err
	}
	return b.lc.StartLoginInteractive(ctx)
}
func (b *realTSBackend) Logout(ctx context.Context) error { return b.lc.Logout(ctx) }
func (b *realTSBackend) Preferences(ctx context.Context, p tsPreferences) error {
	mp := &ipn.MaskedPrefs{RouteAllSet: true, ExitNodeIDSet: true, ExitNodeIPSet: true, ExitNodeAllowLANAccessSet: true, CorpDNSSet: true}
	mp.RouteAll = p.AcceptRoutes
	mp.ExitNodeID = tailcfg.StableNodeID(p.ExitID)
	mp.ExitNodeAllowLANAccess = true
	mp.CorpDNS = true
	_, err := b.lc.EditPrefs(ctx, mp)
	return err
}
func (b *realTSBackend) Refresh(ctx context.Context) (tsBackendStatus, error) {
	s, err := b.lc.Status(ctx)
	if err != nil {
		return tsBackendStatus{}, err
	}
	return normalizeTSStatus(s), nil
}
func (b *realTSBackend) Watch(ctx context.Context, fn func(tsBackendStatus)) error {
	w, err := b.lc.WatchIPNBus(ctx, ipn.NotifyInitialState|ipn.NotifyInitialNetMap|ipn.NotifyInitialHealthState|ipn.NotifyRateLimit)
	if err != nil {
		return err
	}
	defer w.Close()
	for {
		n, err := w.Next()
		if err != nil {
			return err
		}
		c, cancel := context.WithTimeout(ctx, 8*time.Second)
		s, err := b.Refresh(c)
		cancel()
		if err != nil {
			return err
		}
		if n.BrowseToURL != nil && s.Session != "running" {
			s.AuthURL = *n.BrowseToURL
		}
		if n.ErrMessage != nil {
			s.Control = "degraded"
			s.ErrorCode = tsErrorCode(errors.New(*n.ErrMessage))
			s.Health = []string{s.ErrorCode}
		}
		fn(s)
	}
}
func normalizeTSStatus(s *ipnstate.Status) tsBackendStatus {
	v := tsBackendStatus{Session: "starting", AuthURL: s.AuthURL, Control: "healthy", Health: s.Health, Devices: []tsDevice{}}
	switch s.BackendState {
	case "Running":
		v.Session = "running"
	case "NeedsLogin":
		if s.AuthURL != "" {
			v.Session = "authorizing"
		} else {
			v.Session = "needsLogin"
		}
	case "NeedsMachineAuth":
		v.Session = "waitingApproval"
	case "Stopped":
		v.Session = "paused"
	}
	if len(s.Health) > 0 {
		v.Control = "degraded"
	}
	if s.CurrentTailnet != nil && s.CurrentTailnet.MagicDNSEnabled {
		v.Suffix = s.CurrentTailnet.MagicDNSSuffix
	}
	if s.Self != nil {
		d := normalizeTSPeer(s.Self)
		v.Self = &d
		if s.Self.Expired {
			v.Session = "needsLogin"
		}
		if !s.Self.IsTagged() {
			if user, ok := s.User[s.Self.UserID]; ok {
				v.User = user.LoginName
			}
		}
	}
	for _, p := range s.Peer {
		v.Devices = append(v.Devices, normalizeTSPeer(p))
	}
	sort.Slice(v.Devices, func(i, j int) bool { return v.Devices[i].ID < v.Devices[j].ID })
	v.ExitOnline = s.ExitNodeStatus != nil && s.ExitNodeStatus.Online
	if s.ExitNodeStatus != nil {
		v.ExitID = string(s.ExitNodeStatus.ID)
	}
	return v
}
func normalizeTSPeer(p *ipnstate.PeerStatus) tsDevice {
	d := tsDevice{ID: string(p.ID), Name: p.HostName, DNSName: p.DNSName, OS: p.OS, Online: p.Online, Exit: p.ExitNodeOption, KeyExpiry: p.KeyExpiry, IPs: []string{}, Routes: []string{}, Tags: []string{}}
	if !p.LastSeen.IsZero() {
		d.LastSeen = &p.LastSeen
	}
	for _, ip := range p.TailscaleIPs {
		d.IPs = append(d.IPs, ip.String())
	}
	if p.Tags != nil {
		d.Tags = append(d.Tags, p.Tags.AsSlice()...)
	}
	if p.PrimaryRoutes != nil {
		for _, r := range p.PrimaryRoutes.AsSlice() {
			if r.Bits() > 0 {
				d.Routes = append(d.Routes, r.String())
			}
		}
	}

	if p.AllowedIPs != nil {
		for _, r := range p.AllowedIPs.AsSlice() {
			if r.Bits() == 0 {
				continue
			}
			own := false
			for _, ip := range p.TailscaleIPs {
				if r.Addr() == ip && r.Bits() == ip.BitLen() {
					own = true
				}
			}
			if !own && !slices.Contains(d.Routes, r.String()) {
				d.Routes = append(d.Routes, r.String())
			}
		}
	}
	sort.Strings(d.Routes)
	return d
}
func (b *realTSBackend) Ping(ctx context.Context, ip string) (tsProbe, error) {
	a, err := netip.ParseAddr(ip)
	if err != nil {
		return tsProbe{}, err
	}
	r, err := b.lc.Ping(ctx, a, tailcfg.PingDisco)
	if err != nil {
		return tsProbe{}, err
	}
	if r.Err != "" {
		return tsProbe{}, errors.New("ping_failed")
	}
	path := "unknown"
	if r.PeerRelay != "" {
		path = "peerRelay"
	} else if r.Endpoint != "" {
		path = "direct"
	} else if r.DERPRegionID != 0 {
		path = "derp"
	}
	return tsProbe{State: "success", Type: "disco", Latency: r.LatencySeconds * 1000, Path: path, At: time.Now().UTC()}, nil
}
func (b *realTSBackend) ExitHealthy(ctx context.Context) bool {
	// Different endpoints over this exact netstack; disco alone is insufficient.
	for _, host := range []string{"www.gstatic.com", "www.cloudflare.com"} {
		conn, err := b.t.DialContext(ctx, &C.Metadata{NetWork: C.TCP, Host: host, DstPort: 443})
		if err == nil {
			_ = conn.Close()
			return true
		}
	}
	return false
}
func (b *realTSBackend) Proxy() C.Proxy { return b.proxy }
func (b *realTSBackend) Close() error   { return b.t.Close() }
