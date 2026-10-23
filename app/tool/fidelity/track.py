"""Measure an animation in a screen recording and compare it to a V3 curve.

    adb shell screenrecord /sdcard/a.mp4   # perform the interaction, then pull it
    python3 tool/fidelity/track.py a.mp4 START_S DURATION_S CROP MODE TOTAL_MS X1 Y1 X2 Y2 [FROM TO]

CROP is an ffmpeg crop "w:h:x:y" in physical pixels (even sizes); SCALE (env,
default 3) is physical pixels per point. MODE:
  thumb  - centre of the longest bright (>=250) run on the crop's first row
           (switch / segmented thumbs).
  edge   - left end of the longest white (>=250, video-compressed) run, in points from the
           crop's left edge (page pushes: track a white cell of the moving page
           where the page underneath shows background).
  tint   - top of the first tint-blue (#007AFF) pixel down a narrow column crop,
           in points (sheets: track the 取消 label while the page behind dims).
FROM/TO give the start and end positions when they are off screen (pushes).
The start time is fitted to the samples, since frames quantise it.
Prints measured progress next to cubic-bezier(X1,Y1,X2,Y2) over TOTAL_MS.
Requires ffmpeg and Pillow.
"""
import os, subprocess, sys
from PIL import Image

video, start, dur, crop, mode, total = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), sys.argv[4], sys.argv[5], float(sys.argv[6])
x1, y1, x2, y2 = map(float, sys.argv[7:11])
scale = float(os.environ.get("SCALE", 3))  # physical pixels per point
cw, ch = (int(v) for v in crop.split(":")[:2])
# Raw frames with their real timestamps: works for constant-rate device
# captures and variable-rate ones (simulator `recordVideo`, `adb emu
# screenrecord`), and never drops frames that share a muxer timestamp.
raw = subprocess.run(["ffmpeg", "-v", "error", "-i", video, "-vf", f"crop={crop}",
                      "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                     check=True, capture_output=True).stdout
times = [float(x.split(",")[0]) for x in subprocess.run(
    ["ffprobe", "-v", "error", "-select_streams", "v", "-show_entries", "frame=pts_time",
     "-of", "csv=p=0", video], check=True, capture_output=True, text=True).stdout.split()]
size = cw * ch * 3
frames = [Image.frombytes("RGB", (cw, ch), raw[i:i + size]) for i in range(0, len(raw), size)]
if len(frames) != len(times):
    sys.exit(f"decoded {len(frames)} frames but found {len(times)} timestamps")

def bez(t, a, b): return 3 * a * t * (1 - t) ** 2 + 3 * b * t * t * (1 - t) + t ** 3
def curve(x):
    lo, hi = 0.0, 1.0
    for _ in range(50):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if bez(m, x1, x2) < x else (lo, m)
    return bez((lo + hi) / 2, y1, y2)

def thumb(im):
    w = im.size[0]; runs = []; s = None
    for x in range(w + 1):
        on = x < w and min(im.getpixel((x, 0))) >= 250
        if on and s is None: s = x
        if not on and s is not None: runs.append((s, x - 1)); s = None
    if not runs: return None
    a, b = max(runs, key=lambda r: r[1] - r[0]); return (a + b) / 2 / scale

def edge(im):
    w = im.size[0]; best = None; s = None
    for x in range(w + 1):
        on = x < w and min(im.getpixel((x, 0))) >= 250
        if on and s is None: s = x
        if not on and s is not None:
            if best is None or x - s > best[1] - best[0]: best = (s, x)
            s = None
    return best[0] / scale if best and best[1] - best[0] > 30 else None

def tint(im):
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b = im.getpixel((x, y))
            if b > 200 and r < 70 and 90 < g < 160:
                return y / scale
    return None

fn = {"thumb": thumb, "edge": edge, "tint": tint}[mode]
vals = [(tm, fn(im)) for tm, im in zip(times, frames) if start <= tm <= start + dur]
vals = [(t, v) for t, v in vals if v is not None]
v0, vend = (float(sys.argv[11]), float(sys.argv[12])) if len(sys.argv) > 12 else (vals[0][1], vals[-1][1])
moving = [(t, (v - v0) / (vend - v0)) for t, v in vals if 0.002 < (v - v0) / (vend - v0) < 0.998]
t1 = moving[0][0]

def err(shift):
    return sum((p - curve(min(max((t - t1 + shift) / total * 1000, 0), 1))) ** 2 for t, p in moving)

shift = min((s / 2000 for s in range(0, 400)), key=err)  # up to 200 ms before the first moving frame
t0 = t1 - shift
print(f"travel {vend - v0:.2f} pt, start fitted {shift * 1000:.1f} ms before first moving frame")
print("   ms  measured%  expected%")
worst = 0
for t, v in vals:
    ms = (t - t0) * 1000
    if -10 < ms < total + 150:
        m, e = (v - v0) / (vend - v0) * 100, curve(min(max(ms / total, 0), 1)) * 100
        worst = max(worst, abs(m - e))
        print(f"{ms:5.0f}  {m:8.1f}  {e:8.1f}")
print(f"max deviation {worst:.1f}% ({worst / 100 * abs(vend - v0):.1f} pt)")
