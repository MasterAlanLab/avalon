package bridge

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/sagernet/sing-box/adapter"
	"github.com/sagernet/sing-box/common/urltest"
	"github.com/sagernet/sing-box/dns"
	"github.com/sagernet/sing-box/experimental/clashmode"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/log"
	"github.com/sagernet/sing-box/option"
	"github.com/sagernet/sing-box/protocol/group"
	"github.com/sagernet/sing/common/json"
	services "github.com/sagernet/sing/service"
)

// TestCompilerPlans checks what Avalon's compiler writes against the real
// core, as `sing-box check` would: every field must be one this sing-box
// knows, in the shape it expects. The plans come from the Dart compiler's
// tests (see check_plans.sh); without them the test is skipped.
func TestCompilerPlans(t *testing.T) {
	dir := os.Getenv("AVALON_PLANS")
	if dir == "" {
		t.Skip("AVALON_PLANS is not set; run core/check_plans.sh")
	}
	files, err := filepath.Glob(filepath.Join(dir, "*.json"))
	if err != nil || len(files) == 0 {
		t.Fatalf("no plans in %s (%v)", dir, err)
	}
	for _, file := range files {
		t.Run(strings.TrimSuffix(filepath.Base(file), ".json"), func(t *testing.T) {
			raw, err := os.ReadFile(file)
			if err != nil {
				t.Fatal(err)
			}
			// The plans name files under the host's state directory.
			state := t.TempDir()
			content := strings.ReplaceAll(string(raw), "/data/state", state)
			content = strings.ReplaceAll(content, "/state", state)
			// A converted rule provider the plan reads from the cache.
			ruleSet := filepath.Join(state, "rulesets", "ads.json")
			if err := os.MkdirAll(filepath.Dir(ruleSet), 0o755); err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(ruleSet, []byte(`{"version": 1, "rules": []}`), 0o644); err != nil {
				t.Fatal(err)
			}
			service := NewDesktopService(state, t.TempDir())
			if err := service.CheckConfig(context.Background(), content); err != nil {
				t.Fatalf("the core rejects this plan: %v", err)
			}
			ctx := include.Context(context.Background())
			options, err := json.UnmarshalExtendedContext[option.Options](ctx, []byte(content))
			if err != nil {
				t.Fatal(err)
			}
			logger := log.NewNOPFactory()
			services.MustRegisterPtr(ctx, urltest.NewHistoryStorage())
			for _, outbound := range options.Outbounds {
				if settings, ok := outbound.Options.(*option.URLTestOutboundOptions); ok {
					// CheckConfig does not run URLTest.Start; use the real
					// group constructor to validate its startup durations.
					g, err := group.NewURLTestGroup(ctx, nil, logger.Logger(), nil, settings.URL,
						time.Duration(settings.Interval), settings.Tolerance, time.Duration(settings.IdleTimeout), false)
					if err != nil {
						t.Fatalf("compiled URLTest %s cannot start: %v", outbound.Tag, err)
					}
					g.Close()
				}
			}
			if options.Experimental == nil || options.Experimental.ClashAPI == nil {
				// Tailnet-only plans have no proxy modes (CONFIG_PIPELINE §6).
				return
			}
			// The real mode manager clears DNS caches on a change. Supply
			// an unstarted real router; no tunnel, DNS or rule-set fetch runs.
			router, err := dns.NewRouter(ctx, logger, option.DNSOptions{})
			if err != nil {
				t.Fatal(err)
			}
			defer router.Close()
			services.MustRegister[adapter.DNSRouter](ctx, router)
			modes := clashmode.NewManager(ctx, logger.Logger(), options.Experimental.ClashAPI.DefaultMode, clashmode.CalculateModeList(options))
			for _, mode := range []string{"direct", "global", "rule"} {
				modes.SetMode(mode)
				if !strings.EqualFold(modes.Mode(), mode) {
					t.Fatalf("compiled plan cannot select %s: actual %s, available %v", mode, modes.Mode(), modes.ModeList())
				}
			}
		})
	}
}
