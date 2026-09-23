package main

import (
	b "bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sync"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/inbound"
	"github.com/metacubex/mihomo/adapter/outboundgroup"
	"github.com/metacubex/mihomo/adapter/provider"
	"github.com/metacubex/mihomo/common/batch"
	"github.com/metacubex/mihomo/component/dialer"
	"github.com/metacubex/mihomo/component/resolver"
	"github.com/metacubex/mihomo/component/updater"
	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/constant/features"
	cp "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/hub"
	"github.com/metacubex/mihomo/hub/executor"
	"github.com/metacubex/mihomo/hub/route"
	"github.com/metacubex/mihomo/listener"
	LC "github.com/metacubex/mihomo/listener/config"
	"github.com/metacubex/mihomo/log"
	rp "github.com/metacubex/mihomo/rules/provider"
	"github.com/metacubex/mihomo/tunnel"
)

var (
	currentConfig *config.Config
	version       = 0
	isRunning     = false
	runLock       sync.Mutex
	mBatch, _     = batch.New[bool](context.Background(), batch.WithConcurrencyNum[bool](50))
	debugError    = false
)

func getExternalProvidersRaw() map[string]cp.Provider {
	eps := make(map[string]cp.Provider)
	for n, p := range tunnel.Providers() {
		if p.VehicleType() != cp.Compatible {
			eps[n] = p
		}
	}
	for n, p := range tunnel.RuleProviders() {
		if p.VehicleType() != cp.Compatible {
			eps[n] = p
		}
	}
	return eps
}

func toExternalProvider(p cp.Provider) (*ExternalProvider, error) {
	switch p.(type) {
	case *provider.ProxySetProvider:
		psp := p.(*provider.ProxySetProvider)
		return &ExternalProvider{
			Name:             psp.Name(),
			Type:             psp.Type().String(),
			VehicleType:      psp.VehicleType().String(),
			Count:            psp.Count(),
			UpdateAt:         psp.UpdatedAt(),
			Path:             psp.Vehicle().Path(),
			SubscriptionInfo: psp.GetSubscriptionInfo(),
		}, nil
	case *rp.RuleSetProvider:
		rsp := p.(*rp.RuleSetProvider)
		return &ExternalProvider{
			Name:        rsp.Name(),
			Type:        rsp.Type().String(),
			VehicleType: rsp.VehicleType().String(),
			Count:       rsp.Count(),
			UpdateAt:    rsp.UpdatedAt(),
			Path:        rsp.Vehicle().Path(),
		}, nil
	default:
		return nil, errors.New("not external provider")
	}
}

func sideUpdateExternalProvider(p cp.Provider, bytes []byte) error {
	switch p.(type) {
	case *provider.ProxySetProvider:
		psp := p.(*provider.ProxySetProvider)
		_, _, err := psp.SideUpdate(bytes)
		if err == nil {
			return err
		}
		return nil
	case rp.RuleSetProvider:
		rsp := p.(*rp.RuleSetProvider)
		_, _, err := rsp.SideUpdate(bytes)
		if err == nil {
			return err
		}
		return nil
	default:
		return errors.New("not external provider")
	}
}

// updateTunListener applies a TUN configuration and surfaces the failure state
// recorded by mihomo's legacy listener API.
func updateTunListener(tunConf LC.Tun) error {
	log.Infoln(
		"[TUN] recreate begin enable=%t device=%q stack=%v autoRoute=%t strictRoute=%t dnsHijack=%v routeAddress=%v",
		tunConf.Enable,
		tunConf.Device,
		tunConf.Stack,
		tunConf.AutoRoute,
		tunConf.StrictRoute,
		tunConf.DNSHijack,
		tunConf.RouteAddress,
	)
	// mihomo's ReCreateTun API predates error returns and reports a failed
	// creation by recording an effectively disabled LastTunConf.  Inspect
	// that state here so a failed OS-level recreate is still returned to the
	// caller without changing the upstream submodule.
	listener.ReCreateTun(tunConf, tunnel.Tunnel)
	actualTun := listener.GetTunConf()
	if tunConf.Enable && !actualTun.Enable {
		err := fmt.Errorf("recreate TUN failed: listener is disabled after create")
		log.Errorln(
			"[TUN] recreate failed requestedEnable=%t actualEnable=%t device=%q stack=%v: %v",
			tunConf.Enable,
			actualTun.Enable,
			actualTun.Device,
			actualTun.Stack,
			err,
		)
		return err
	}
	log.Infoln(
		"[TUN] recreate complete requestedEnable=%t actualEnable=%t device=%q stack=%v",
		tunConf.Enable,
		actualTun.Enable,
		actualTun.Device,
		actualTun.Stack,
	)
	return nil
}

