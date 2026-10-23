package bridge

import "sync"

// resultCache keeps the outcome of the last commands so that a caller
// whose wait timed out can ask what happened instead of sending the
// command again (RUNTIME_HOST §2, §4).
type resultCache struct {
	mu      sync.Mutex
	order   []string
	entries map[string]CommandStatus
	size    int
}

func newResultCache(size int) *resultCache {
	return &resultCache{entries: map[string]CommandStatus{}, size: size}
}

func (c *resultCache) begin(requestID string) {
	if requestID == "" {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if _, known := c.entries[requestID]; !known {
		c.order = append(c.order, requestID)
		if len(c.order) > c.size {
			delete(c.entries, c.order[0])
			c.order = c.order[1:]
		}
	}
	c.entries[requestID] = CommandStatus{Status: "pending"}
}

func (c *resultCache) finish(requestID string, result any, err *Error) {
	if requestID == "" {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if _, known := c.entries[requestID]; !known {
		return // Pushed out by newer commands meanwhile.
	}
	if err != nil {
		c.entries[requestID] = CommandStatus{Status: "failed", Error: err}
		return
	}
	c.entries[requestID] = CommandStatus{Status: "done", Result: result}
}

func (c *resultCache) status(requestID string) CommandStatus {
	c.mu.Lock()
	defer c.mu.Unlock()
	if status, known := c.entries[requestID]; known {
		return status
	}
	return CommandStatus{Status: "unknown"}
}
