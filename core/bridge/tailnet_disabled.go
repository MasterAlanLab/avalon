//go:build !with_gvisor || !with_tailscale

package bridge

func (e *Engine) tailnetStatus() (any, *Error) {
	return nil, &Error{Code: CodeUnsupported, Message: "this core does not include Tailscale"}
}

func (e *Engine) tailnetAccount(bool) (any, *Error) { return e.tailnetStatus() }
