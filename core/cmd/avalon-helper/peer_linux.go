package main

import (
	"net"
	"os"
	"strconv"
	"strings"
	"syscall"
)

// peerUID is the user of the process at the other end (SO_PEERCRED).
func peerUID(conn *net.UnixConn) (int, error) {
	raw, err := conn.SyscallConn()
	if err != nil {
		return -1, err
	}
	var cred *syscall.Ucred
	var credErr error
	if err := raw.Control(func(fd uintptr) {
		cred, credErr = syscall.GetsockoptUcred(int(fd), syscall.SOL_SOCKET, syscall.SO_PEERCRED)
	}); err != nil {
		return -1, err
	}
	if credErr != nil {
		return -1, credErr
	}
	return int(cred.Uid), nil
}

// tunAvailable: root, or CAP_NET_ADMIN in the effective set (deb/rpm give
// the helper the capability with setcap).
func tunAvailable() bool {
	if os.Geteuid() == 0 {
		return true
	}
	status, err := os.ReadFile("/proc/self/status")
	if err != nil {
		return false
	}
	for _, line := range strings.Split(string(status), "\n") {
		if hex, ok := strings.CutPrefix(line, "CapEff:"); ok {
			caps, err := strconv.ParseUint(strings.TrimSpace(hex), 16, 64)
			const capNetAdmin = 12
			return err == nil && caps&(1<<capNetAdmin) != 0
		}
	}
	return false
}
