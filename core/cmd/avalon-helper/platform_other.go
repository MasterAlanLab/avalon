//go:build !windows

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

func platformMain(action, sid, state, socket string) (bool, error) {
	if action != "" || sid != "" {
		return true, fmt.Errorf("Windows helper actions are unavailable on this platform")
	}
	return false, nil
}

func writePlatformError(err error) {
	_ = json.NewEncoder(os.Stdout).Encode(map[string]any{"error": map[string]string{"code": "UNSUPPORTED", "message": err.Error()}})
}
