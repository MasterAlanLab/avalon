#!/bin/sh
# Drive the macOS desktop gallery through gallery/dev_remote.dart and
# capture only its window (needs Screen Recording permission for the terminal).
#
#   mac.sh launch [Avalon.app]        relaunch with the remote on
#   mac.sh do CMD...                  run remote commands, e.g. "tap 62 213"
#   mac.sh shot OUT NAME [CMD]...     run commands, then capture OUT/NAME.png
#
# Captures are converted from the display profile to sRGB. Coordinates are
# logical points from the window's top-left. SETTLE as in ios.sh.
set -e
here=$(cd "$(dirname "$0")" && pwd)
APP=${2:-$here/../../build/macos/Build/Products/Debug/Avalon.app}
dir=$HOME/Library/Containers/app.getavalon.avalon/Data/tmp   # sandboxed temp dir
winid=$here/.winid
[ "$winid" -nt "$here/winid.swift" ] || swiftc -O "$here/winid.swift" -o "$winid"

# The development build only, by its path: an installed Avalon has the
# same process name and must never be touched.
exe=$APP/Contents/MacOS/Avalon
devpid() { pgrep -f "^$exe" | head -1; }

if [ "$1" = launch ]; then
  pkill -f "^$exe" 2>/dev/null || true
  mkdir -p "$dir"
  rm -f "$dir/av_remote.out"
  : > "$dir/av_remote.in"   # marker: switches the remote on at startup
  "$exe" > /dev/null 2>&1 &
  i=0
  while [ ! -f "$dir/av_remote.out" ]; do
    i=$((i + 1)); [ $i -gt 200 ] && { echo "remote did not start" >&2; exit 1; }
    sleep 0.1
  done
  sleep 2
  exit 0
fi

run() {
  echo "$1" >> "$dir/av_remote.in"
  want=$(wc -l < "$dir/av_remote.in" | tr -d ' ')
  i=0
  until [ "$(tr -d ' \n' < "$dir/av_remote.out")" = "$want" ]; do
    i=$((i + 1)); [ $i -gt 400 ] && { echo "timeout: $1" >&2; exit 1; }
    sleep 0.05
  done
  sleep "${SETTLE:-1}"
}

case "$1" in
  do) shift; for c in "$@"; do run "$c"; done ;;
  shot)
    out=$2; name=$3; shift 3
    mkdir -p "$out"
    for c in "$@"; do run "$c"; done
    screencapture -x -o -l "$("$winid" "$(devpid)")" "$out/$name.png"
    sips -m "/System/Library/ColorSync/Profiles/sRGB Profile.icc" "$out/$name.png" >/dev/null ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
