//go:build windows

package main

import (
	"golang.org/x/sys/windows"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestTSWindowsIdentityIsLocalAndProtected(t *testing.T) {
	path := tsIdentityRoot(`C:\Users\fixture\AppData\Roaming\Avalon`)
	if strings.Contains(strings.ToLower(path), `\roaming\`) || !strings.Contains(strings.ToLower(path), `\local\`) {
		t.Fatal("identity would roam to another device")
	}
	root := filepath.Join(t.TempDir(), "managed-tailscale-v2")
	if err := os.Mkdir(root, 0700); err != nil {
		t.Fatal(err)
	}
	if err := markTSIdentityPrivate(root); err != nil {
		t.Fatal(err)
	}
	sd, err := windows.GetNamedSecurityInfo(root, windows.SE_FILE_OBJECT, windows.DACL_SECURITY_INFORMATION)
	if err != nil {
		t.Fatal(err)
	}
	control, _, err := sd.Control()
	if err != nil || control&windows.SE_DACL_PROTECTED == 0 {
		t.Fatal("identity inherited an unprotected DACL")
	}
}
