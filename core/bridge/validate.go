package bridge

import (
	"context"
)

// ValidatePlan checks a host-sanitized candidate without replacing the active
// session. Desktop privilege-mode changes use it before stopping the old host.
// It is a host API, not an additional public Bridge wire command.
func (e *Engine) ValidatePlan(raw []byte) *Error {
	e.lifecycle.Lock()
	defer e.lifecycle.Unlock()
	r := startRequest{Plan: raw}
	if err := e.preparePlan(&r); err != nil {
		return err
	}
	if err := e.service.CheckConfig(context.Background(), string(r.corePlan)); err != nil {
		return &Error{Code: CodePlanInvalid, Message: err.Error()}
	}
	return nil
}
