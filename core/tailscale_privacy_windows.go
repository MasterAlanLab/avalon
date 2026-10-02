//go:build windows

package main

import (
	"golang.org/x/sys/windows"
	"path/filepath"
	"strings"
)

// path_provider uses Roaming AppData. The identity belongs in the same user's
// LOCAL AppData so Windows roaming profiles never copy it to another machine.
func tsIdentityRoot(home string) string {
	clean := filepath.Clean(home)
	if index := strings.Index(strings.ToLower(clean), `\appdata\roaming\`); index >= 0 {
		return filepath.Join(clean[:index], "AppData", "Local", "Avalon", "managed-tailscale-v2")
	}
	return filepath.Join(home, "managed-tailscale-v2")
}
func markTSIdentityPrivate(path string) error {
	// The helper may run elevated. Use the owner of the USER's application data
	// directory, rather than the helper process token, for the protected ACL.
	ownerPath := filepath.Dir(path)
	if index := strings.Index(strings.ToLower(path), `\appdata\local\`); index >= 0 {
		ownerPath = filepath.Join(path[:index], "AppData", "Local")
	}
	parent, err := windows.GetNamedSecurityInfo(ownerPath, windows.SE_FILE_OBJECT, windows.OWNER_SECURITY_INFORMATION)
	if err != nil {
		return err
	}
	owner, _, err := parent.Owner()
	if err != nil {
		return err
	}
	descriptor, err := windows.SecurityDescriptorFromString("D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;FA;;;" + owner.String() + ")")
	if err != nil {
		return err
	}
	dacl, _, err := descriptor.DACL()
	if err != nil {
		return err
	}
	return windows.SetNamedSecurityInfo(path, windows.SE_FILE_OBJECT, windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION, nil, nil, dacl, nil)
}
