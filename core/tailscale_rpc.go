package main

import (
	"encoding/json"
	"errors"
	"github.com/metacubex/mihomo/constant/features"
	"net/netip"
)

func handleTailscaleCall(call *MethodCall, response MethodResponse) bool {
	if call.Method == tailscaleLoginMethod {
		defer func() { clear(call.Arguments); call.Arguments = nil }()
	}
	var result tsSnapshot
	var err error
	switch call.Method {
	case tailscaleCaptureMethod:
		if !features.Android {
			err = errors.New("unsupported")
			break
		}
		var p struct {
			Prefixes []string `json:"prefixes"`
			Failure  bool     `json:"failure"`
		}
		if json.Unmarshal(call.Arguments, &p) != nil {
			err = errors.New("invalid_arguments")
			break
		}
		for _, text := range p.Prefixes {
			if _, e := netip.ParsePrefix(text); e != nil {
				err = errors.New("invalid_prefix")
				break
			}
		}
		if err != nil {
			break
		}
		tsAndroidRoutes.Store(p.Prefixes)
		tsAndroidRoutesKnown.Store(true)
		managedTS.mu.Lock()
		managedTS.captureFailure = p.Failure
		managedTS.mu.Unlock()
		runLock.Lock()
		tsReportConfig(tsCurrentProfile(), nil)
		runLock.Unlock()
		result = managedTS.Snapshot()
	case tailscaleCapabilitiesMethod:
		response.success(map[string]any{"supported": tsSupported, "protocol": 2})
		return true
	case tailscaleSnapshotMethod:
		result = managedTS.Snapshot()
	case tailscaleLoginMethod:
		var p struct {
			Kind    string `json:"kind"`
			Control string `json:"control"`
			AuthKey string `json:"authKey"`
		}
		if json.Unmarshal(call.Arguments, &p) != nil {
			response.failure("invalid_arguments", "invalid tailscale request", nil)
			return true
		}
		if p.Kind != "browser" && p.Kind != "key" {
			err = errors.New("invalid_login_kind")
		} else {
			result, err = managedTS.Begin(p.Kind, p.Control, p.AuthKey)
		}
		p.AuthKey = ""
	case tailscaleCancelMethod:
		result, err = managedTS.Stop("cancel")
	case tailscalePauseMethod:
		result, err = managedTS.Stop("pause")
	case tailscaleResumeMethod:
		result, err = managedTS.Begin("resume", "", "")
	case tailscaleLogoutMethod:
		result, err = managedTS.Stop("logout")
	case tailscaleRefreshMethod:
		result = managedTS.Refresh()
	case tailscalePreferencesMethod:
		oldPrefs := managedTS.Snapshot().Prefs
		var p tsPreferences
		if json.Unmarshal(call.Arguments, &p) != nil {
			err = errors.New("invalid_arguments")
		} else {
			result, err = managedTS.SetPreferences(p)
			if err == nil && tsCurrentProfile() != 0 {
				if applyErr := tsReloadConfig(); applyErr != nil {
					_, _ = managedTS.SetPreferences(oldPrefs)
					_ = tsReloadConfig()
					err = errors.New("config_apply_failed")
				}
				result = managedTS.Snapshot()
			}
		}
	case tailscaleProbeMethod:
		var p struct {
			IDs []string `json:"ids"`
		}
		if json.Unmarshal(call.Arguments, &p) != nil {
			err = errors.New("invalid_arguments")
		} else {
			result, err = managedTS.Probe(p.IDs)
		}
	case tailscaleCancelProbesMethod:
		result = managedTS.CancelProbes()
	default:
		return false
	}
	if err == nil && (call.Method == tailscaleLogoutMethod || call.Method == tailscaleCancelMethod) && tsCurrentProfile() != 0 {
		if tsReloadConfig() != nil {
			err = errors.New("config_apply_failed")
		}
		result = managedTS.Snapshot()
	}
	if err != nil {
		response.failure(err.Error(), "tailscale operation failed", nil)
	} else {
		response.success(result)
	}
	return true
}
