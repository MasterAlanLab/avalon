package bridge

import (
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestDayTotals(t *testing.T) {
	dir := t.TempDir()
	clock := time.Date(2026, 10, 10, 15, 0, 0, 0, time.UTC)
	open := func() *dayTotals {
		d := newDayTotals(dir)
		d.now = func() time.Time { return clock }
		return d
	}

	d := open()
	// A session counts up from zero.
	if up, down := d.sample(100, 1000); up != 100 || down != 1000 {
		t.Fatalf("first sample: %d %d", up, down)
	}
	if up, down := d.sample(150, 1800); up != 150 || down != 1800 {
		t.Fatalf("second sample: %d %d", up, down)
	}
	// The next session starts from zero again and adds to the day.
	d.sessionEnded()
	if up, down := d.sample(10, 20); up != 160 || down != 1820 {
		t.Fatalf("after a restart: %d %d", up, down)
	}
	d.save()

	// A restarted host reads the day back.
	d = open()
	if up, down := d.totals(); up != 160 || down != 1820 {
		t.Fatalf("after reopening: %d %d", up, down)
	}

	// The day follows the device's clock, not UTC: at 15:00 UTC it is
	// already tomorrow ten hours east.
	d.setOffset(10 * time.Hour)
	if up, down := d.totals(); up != 0 || down != 0 {
		t.Fatalf("a new local day starts at zero: %d %d", up, down)
	}
	d.sample(5, 6)
	d.save()
	var saved dayFile
	raw, _ := os.ReadFile(filepath.Join(dir, "traffic-today.json"))
	if json.Unmarshal(raw, &saved) != nil || saved != (dayFile{Date: "2026-10-11", Up: 5, Down: 6}) {
		t.Fatalf("saved: %s", raw)
	}

	// Midnight passes while a session runs: only what comes after counts.
	clock = clock.Add(24 * time.Hour)
	if up, down := d.sample(8, 10); up != 3 || down != 4 {
		t.Fatalf("across midnight: %d %d", up, down)
	}
}

func TestTodayInSnapshots(t *testing.T) {
	state := t.TempDir()
	engine := NewEngine(NewDesktopService(t.TempDir(), t.TempDir()), "test", state)
	t.Cleanup(engine.Close)
	port := freePort(t)
	server := origin(t)
	session := mustStart(t, engine, port)

	get := func() {
		t.Helper()
		response, err := through(port).Get(server.URL)
		if err != nil {
			t.Fatal(err)
		}
		_, _ = io.Copy(io.Discard, response.Body)
		response.Body.Close()
	}
	get()
	first := snapshot(t, engine)
	if first.TodayDown < first.DownTotal || first.DownTotal == 0 {
		t.Fatalf("today includes the session: %+v", first)
	}

	// Across a reload the session starts over; the day goes on.
	request := map[string]any{"sessionId": session, "plan": json.RawMessage(plan(port, "")), "planHash": "h2"}
	if err := call(t, engine, "reload", request, nil); err != nil {
		t.Fatal(err)
	}
	get()
	second := snapshot(t, engine)
	if second.DownTotal >= second.TodayDown || second.TodayDown < first.TodayDown+second.DownTotal {
		t.Fatalf("after a reload: first %+v, second %+v", first, second)
	}

	// Stopping writes the day down; a stopped host still reports it.
	if err := call(t, engine, "stop", stopRequest{RequestID: "s"}, nil); err != nil {
		t.Fatal(err)
	}
	stopped := snapshot(t, engine)
	if stopped.TodayDown != second.TodayDown {
		t.Fatalf("after stop: %d, before %d", stopped.TodayDown, second.TodayDown)
	}
	if _, err := os.Stat(filepath.Join(state, "traffic-today.json")); err != nil {
		t.Fatalf("the day should be saved at stop: %v", err)
	}
}
