//go:build with_gvisor && with_tailscale

package bridge

import (
	"context"
	"net/url"
	"sort"
	"time"

	C "github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/protocol/tailscale"
	"github.com/sagernet/tailscale/ipn/ipnstate"
)

func (e *Engine) tailnetEndpoint() (*tailscale.Endpoint, *Error) {
	instance := e.service.Instance()
	if instance != nil {
		for _, endpoint := range instance.Box().Endpoint().Endpoints() {
			if endpoint.Type() == C.TypeTailscale {
				if real, ok := endpoint.(*tailscale.Endpoint); ok {
					return real, nil
				}
			}
		}
	}
	return nil, &Error{Code: CodeSessionMismatch, Message: "Tailscale is not enabled"}
}

func (e *Engine) tailnetStatus() (any, *Error) {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	endpoint, failure := e.tailnetEndpoint()
	if failure != nil {
		return TailnetStatus{State: "disabled", Peers: []TailnetPeer{}}, nil
	}
	return projectTailnet(endpoint.Server().ExportLocalBackend().Status()), nil
}

func (e *Engine) tailnetAccount(login bool) (any, *Error) {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	endpoint, failure := e.tailnetEndpoint()
	if failure != nil {
		return nil, failure
	}
	ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
	defer cancel()
	var err error
	if login {
		err = endpoint.Server().ExportLocalBackend().StartLoginInteractive(ctx)
	} else {
		err = endpoint.Logout(ctx)
	}
	if err != nil {
		// Backend errors can include auth URLs. Return a stable non-secret
		// failure; the state query remains available for recovery.
		return nil, &Error{Code: CodeCoreFailed, Message: "Tailscale account operation failed"}
	}
	return projectTailnet(endpoint.Server().ExportLocalBackend().Status()), nil
}

func projectTailnet(status *ipnstate.Status) TailnetStatus {
	result := TailnetStatus{State: status.BackendState, Peers: []TailnetPeer{}}
	if status.CurrentTailnet != nil {
		result.Tailnet = status.CurrentTailnet.Name
	}
	if status.Self != nil {
		self := projectTailnetPeer(status.Self)
		result.Self = &self
	}
	for _, peer := range status.Peer {
		result.Peers = append(result.Peers, projectTailnetPeer(peer))
	}
	sort.Slice(result.Peers, func(i, j int) bool {
		if result.Peers[i].Online != result.Peers[j].Online {
			return result.Peers[i].Online
		}
		if result.Peers[i].Name != result.Peers[j].Name {
			return result.Peers[i].Name < result.Peers[j].Name
		}
		return result.Peers[i].ID < result.Peers[j].ID
	})
	// Only the built-in HTTPS control service may supply the browser
	// authorization URL; reject userinfo and fragments at this boundary.
	if uri, err := url.Parse(status.AuthURL); err == nil && uri.Scheme == "https" && uri.Hostname() == "login.tailscale.com" && uri.User == nil && uri.Fragment == "" && (uri.Port() == "" || uri.Port() == "443") {
		result.LoginURL = status.AuthURL
	}
	return result
}

func projectTailnetPeer(peer *ipnstate.PeerStatus) TailnetPeer {
	result := TailnetPeer{ID: string(peer.ID), Name: peer.HostName, OS: peer.OS, IPs: []string{}, Online: peer.Online && !peer.Expired, ExitCapable: peer.ExitNodeOption}
	for _, address := range peer.TailscaleIPs {
		result.IPs = append(result.IPs, address.String())
	}
	return result
}