// updateListeners refreshes ordinary inbound listeners and optionally refreshes
// the TUN listener. The TUN device is an OS resource, so recreating it for a
// change that only affects routing mode can make Windows remove the existing
// Wintun adapter while the replacement is still starting.
func updateListeners(recreateTun bool) error {
	if !isRunning {
		return nil
	}
	if currentConfig == nil || currentConfig.General == nil {
		return errors.New("config is not loaded")
	}
	listeners := currentConfig.Listeners
	general := currentConfig.General
	listener.PatchInboundListeners(listeners, tunnel.Tunnel, true)

	allowLan := general.AllowLan
	listener.SetAllowLan(allowLan)
	inbound.SetSkipAuthPrefixes(general.SkipAuthPrefixes)
	inbound.SetAllowedIPs(general.LanAllowedIPs)
	inbound.SetDisAllowedIPs(general.LanDisAllowedIPs)

	bindAddress := general.BindAddress
	listener.SetBindAddress(bindAddress)
	listener.ReCreateHTTP(general.Port, tunnel.Tunnel)
	listener.ReCreateSocks(general.SocksPort, tunnel.Tunnel)
	listener.ReCreateRedir(general.RedirPort, tunnel.Tunnel)
	listener.ReCreateTProxy(general.TProxyPort, tunnel.Tunnel)
	listener.ReCreateMixed(general.MixedPort, tunnel.Tunnel)
	listener.ReCreateShadowSocks(general.ShadowSocksConfig, tunnel.Tunnel)
	listener.ReCreateVmess(general.VmessConfig, tunnel.Tunnel)
	listener.ReCreateTuic(general.TuicServer, tunnel.Tunnel)
	if recreateTun && !features.Android {
		return updateTunListener(general.Tun)
	}
	return nil
}

func stopListeners() {
	listener.StopListener()
}

// equalTunConfig compares the effective TUN settings rather than the order in
// which list-valued settings were supplied.  ReCreateTun sorts these lists
// before applying them; normalizing the snapshots here avoids tearing down a
// live device for an order-only update.
func equalTunConfig(left, right LC.Tun) bool {
	leftBytes, leftErr := json.Marshal(left)
	rightBytes, rightErr := json.Marshal(right)
	if leftErr != nil || rightErr != nil {
		return left.Equal(right)
	}
	var normalizedLeft, normalizedRight LC.Tun
	if json.Unmarshal(leftBytes, &normalizedLeft) != nil ||
		json.Unmarshal(rightBytes, &normalizedRight) != nil {
		return left.Equal(right)
	}
	normalizedLeft.Sort()
	normalizedRight.Sort()
	return normalizedLeft.Equal(normalizedRight)
}

func patchSelectGroup(mapping map[string]string) {
	for name, proxy := range tunnel.AllProxies() {
		outbound, ok := proxy.(*adapter.Proxy)
		if !ok {
			continue
		}

		selector, ok := outbound.ProxyAdapter.(outboundgroup.SelectAble)
		if !ok {
			continue
		}

		selected, exist := mapping[name]
		if !exist {
			continue
		}

		selector.ForceSet(selected)
	}
}

func defaultSetupParams() *SetupParams {
	return &SetupParams{
		TestURL:     "https://www.gstatic.com/generate_204",
		SelectedMap: map[string]string{},
	}
}

func readFile(path string) ([]byte, error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	return data, err
}

