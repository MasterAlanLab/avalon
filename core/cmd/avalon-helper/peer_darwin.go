package main

import (
	"net"
	"os"

	"golang.org/x/sys/unix"
)

// peerUID is the user of the process at the other end (LOCAL_PEERCRED).
func peerUID(conn *net.UnixConn) (int, error) {
	raw, err := conn.SyscallConn()
	if err != nil {
		return -1, err
	}
	var cred *unix.Xucred
	var credErr error
	if err := raw.Control(func(fd uintptr) {
		cred, credErr = unix.GetsockoptXucred(int(fd), unix.SOL_LOCAL, unix.LOCAL_PEERCRED)
	}); err != nil {
		return -1, err
	}
	if credErr != nil {
		return -1, credErr
	}
	return int(cred.Uid), nil
}

// tunAvailable: macOS opens utun as root only (the app proper uses a
// network extension; the helper here serves development and tests).
func tunAvailable() bool { return os.Geteuid() == 0 }
