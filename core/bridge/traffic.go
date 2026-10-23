package bridge

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// dayTotals adds up traffic since local midnight across sessions
// (RUNTIME_HOST §6). The core counts per session, from zero; this keeps
// the running sum for the day in the host's state directory so that it
// survives restarts of the session and of the host. At most the last
// interval is lost when the host is killed.
type dayTotals struct {
	mu   sync.Mutex
	path string // empty: kept in memory only
	now  func() time.Time
	// The device's offset from UTC. Go cannot tell the local zone on
	// Android, so the app says it when it starts a session.
	offset time.Duration

	date     string
	up, down int64
	// The session's own totals when last sampled.
	lastUp, lastDown int64
	dirty            bool
}

type dayFile struct {
	Date string `json:"date"`
	Up   int64  `json:"up"`
	Down int64  `json:"down"`
}

func newDayTotals(stateDir string) *dayTotals {
	d := &dayTotals{now: time.Now}
	if stateDir != "" {
		d.path = filepath.Join(stateDir, "traffic-today.json")
		if raw, err := os.ReadFile(d.path); err == nil {
			var saved dayFile
			if json.Unmarshal(raw, &saved) == nil {
				d.date, d.up, d.down = saved.Date, saved.Up, saved.Down
			}
		}
	}
	return d
}

func (d *dayTotals) today() string {
	return d.now().UTC().Add(d.offset).Format("2006-01-02")
}

// roll starts a new day when the date has changed. Called with mu held.
func (d *dayTotals) roll() {
	if today := d.today(); today != d.date {
		d.date, d.up, d.down = today, 0, 0
		d.dirty = true
	}
}

func (d *dayTotals) setOffset(offset time.Duration) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.offset = offset
	d.roll()
}

// sample takes the session's totals so far and returns today's.
func (d *dayTotals) sample(sessionUp, sessionDown int64) (up, down int64) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.roll()
	if deltaUp, deltaDown := sessionUp-d.lastUp, sessionDown-d.lastDown; deltaUp > 0 || deltaDown > 0 {
		if deltaUp > 0 {
			d.up += deltaUp
		}
		if deltaDown > 0 {
			d.down += deltaDown
		}
		d.dirty = true
	}
	d.lastUp, d.lastDown = sessionUp, sessionDown
	return d.up, d.down
}

// sessionEnded: the next session counts from zero again.
func (d *dayTotals) sessionEnded() {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.lastUp, d.lastDown = 0, 0
}

func (d *dayTotals) totals() (up, down int64) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.roll()
	return d.up, d.down
}

// save writes the day's sums when they changed.
func (d *dayTotals) save() {
	d.mu.Lock()
	defer d.mu.Unlock()
	if !d.dirty || d.path == "" {
		return
	}
	raw, _ := json.Marshal(dayFile{Date: d.date, Up: d.up, Down: d.down})
	temp := d.path + ".tmp"
	if os.WriteFile(temp, raw, 0o600) == nil && os.Rename(temp, d.path) == nil {
		d.dirty = false
	}
}
