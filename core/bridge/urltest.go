package bridge

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"time"

	"github.com/sagernet/sing-box/common/urltest"
	"github.com/sagernet/sing-box/daemon"
)

const (
	urlTestParallel       = 8 // CONFIG_PIPELINE §9
	urlTestDefaultTimeout = 5 * time.Second
	urlTestMaxTimeout     = 30 * time.Second
)

type urlTestRequest struct {
	RequestID string `json:"requestId"`
	// The running session to test in. Without it the plan below is started
	// as a probe: its outbounds only, nothing listening, no tunnel.
	SessionID string          `json:"sessionId,omitempty"`
	Plan      json.RawMessage `json:"plan,omitempty"`
	PlanPath  string          `json:"planPath,omitempty"`
	Tags      []string        `json:"tags"`
	URL       string          `json:"url"`
	TimeoutMs int             `json:"timeoutMs"`
}

// URLTestResult is one outbound's answer: how long it took, or why not.
type URLTestResult struct {
	DelayMs int `json:"delayMs,omitempty"`
	// "timeout", or what the core said.
	Error string `json:"error,omitempty"`
}

type urlTestResponse struct {
	Results map[string]URLTestResult `json:"results"`
}

func (e *Engine) urlTest(r urlTestRequest) (any, *Error) {
	timeout := time.Duration(r.TimeoutMs) * time.Millisecond
	if timeout <= 0 {
		timeout = urlTestDefaultTimeout
	} else if timeout > urlTestMaxTimeout {
		timeout = urlTestMaxTimeout
	}
	if r.SessionID != "" {
		if err := e.checkSession(r.SessionID); err != nil {
			return nil, err
		}
		instance := e.service.Instance()
		if instance == nil {
			return nil, &Error{Code: CodeSessionMismatch, Message: "no such running session"}
		}
		return testOutbounds(instance, r.Tags, r.URL, timeout), nil
	}

	// Nothing runs: start the plan's outbounds alone, measure, stop. No
	// session exists meanwhile, and a start waits for the probe to end.
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	if e.currentState() == StateRunning {
		return nil, &Error{Code: CodeSessionMismatch, Message: "a session is running: test in it"}
	}
	request := startRequest{Plan: r.Plan, PlanPath: r.PlanPath}
	if err := loadPlan(&request); err != nil {
		return nil, err
	}
	if err := checkTailnetPlan(request.Plan); err != nil {
		return nil, err
	}
	probe, err := probePlan(request.Plan)
	if err != nil {
		return nil, &Error{Code: CodePlanInvalid, Message: "malformed plan", Detail: err.Error()}
	}
	probe, err = preparePublicPlan(probe, e.lookupPublicAddress())
	if err != nil {
		return nil, &Error{Code: CodePlanInvalid, Message: err.Error()}
	}
	if err := e.service.StartOrReloadService(context.Background(), string(probe), nil); err != nil {
		return nil, classify(err)
	}
	defer func() { _ = e.service.CloseService() }()
	instance := e.service.Instance()
	if instance == nil {
		return nil, &Error{Code: CodeCoreFailed, Message: "the probe did not start"}
	}
	return testOutbounds(instance, r.Tags, r.URL, timeout), nil
}

// probePlan keeps what is needed to dial through a plan's outbounds and
// drops everything that would take over the device or wait on the
// network: inbounds (the tunnel, the ports), the controller, and the rules
// with their rule sets (which the core would download before starting).
func probePlan(plan []byte) ([]byte, error) {
	var tree map[string]any
	if err := json.Unmarshal(plan, &tree); err != nil {
		return nil, err
	}
	delete(tree, "inbounds")
	delete(tree, "experimental")
	if route, isMap := tree["route"].(map[string]any); isMap {
		delete(route, "rules")
		delete(route, "rule_set")
	}
	if dns, isMap := tree["dns"].(map[string]any); isMap {
		delete(dns, "rules")
	}
	return json.Marshal(tree)
}

func testOutbounds(instance *daemon.Instance, tags []string, url string, timeout time.Duration) urlTestResponse {
	results := make(map[string]URLTestResult, len(tags))
	var access sync.Mutex
	var group sync.WaitGroup
	slots := make(chan struct{}, urlTestParallel)
	outbounds := instance.Box().Outbound()
	for _, tag := range tags {
		outbound, found := outbounds.Outbound(tag)
		if !found {
			results[tag] = URLTestResult{Error: "outbound not found"}
			continue
		}
		group.Add(1)
		go func() {
			defer group.Done()
			slots <- struct{}{}
			defer func() { <-slots }()
			ctx, cancel := context.WithTimeout(context.Background(), timeout)
			defer cancel()
			delay, err := urltest.URLTest(ctx, url, outbound)
			result := URLTestResult{DelayMs: int(delay)}
			switch {
			case err == nil && delay == 0:
				result.DelayMs = 1 // Faster than a millisecond is still an answer.
			case errors.Is(err, context.DeadlineExceeded), ctx.Err() != nil:
				result = URLTestResult{Error: "timeout"}
			case err != nil:
				result = URLTestResult{Error: err.Error()}
			}
			access.Lock()
			results[tag] = result
			access.Unlock()
		}()
	}
	group.Wait()
	return urlTestResponse{Results: results}
}
