// Package windowshost contains the Windows helper's privilege boundary.
// The policy is platform independent so rejected plans are tested on every host.
package windowshost

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

const MaxTransferBytes = 32 << 20

var sidPattern = regexp.MustCompile(`^(?:S-1-5-21|S-1-12-1)(?:-[0-9]{1,10}){4}$`)

// ValidSID restricts installations to real local/domain account SIDs, not groups,
// well-known identities, arbitrary pipe names or command-line fragments.
func ValidSID(s string) bool {
	if !sidPattern.MatchString(s) {
		return false
	}
	parts := strings.Split(s, "-")
	for _, value := range parts[4:] {
		if len(value) > 1 && value[0] == '0' {
			return false
		}
		if _, err := strconv.ParseUint(value, 10, 32); err != nil {
			return false
		}
	}
	return true
}

func PipeName(sid string, service bool) string {
	mode := "user"
	if service {
		mode = "service"
	}
	return `\\.\pipe\Avalon-` + sid + "-" + mode + "-v1"
}

func ServiceName(sid string) string { return "AvalonHelper_" + sid }

// TransferFiles is deliberately a fixed inventory. A client cannot make the
// SYSTEM service read or replace a file by naming it in a transfer request.
var TransferFiles = []string{"cache.db", "traffic-today.json", "tailscale/tailscaled.state"}

func ValidTransfer(files map[string][]byte) error {
	total := 0
	for name, body := range files {
		found := false
		for _, allowed := range TransferFiles {
			found = found || name == allowed
		}
		if !found {
			return errors.New("state transfer contains an unsupported file")
		}
		total += len(body)
		if total > MaxTransferBytes {
			return errors.New("state transfer is too large")
		}
	}
	return nil
}

// RewritePlan removes all client-controlled privileged filesystem operations.
// copyRule reads a shared rule file with the caller's token and snapshots it
// into an immutable file in the private runtime. No core code reads shared files.
func RewritePlan(raw []byte, runtime string, copyRule func(string) (string, error)) ([]byte, bool, error) {
	var root map[string]any
	if err := json.Unmarshal(raw, &root); err != nil || root == nil {
		return nil, false, errors.New("invalid plan")
	}
	allowedRoots := map[string]bool{"log": true, "dns": true, "inbounds": true, "outbounds": true, "endpoints": true, "route": true, "experimental": true, "_avalon_public_network": true}
	for k := range root {
		if !allowedRoots[k] {
			return nil, false, fmt.Errorf("unsupported plan section: %s", k)
		}
	}
	tun := false
	join := func(name string) string { return strings.TrimRight(runtime, `\/`) + `/` + name }
	var visit func(any, []string) error
	visit = func(value any, at []string) error {
		switch v := value.(type) {
		case []any:
			for _, child := range v {
				if err := visit(child, at); err != nil {
					return err
				}
			}
		case map[string]any:
			for key := range v {
				if key != "type" && strings.EqualFold(key, "type") {
					return errors.New("plan type fields must use their canonical spelling")
				}
			}
			if typ, _ := v["type"].(string); typ != "" {
				// No process execution, filesystem servers, scripts or new engine
				// modules can be introduced through this privileged endpoint.
				switch typ {
				case "tor":
					return fmt.Errorf("unsupported privileged plan type: %s", typ)
				case "tun":
					tun = true
				}
			}
			for key, child := range v {
				place := strings.Join(append(at, key), ".")
				lower := strings.ToLower(key)
				// These fields invoke code or select filesystem roots. Reject even
				// empty values, so newly enabled upstream features fail closed.
				if strings.Contains(lower, "script") || strings.Contains(lower, "javascript") || strings.Contains(lower, "executable") || lower == "command" || lower == "wrapper" || lower == "plugins" {
					return fmt.Errorf("unsupported privileged plan field: %s", place)
				}
				switch {
				case place == "log.output":
					return errors.New("file logging is not permitted in a service plan")
				case place == "experimental.cache_file.path":
					v[key] = join("cache.db")
					continue
				case place == "experimental.clash_api.external_ui":
					v[key] = join("ui")
					continue
				case key == "state_directory" && len(at) == 1 && at[0] == "endpoints" && v["type"] == "tailscale":
					v[key] = join("tailscale")
					continue
				case key == "path" && len(at) == 2 && at[0] == "route" && at[1] == "rule_set" && v["type"] == "local":
					path, ok := child.(string)
					if !ok {
						return errors.New("invalid local rule path")
					}
					private, err := copyRule(path)
					if err != nil {
						return err
					}
					v[key] = private
					continue
				case key == "process_path" || key == "process_path_regex":
					// Process match strings do not perform filesystem I/O.
					continue
				case lower == "path":
					// HTTP/WebSocket/gRPC URL paths are the only remaining path
					// fields allowed. Never infer safety from a string prefix.
					if key != "path" || len(at) == 0 || at[len(at)-1] != "transport" && !(len(at) == 2 && at[0] == "dns" && at[1] == "servers" && v["type"] == "https") {
						return fmt.Errorf("unsupported privileged file path: %s", place)
					}
				case strings.HasSuffix(lower, "_path") || strings.HasSuffix(lower, "_paths") || strings.HasSuffix(lower, "_directory") || strings.HasSuffix(lower, "_files") || strings.HasSuffix(lower, "_file") && place != "experimental.cache_file" || lower == "directory" || lower == "file" || lower == "output" || lower == "external_ui":
					return fmt.Errorf("unsupported privileged file field: %s", place)
				}
				if err := visit(child, append(at, key)); err != nil {
					return err
				}
			}
		}
		return nil
	}
	if err := visit(root, nil); err != nil {
		return nil, false, err
	}
	// Ensure cache and endpoint defaults cannot select a process working
	// directory outside the private runtime if the client omits their paths.
	if endpoints, ok := root["endpoints"].([]any); ok {
		for _, entry := range endpoints {
			if endpoint, ok := entry.(map[string]any); ok && endpoint["type"] == "tailscale" {
				endpoint["state_directory"] = join("tailscale")
			}
		}
	}
	result, err := json.Marshal(root)
	return result, tun, err
}

