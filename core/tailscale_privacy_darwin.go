//go:build darwin

package main

import (
	"golang.org/x/sys/unix"
	"path/filepath"
)

func tsIdentityRoot(home string) string { return filepath.Join(home, "managed-tailscale-v2") }

func markTSIdentityPrivate(path string) error {
	// Standard Time Machine metadata exclusion, attached to the directory. Use
	// the syscall rather than spawning tmutil on every backend notification.
	const value = `<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><string>com.apple.backupd</string></plist>`
	return unix.Setxattr(path, "com.apple.metadata:com_apple_backup_excludeItem", []byte(value), 0)
}
