package windowshost

import (
	"strings"
	"testing"
)

func TestPrivilegedPlanPathsAreRewrittenOrRejected(t *testing.T) {
	for _, raw := range []string{
		`{"log":{"output":"C:/Windows/win.ini"}}`,
		`{"outbounds":[{"type":"ssh","private_key_path":"C:/secret"}]}`,
		`{"outbounds":[{"type":"tor","executable_path":"C:/run.exe"}]}`,
		`{"dns":{"servers":[{"type":"hosts","path":["C:/secret"]}]}}`,
		`{"experimental":{"other":{"directory":"C:/Windows"}}}`,
		`{"outbounds":[{"type":"direct","tls":{"key_path":"C:/secret"}}]}`,
		`{"outbounds":[{"type":"direct","script":"anything"}]}`,
		`{"outbounds":[{"Type":"tor"}]}`,
		`{"experimental":{"cache_file":{"PATH":"C:/Windows/target"}}}`,
		`{"route":{"dhcp_lease_files":["C:/Windows/secret"]}}`,
		`{"ntp":{"enabled":true,"write_to_system":true}}`,
	} {
		if _, _, err := RewritePlan([]byte(raw), `C:/private`, nil); err == nil {
			t.Fatalf("accepted unsafe plan %s", raw)
		}
	}
	raw := `{"inbounds":[{"type":"tun"}],"outbounds":[{"type":"vmess","transport":{"type":"ws","path":"/rpc"}}],"route":{"rule_set":[{"type":"local","path":"C:/shared/rulesets/a.json"}],"rules":[{"process_path":"C:/App.exe"}]},"experimental":{"cache_file":{"path":"C:/bad"},"clash_api":{"external_ui":"C:/bad"}},"endpoints":[{"type":"tailscale","state_directory":"C:/bad"}]}`
	got, tun, err := RewritePlan([]byte(raw), `C:/private`, func(path string) (string, error) { return "C:/private/rulesets/a.json", nil })
	if err != nil || !tun || strings.Contains(string(got), "C:/bad") || strings.Contains(string(got), "C:/shared") {
		t.Fatalf("rewrite=%s tun=%v err=%v", got, tun, err)
	}
}

func TestStateTransferCannotNameFiles(t *testing.T) {
	if err := ValidTransfer(map[string][]byte{"../file": {1}}); err == nil {
		t.Fatal("accepted caller path")
	}
	if err := ValidTransfer(map[string][]byte{"tailscale/tailscaled.state": []byte(`{"identity":"test"}`)}); err != nil {
		t.Fatal(err)
	}
}

func TestOnlyCanonicalAccountSIDsAreAccepted(t *testing.T) {
	for _, sid := range []string{"S-1-5-21-1-2-3-1001", "S-1-12-1-123-456-789-4294967295"} {
		if !ValidSID(sid) {
			t.Fatalf("rejected account SID %s", sid)
		}
	}
	for _, sid := range []string{"S-1-5-18", "S-1-5-32-544", "S-1-5-21-01-2-3-1001", "S-1-12-1-1-2-3-4294967296", "S-1-5-21-1-2-3-1001/other"} {
		if ValidSID(sid) {
			t.Fatalf("accepted unsafe SID %s", sid)
		}
	}
}

func TestPrivilegedRequestCaseCannotBypassPathChecks(t *testing.T) {
	for _, pair := range [][2]string{{"fetch", `{"DestPath":"C:/Windows/target"}`}, {"urlTest", `{"PlanPath":"C:/Windows/secret"}`}, {"start", `{"PLAN":{"outbounds":[]}}`}} {
		if err := ValidateRequestKeys(pair[0], []byte(pair[1])); err == nil {
			t.Fatalf("accepted noncanonical privileged request %v", pair)
		}
	}
	if err := ValidateRequestKeys("fetch", []byte(`{"destPath":"C:/shared/rulesets/new","publicOnly":true}`)); err != nil {
		t.Fatal(err)
	}
}
