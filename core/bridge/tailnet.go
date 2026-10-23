package bridge

import "encoding/json"

// TailnetStatus is a deliberately small projection of the native backend.
// Identity keys, user profiles and credentials never cross the bridge.
type TailnetStatus struct {
	State    string        `json:"state"`
	LoginURL string        `json:"loginUrl,omitempty"`
	Tailnet  string        `json:"tailnet,omitempty"`
	Self     *TailnetPeer  `json:"self,omitempty"`
	Peers    []TailnetPeer `json:"peers"`
}

type TailnetPeer struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	OS          string   `json:"os"`
	IPs         []string `json:"ips"`
	Online      bool     `json:"online"`
	ExitCapable bool     `json:"exitCapable"`
}

// Peer identity and applied exit routes cannot yet be verified on every
// native host. Do not let old settings or a raw plan bypass the UI gate.
func checkTailnetPlan(plan []byte) *Error {
	var config struct {
		Endpoints []struct {
			Type          string `json:"type"`
			ExitNode      string `json:"exit_node"`
			AdvertiseExit bool   `json:"advertise_exit_node"`
		} `json:"endpoints"`
	}
	if json.Unmarshal(plan, &config) != nil {
		return nil
	}
	for _, endpoint := range config.Endpoints {
		if endpoint.Type == "tailscale" && (endpoint.ExitNode != "" || endpoint.AdvertiseExit) {
			return &Error{Code: CodeUnsupported, Message: "Tailscale exit routing has not been verified"}
		}
	}
	return nil
}
