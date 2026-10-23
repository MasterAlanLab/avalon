#!/bin/sh
# Capture the app at V3's frame size (390x844 pt @3x) on an Android emulator.
#   tool/fidelity/capture.sh OUT_DIR NAME [X Y]...   taps in logical points, then captures
# Run `capture.sh --setup` once before and `capture.sh --reset` after a session.
set -e
DEV=${ANDROID_SERIAL:-emulator-5554}
case "$1" in
  --setup) adb -s "$DEV" shell wm size 1170x2532; adb -s "$DEV" shell wm density 480; exit 0 ;;
  --reset) adb -s "$DEV" shell wm size reset; adb -s "$DEV" shell wm density reset; exit 0 ;;
esac
out=$1; name=$2; shift 2
mkdir -p "$out"
while [ $# -ge 2 ]; do adb -s "$DEV" shell input tap $(($1*3)) $(($2*3)); sleep 1.2; shift 2; done
sleep 1
adb -s "$DEV" exec-out screencap -p > "$out/$name.png"
