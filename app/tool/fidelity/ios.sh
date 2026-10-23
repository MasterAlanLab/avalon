#!/bin/sh
# Drive the gallery on the booted iOS simulator through gallery/dev_remote.dart
# (the simulator has screenshots and video, but no input injection).
#
#   ios.sh launch [Runner.app]        (install and) relaunch with the remote on
#   ios.sh do CMD...                  run remote commands, e.g. "tap 341 800"
#   ios.sh shot OUT NAME [CMD]...     run commands, then screenshot OUT/NAME.png
#
# Coordinates are logical points. SETTLE (seconds, default 1) is the pause
# after each command. SIM selects the simulator (default: booted).
set -e
BUNDLE=app.getavalon.avalon
SIM=${SIM:-booted}
container() { xcrun simctl get_app_container "$SIM" $BUNDLE data; }

if [ "$1" = launch ]; then
  [ -n "$2" ] && xcrun simctl install "$SIM" "$2"
  xcrun simctl terminate "$SIM" $BUNDLE 2>/dev/null || true
  dir=$(container)/tmp
  mkdir -p "$dir"
  rm -f "$dir/av_remote.out"
  : > "$dir/av_remote.in"   # marker: switches the remote on at startup
  xcrun simctl launch "$SIM" $BUNDLE >/dev/null
  i=0
  while [ ! -f "$dir/av_remote.out" ]; do
    i=$((i + 1)); [ $i -gt 200 ] && { echo "remote did not start" >&2; exit 1; }
    sleep 0.1
  done
  sleep 1.5
  exit 0
fi

dir=$(container)/tmp
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
    xcrun simctl io "$SIM" screenshot "$out/$name.png" >/dev/null 2>&1 ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
