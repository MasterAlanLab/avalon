package bridge

import (
	"context"
	"os"

	"github.com/sagernet/sing-box/daemon"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing/service/filemanager"
)

// NewDesktopService builds the daemon service for hosts where sing-box
// handles the network itself (the Windows and Linux helper, tests). Mobile
// hosts build theirs through libbox with a platform interface instead.
func NewDesktopService(workingDir, tempDir string) *daemon.StartedService {
	ctx := filemanager.WithDefault(context.Background(), workingDir, tempDir, os.Getuid(), os.Getgid())
	return daemon.NewStartedService(daemon.ServiceOptions{
		Context:     include.Context(ctx),
		Handler:     quietHandler{},
		LogMaxLines: logBufferSize,
	})
}

type quietHandler struct{}

func (quietHandler) WriteDebugMessage(string)        {}
func (quietHandler) ConnectSSHAgent() (int32, error) { return 0, os.ErrInvalid }