func AllowedCommand(command string) bool {
	switch command {
	case "start", "reload", "stop", "setMode", "select", "urlTest", "fetch", "queryCommand", "snapshot", "connections", "closeConnection", "closeAllConnections", "capabilities", "logs", "tailnetStatus", "tailnetLogin", "tailnetLogout", "hostShutdown", "hostExportState", "hostImportState", "hostCheckPlan":
		return true
	}
	return false
}

// ValidateRequestKeys is case-sensitive, unlike Go's struct JSON decoder.
// Without it, e.g. DestPath could evade the host's destPath validation and
// subsequently be accepted by the Bridge as a privileged write destination.
func ValidateRequestKeys(command string, raw []byte) error {
	var request map[string]json.RawMessage
	if len(raw) == 0 {
		raw = []byte(`{}`)
	}
	if err := json.Unmarshal(raw, &request); err != nil || request == nil {
		return errors.New("invalid host request")
	}
	fields := ""
	switch command {
	case "start", "reload", "hostCheckPlan":
		fields = "requestId sessionId plan planPath planHash utcOffsetSeconds"
	case "urlTest":
		fields = "requestId sessionId plan planPath planHash tags url timeoutMs"
	case "fetch":
		fields = "requestId sessionId outboundTag url maxBytes destPath timeoutMs publicOnly"
	case "stop", "tailnetLogin", "tailnetLogout", "queryCommand":
		fields = "requestId"
	case "setMode":
		fields = "requestId sessionId mode"
	case "select":
		fields = "requestId sessionId groupTag memberTag"
	case "connections":
		fields = "sessionId"
	case "closeConnection":
		fields = "requestId sessionId id"
	case "closeAllConnections":
		fields = "requestId sessionId"
	case "logs":
		fields = "afterSeq limit"
	case "hostImportState":
		fields = "version files"
	}
	allowed := map[string]bool{}
	for _, key := range strings.Fields(fields) {
		allowed[key] = true
	}
	for key := range request {
		if !allowed[key] {
			return fmt.Errorf("unsupported host request field: %s", key)
		}
	}
	return nil
}
