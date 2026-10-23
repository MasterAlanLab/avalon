package bridge

import (
	"regexp"
	"sync"
	"time"
)

// The core formats lines for a terminal: colours (on Android), then the
// level and the seconds since it started. The level travels separately
// and readers have their own clock, so only the text is kept.
var (
	ansi           = regexp.MustCompile(`\x1b\[[0-9;]*m`)
	logPrefix      = regexp.MustCompile(`^[A-Z]+\[\d+\] `)
	tailnetAuthURL = regexp.MustCompile(`(?i)https://login\.tailscale\.com(?::443)?[/?][^\s\"'<>]*`)
	tailnetAuthKey = regexp.MustCompile(`tskey-[a-zA-Z0-9_-]+`)
)

func cleanLogMessage(message string) string {
	clean := logPrefix.ReplaceAllString(ansi.ReplaceAllString(message, ""), "")
	clean = tailnetAuthURL.ReplaceAllString(clean, "[Tailscale authentication URL redacted]")
	return tailnetAuthKey.ReplaceAllString(clean, "[Tailscale credential redacted]")
}

// logBuffer keeps the last entries under sequence numbers that never
// restart, so a reader can ask for what came after the last one it saw
// (RUNTIME_HOST §6). It outlives sessions: the lines explaining why a
// start failed are still there afterwards.
type logBuffer struct {
	mu      sync.Mutex
	entries []LogEntry
	start   int   // index of the oldest entry once the buffer is full
	nextSeq int64 // sequence of the next entry
	size    int
}

func newLogBuffer(size int) *logBuffer {
	return &logBuffer{size: size, nextSeq: 1}
}

func (b *logBuffer) add(level, message string) {
	b.mu.Lock()
	defer b.mu.Unlock()
	entry := LogEntry{
		Seq:     b.nextSeq,
		Time:    time.Now().UnixMilli(),
		Level:   level,
		Message: cleanLogMessage(message),
	}
	b.nextSeq++
	if len(b.entries) < b.size {
		b.entries = append(b.entries, entry)
		return
	}
	b.entries[b.start] = entry
	b.start = (b.start + 1) % b.size
}

// page returns up to limit entries after afterSeq.
func (b *logBuffer) page(afterSeq int64, limit int) LogPage {
	b.mu.Lock()
	defer b.mu.Unlock()
	if limit <= 0 || limit > b.size {
		limit = b.size
	}
	count := len(b.entries)
	oldest := b.nextSeq - int64(count)
	page := LogPage{Entries: []LogEntry{}, NextSeq: afterSeq}
	if afterSeq >= b.nextSeq-1 {
		// Nothing new (or a reader ahead of a restarted host).
		page.NextSeq = b.nextSeq - 1
		return page
	}
	first := afterSeq + 1
	if first < oldest {
		page.Dropped = oldest - first
		first = oldest
	}
	for seq := first; seq < b.nextSeq && len(page.Entries) < limit; seq++ {
		index := (b.start + int(seq-oldest)) % count
		page.Entries = append(page.Entries, b.entries[index])
		page.NextSeq = seq
	}
	return page
}
