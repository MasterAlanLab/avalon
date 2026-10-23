#!/bin/sh
# iOS links the Core Bridge for its test-only app instance and Packet Tunnel;
# macOS links it only in the System Extension. Reject stale native binaries.
set -eu

tool_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
core_dir=$(CDPATH= cd -- "$tool_dir/../../core" && pwd)
framework="$core_dir/out/AvalonCore.xcframework"

fail() {
  echo "error: $1 Run core/build.sh apple before building the Apple application." >&2
  exit 1
}

[ -f "$framework/Info.plist" ] || fail "The Core Bridge is missing."

# Xcode checks the slice it is linking. A manual invocation checks all
# slices present in the default Apple build, including macOS.
case "${PLATFORM_NAME:-}" in
  iphoneos) slices="ios-arm64" ;;
  iphonesimulator) slices="ios-arm64_x86_64-simulator" ;;
  macosx) slices="macos-arm64_x86_64" ;;
  "") slices="ios-arm64 ios-arm64_x86_64-simulator macos-arm64_x86_64" ;;
  *) fail "Unsupported Apple platform: $PLATFORM_NAME." ;;
esac

for slice in $slices; do
  binary="$framework/$slice/AvalonCore.framework/AvalonCore"
  [ -f "$binary" ] || fail "The Core Bridge lacks its $slice slice."
  newer=$(find "$core_dir/bridge" "$core_dir/mobile" -type f \
    -name '*.go' ! -name '*_test.go' -newer "$binary" -print)
  [ -z "$newer" ] || fail "The Core Bridge is older than its Go sources."
  for source in go.mod go.sum BUILD_TAGS build.sh; do
    [ ! "$core_dir/$source" -nt "$binary" ] || \
      fail "The Core Bridge is older than $source."
  done
done
