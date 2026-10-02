//go:build !with_gvisor || no_tailscale

package main

import (
	"context"
	"errors"
)

const tsSupported = false

func tsValidateControl(string) (string, error) { return "", errors.New("unsupported") }
func newRealTSBackend(context.Context, string, string, func() bool) (tsBackend, error) {
	return nil, errors.New("unsupported")
}
