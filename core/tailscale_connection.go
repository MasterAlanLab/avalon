package main

import (
	"context"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel/statistic"
	"net/netip"
	"slices"
	"strings"
)

const tsExitMarker = "__avalon_ts_exit/"

type tsExitProxy struct {
	C.Proxy
	target string
}

func (p *tsExitProxy) Name() string { return tsExitMarker + p.target }
func (p *tsExitProxy) Close() error { return nil } // wrapper never owns tsnet
func (p *tsExitProxy) DialContext(ctx context.Context, md *C.Metadata) (C.Conn, error) {
	c, err := p.Proxy.DialContext(ctx, md)
	if err == nil {
		c.AppendToChains(p)
	}
	return c, err
}
func (p *tsExitProxy) ListenPacketContext(ctx context.Context, md *C.Metadata) (C.PacketConn, error) {
	c, err := p.Proxy.ListenPacketContext(ctx, md)
	if err == nil {
		c.AppendToChains(p)
	}
	return c, err
}
func closeTSExitConnections() {
	statistic.DefaultManager.Range(func(t statistic.Tracker) bool {
		for _, c := range t.Chains() {
			if strings.HasPrefix(c, tsExitMarker) {
				_ = t.Close()
				break
			}
		}
		return true
	})
}
func closeTSChangedConnections(previous, next tsSnapshot) {
	statistic.DefaultManager.Range(func(t statistic.Tracker) bool {
		md := t.Info().Metadata
		if md == nil {
			return true
		}
		chain := t.Chains()
		target := ""
		if len(chain) > 0 {
			target = chain[len(chain)-1]
		}
		target = strings.TrimPrefix(target, tsExitMarker)
		oldCovered := previous.Prefs.ExitID != "" && (previous.Prefs.ExitScope == "all" || slices.Contains(previous.Prefs.Bindings[previous.ProfileID], target))
		newCovered := next.Prefs.ExitID != "" && (next.Prefs.ExitScope == "all" || slices.Contains(next.Prefs.Bindings[next.ProfileID], target))
		exitChanged := oldCovered != newCovered || oldCovered && newCovered && (previous.Prefs.ExitID != next.Prefs.ExitID || previous.Prefs.FailurePolicy != next.Prefs.FailurePolicy)
		if isPublicTSAddress(md.DstIP) && exitChanged {
			_ = t.Close()
			return true
		}
		if slices.Contains(chain, managedTSName) {
			for _, oldRoute := range previous.Routes {
				for _, newRoute := range next.Routes {
					prefix, err := netip.ParsePrefix(oldRoute.Prefix)
					if err == nil && oldRoute.Prefix == newRoute.Prefix && prefix.Contains(md.DstIP) && (oldRoute.Accepted != newRoute.Accepted || oldRoute.Choice != newRoute.Choice) {
						_ = t.Close()
						return true
					}
				}
			}
		}
		if previous.Prefs.AutoRoute != next.Prefs.AutoRoute || previous.Prefs.AcceptRoutes != next.Prefs.AcceptRoutes {
			if slices.Contains(chain, managedTSName) {
				_ = t.Close()
			}
		}
		return true
	})
}
