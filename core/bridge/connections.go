package bridge

import (
	"path/filepath"
	"sort"
	"strings"

	"github.com/gofrs/uuid/v5"
)

type connectionsRequest struct {
	SessionID string `json:"sessionId"`
}

type closeConnectionRequest struct {
	RequestID string `json:"requestId"`
	SessionID string `json:"sessionId"`
	// Empty closes them all.
	ID string `json:"id,omitempty"`
}

// Connection is one active connection (PRODUCT_SPEC §3.8).
type Connection struct {
	ID string `json:"id"`
	// Where it goes: the domain when known, else the address; with port.
	Host    string `json:"host"`
	Network string `json:"network"`
	// The app: Android package, else the program's file name; empty when
	// unknown (find process off).
	Process string `json:"process,omitempty"`
	// The rule's match part as the core writes it; empty for the final
	// target.
	Rule string `json:"rule,omitempty"`
	// Outbound tags from the rule's target through groups to the exit.
	Chain     []string `json:"chain"`
	Upload    int64    `json:"upload"`
	Download  int64    `json:"download"`
	CreatedAt int64    `json:"createdAt"`
}

type connectionsResponse struct {
	Connections []Connection `json:"connections"`
}

func (e *Engine) connections(r connectionsRequest) (any, *Error) {
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	instance := e.service.Instance()
	if instance == nil || instance.TrafficManager() == nil {
		return connectionsResponse{Connections: []Connection{}}, nil
	}
	tracked := instance.TrafficManager().Connections()
	list := make([]Connection, 0, len(tracked))
	for _, metadata := range tracked {
		inbound := metadata.Metadata
		host := inbound.Destination.String()
		if inbound.Domain != "" {
			host = inbound.Domain + ":" + portOf(host)
		}
		var process string
		if owner := inbound.ProcessInfo; owner != nil {
			switch {
			case len(owner.AndroidPackageNames) > 0:
				process = owner.AndroidPackageNames[0]
			case owner.ProcessPath != "":
				process = filepath.Base(owner.ProcessPath)
			}
		}
		var rule string
		if metadata.Rule != nil {
			// «rule_set=geosite-cn => route(direct)»: the match part.
			rule, _, _ = strings.Cut(metadata.Rule.String(), " => ")
		}
		// The core lists the exit first; read from the rule's target.
		chain := make([]string, len(metadata.Chain))
		for i, tag := range metadata.Chain {
			chain[len(chain)-1-i] = tag
		}
		list = append(list, Connection{
			ID:        metadata.ID.String(),
			Host:      host,
			Network:   inbound.Network,
			Process:   process,
			Rule:      rule,
			Chain:     chain,
			Upload:    metadata.Upload.Load(),
			Download:  metadata.Download.Load(),
			CreatedAt: metadata.CreatedAt.UnixMilli(),
		})
	}
	// Newest first.
	sort.Slice(list, func(i, j int) bool { return list[i].CreatedAt > list[j].CreatedAt })
	return connectionsResponse{Connections: list}, nil
}

func (e *Engine) closeConnection(r closeConnectionRequest) (any, *Error) {
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	instance := e.service.Instance()
	if instance == nil || instance.TrafficManager() == nil {
		return nil, nil
	}
	traffic := instance.TrafficManager()
	if r.ID == "" {
		traffic.CloseAllConnections()
		return nil, nil
	}
	id, err := uuid.FromString(r.ID)
	if err != nil {
		return nil, &Error{Code: CodePlanInvalid, Message: "malformed connection id"}
	}
	// Gone already is fine: the user wanted it closed.
	if connection := traffic.Connection(id); connection != nil {
		_ = connection.Close()
	}
	return nil, nil
}

func portOf(address string) string {
	if i := strings.LastIndex(address, ":"); i >= 0 {
		return address[i+1:]
	}
	return ""
}
