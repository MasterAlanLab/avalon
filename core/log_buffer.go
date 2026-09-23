package main

import (
	"sync"

	"github.com/metacubex/mihomo/log"
)

// Keep a bounded history even when the UI log stream is disabled.  The UI
// stream is intentionally opt-in, while an export should still contain the
// mihomo messages that explain a TUN/global-mode failure.
const coreLogBufferSize = 2000

var coreLogBuffer = struct {
	sync.RWMutex
	items []log.Event
}{
	items: make([]log.Event, 0, coreLogBufferSize),
}

var coreLogBufferOnce sync.Once

func initCoreLogBuffer() {
	coreLogBufferOnce.Do(func() {
		subscriber := log.Subscribe()
		go func() {
			for item := range subscriber {
				coreLogBuffer.Lock()
				if len(coreLogBuffer.items) == coreLogBufferSize {
					copy(coreLogBuffer.items, coreLogBuffer.items[1:])
					coreLogBuffer.items = coreLogBuffer.items[:coreLogBufferSize-1]
				}
				coreLogBuffer.items = append(coreLogBuffer.items, item)
				coreLogBuffer.Unlock()
			}
		}()
	})
}

func resetCoreLogBuffer() {
	coreLogBuffer.Lock()
	coreLogBuffer.items = coreLogBuffer.items[:0]
	coreLogBuffer.Unlock()
}

func handleGetLogs() []log.Event {
	initCoreLogBuffer()
	coreLogBuffer.RLock()
	defer coreLogBuffer.RUnlock()
	return append([]log.Event(nil), coreLogBuffer.items...)
}

func init() {
	initCoreLogBuffer()
}
