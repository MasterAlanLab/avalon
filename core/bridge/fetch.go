package bridge

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"time"

	M "github.com/sagernet/sing/common/metadata"
)

const (
	fetchDefaultTimeout = 30 * time.Second
	fetchMaxTimeout     = 5 * time.Minute
	fetchDefaultMax     = 1 << 20
)

type fetchRequest struct {
	RequestID string `json:"requestId"`
	SessionID string `json:"sessionId"`
	// The outbound to go through: a group or a node of the running plan.
	OutboundTag string `json:"outboundTag"`
	URL         string `json:"url"`
	MaxBytes    int64  `json:"maxBytes"`
	// Where to write the body; without it the body comes back in the
	// answer (keep those small: the answer crosses processes).
	DestPath  string `json:"destPath,omitempty"`
	TimeoutMs int    `json:"timeoutMs,omitempty"`
	// Cloud resource provenance: the destination is resolved, checked and
	// pinned separately for each connection and every HTTP redirect.
	PublicOnly bool `json:"publicOnly,omitempty"`
}

type fetchResponse struct {
	Status int `json:"status"`
	// Bytes written to DestPath, or the length of Body.
	Size int64  `json:"size"`
	Body string `json:"body,omitempty"`
	Path string `json:"path,omitempty"`
}

// fetch downloads url through an outbound of the running session
// (RUNTIME_HOST §2): rule sets «经代理», and the exit IP.
func (e *Engine) fetch(r fetchRequest) (any, *Error) {
	if err := e.checkSession(r.SessionID); err != nil {
		return nil, err
	}
	instance := e.service.Instance()
	if instance == nil {
		return nil, &Error{Code: CodeSessionMismatch, Message: "no such running session"}
	}
	outbound, found := instance.Box().Outbound().Outbound(r.OutboundTag)
	if !found {
		return nil, &Error{Code: CodePlanInvalid, Message: "outbound not found: " + r.OutboundTag}
	}
	timeout := time.Duration(r.TimeoutMs) * time.Millisecond
	if timeout <= 0 {
		timeout = fetchDefaultTimeout
	} else if timeout > fetchMaxTimeout {
		timeout = fetchMaxTimeout
	}
	limit := r.MaxBytes
	if limit <= 0 {
		limit = fetchDefaultMax
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	if r.PublicOnly {
		address, err := url.Parse(r.URL)
		if err != nil || checkPublicURL(address) != nil {
			return nil, &Error{Code: CodePlanInvalid, Message: errBlockedAddress.Error()}
		}
	}

	dialContext := func(ctx context.Context, network, address string) (net.Conn, error) {
		return outbound.DialContext(ctx, network, M.ParseSocksaddr(address))
	}
	if r.PublicOnly {
		dialContext = publicDialContext(e.lookupPublicAddress(), outbound)
	}
	client := &http.Client{
		Transport: &http.Transport{
			DialContext:         dialContext,
			ForceAttemptHTTP2:   true,
			TLSHandshakeTimeout: timeout,
		},
	}
	if r.PublicOnly {
		client.CheckRedirect = func(request *http.Request, previous []*http.Request) error {
			if len(previous) >= 10 {
				return errors.New("too many redirects")
			}
			return checkPublicURL(request.URL)
		}
	}
	defer client.CloseIdleConnections()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, r.URL, nil)
	if err != nil {
		return nil, &Error{Code: CodePlanInvalid, Message: "malformed address", Detail: err.Error()}
	}
	request.Header.Set("User-Agent", "Avalon/"+e.platform)
	response, err := client.Do(request)
	if err != nil {
		if r.PublicOnly && ctx.Err() == nil {
			// net/http's url.Error includes the whole URL (including tokens).
			// Preserve the safe guard failure, never echo request material.
			if errors.Is(err, errBlockedAddress) {
				return nil, &Error{Code: CodePlanInvalid, Message: errBlockedAddress.Error()}
			}
			return nil, &Error{Code: CodeCoreFailed, Message: "cloud resource download failed"}
		}
		return nil, fetchError(ctx, err)
	}
	defer response.Body.Close()
	if response.ContentLength > limit {
		return nil, &Error{Code: CodeCoreFailed, Message: "too large", Detail: fmt.Sprint(response.ContentLength)}
	}
	reader := io.LimitReader(response.Body, limit+1)
	result := fetchResponse{Status: response.StatusCode}

	if r.DestPath == "" {
		body, err := io.ReadAll(reader)
		if err != nil {
			return nil, fetchError(ctx, err)
		}
		if int64(len(body)) > limit {
			return nil, &Error{Code: CodeCoreFailed, Message: "too large"}
		}
		result.Body, result.Size = string(body), int64(len(body))
		return result, nil
	}
	// Written beside the destination and moved into place whole.
	temp, err := os.CreateTemp(filepath.Dir(r.DestPath), ".fetch-*")
	if err != nil {
		return nil, &Error{Code: CodeCoreFailed, Message: "cannot write the file", Detail: err.Error()}
	}
	defer os.Remove(temp.Name())
	written, err := io.Copy(temp, reader)
	closeErr := temp.Close()
	switch {
	case err != nil:
		return nil, fetchError(ctx, err)
	case closeErr != nil:
		return nil, &Error{Code: CodeCoreFailed, Message: "cannot write the file", Detail: closeErr.Error()}
	case written > limit:
		return nil, &Error{Code: CodeCoreFailed, Message: "too large"}
	}
	if err := os.Rename(temp.Name(), r.DestPath); err != nil {
		return nil, &Error{Code: CodeCoreFailed, Message: "cannot write the file", Detail: err.Error()}
	}
	result.Path, result.Size = r.DestPath, written
	return result, nil
}

func fetchError(ctx context.Context, err error) *Error {
	if errors.Is(err, context.DeadlineExceeded) || ctx.Err() != nil {
		return &Error{Code: CodeTimeout, Message: "the download did not finish in time"}
	}
	return &Error{Code: CodeCoreFailed, Message: err.Error()}
}
