//go:build !darwin && !windows

package main

import "path/filepath"

func tsIdentityRoot(home string) string { return filepath.Join(home, "managed-tailscale-v2") }

// Android excludes this application-file root from cloud/device-transfer backup.
// Linux backup products have no shared exclusion API; configure an explicit
// exclusion in the installed system backup tool (see delivery checklist).
func markTSIdentityPrivate(string) error { return nil }