func updateConfig(params *UpdateParams) error {
	runLock.Lock()
	defer runLock.Unlock()
	if currentConfig == nil || currentConfig.General == nil {
		return errors.New("config is not loaded")
	}
	general := currentConfig.General
	previousMode := general.Mode
	previousTun := general.Tun
	if params.MixedPort != nil {
		general.MixedPort = *params.MixedPort
	}
	if params.Sniffing != nil {
		general.Sniffing = *params.Sniffing
		tunnel.SetSniffing(general.Sniffing)
	}
	if params.FindProcessMode != nil {
		general.FindProcessMode = *params.FindProcessMode
		tunnel.SetFindProcessMode(general.FindProcessMode)
	}
	if params.TCPConcurrent != nil {
		general.TCPConcurrent = *params.TCPConcurrent
		dialer.SetTcpConcurrent(general.TCPConcurrent)
	}
	if params.Interface != nil {
		general.Interface = *params.Interface
		dialer.DefaultInterface.Store(general.Interface)
	}
	if params.UnifiedDelay != nil {
		general.UnifiedDelay = *params.UnifiedDelay
		adapter.UnifiedDelay.Store(general.UnifiedDelay)
	}
	if params.Mode != nil {
		general.Mode = *params.Mode
		tunnel.SetMode(general.Mode)
	}
	if params.LogLevel != nil {
		general.LogLevel = *params.LogLevel
		log.SetLevel(general.LogLevel)
	}
	if params.IPv6 != nil {
		general.IPv6 = *params.IPv6
		resolver.DisableIPv6 = !general.IPv6
	}
	if params.ExternalController != nil {
		currentConfig.Controller.ExternalController = *params.ExternalController
		route.ReCreateServer(&route.Config{
			Addr: currentConfig.Controller.ExternalController,
		})
	}

	if params.Tun != nil {
		general.Tun.Enable = params.Tun.Enable
		if params.Tun.AutoRoute != nil {
			general.Tun.AutoRoute = *params.Tun.AutoRoute
		}
		if params.Tun.StrictRoute != nil {
			general.Tun.StrictRoute = *params.Tun.StrictRoute
		}
		if params.Tun.Device != nil {
			general.Tun.Device = *params.Tun.Device
		}
		if params.Tun.RouteAddress != nil {
			general.Tun.RouteAddress = *params.Tun.RouteAddress
		}
		if params.Tun.Inet6Address != nil {
			general.Tun.Inet6Address = *params.Tun.Inet6Address
		}
		if params.Tun.DNSHijack != nil {
			general.Tun.DNSHijack = *params.Tun.DNSHijack
		}
		if params.Tun.Stack != nil {
			general.Tun.Stack = *params.Tun.Stack
		}
	}
	tunChanged := params.Tun != nil && !equalTunConfig(general.Tun, previousTun)
	log.Infoln(
		"[CONFIG] hot update mode=%s->%s tunChanged=%t tunEnable=%t->%t device=%q->%q stack=%v->%v autoRoute=%t->%t strictRoute=%t->%t dnsHijack=%v->%v routeAddress=%v->%v",
		previousMode,
		general.Mode,
		tunChanged,
		previousTun.Enable,
		general.Tun.Enable,
		previousTun.Device,
		general.Tun.Device,
		previousTun.Stack,
		general.Tun.Stack,
		previousTun.AutoRoute,
		general.Tun.AutoRoute,
		previousTun.StrictRoute,
		general.Tun.StrictRoute,
		previousTun.DNSHijack,
		general.Tun.DNSHijack,
		previousTun.RouteAddress,
		general.Tun.RouteAddress,
	)

	if params.GeoAutoUpdate != nil {
		updater.SetGeoAutoUpdate(*params.GeoAutoUpdate)
	}
	if params.GeoUpdateInterval != nil {
		updater.SetGeoUpdateInterval(*params.GeoUpdateInterval)
	}

	if err := updateListeners(tunChanged); err != nil {
		log.Errorln("[CONFIG] hot update listeners failed: %v", err)
		return err
	}
	if updater.GeoAutoUpdate() {
		updater.RegisterGeoUpdaterWithCancel()
	}
	return nil
}

func applyConfig(params *SetupParams) error {
	runtime.GC()
	runLock.Lock()
	defer runLock.Unlock()
	var err error
	constant.DefaultTestURL = params.TestURL
	currentConfig, err = executor.ParseWithPath(filepath.Join(constant.Path.HomeDir(), "config.yaml"))
	if err != nil {
		currentConfig, _ = config.ParseRawConfig(config.DefaultRawConfig())
	}
	hub.ApplyConfig(currentConfig)
	patchSelectGroup(params.SelectedMap)
	if listenerErr := updateListeners(true); listenerErr != nil {
		return listenerErr
	}
	if updater.GeoAutoUpdate() {
		updater.RegisterGeoUpdaterWithCancel()
	}
	return err
}

func UnmarshalJson(data []byte, v any) error {
	decoder := json.NewDecoder(b.NewReader(data))
	decoder.UseNumber()
	err := decoder.Decode(v)
	return err
}

func logError(format string, args ...interface{}) {
	log.Errorln(format, args...)
	if debugError {
		fmt.Fprintf(os.Stderr, "[ERROR] "+format+"\n", args...)
	}
}
