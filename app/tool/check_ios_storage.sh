#!/bin/sh
# Isolated macOS filesystem checks for the iOS host's shared storage.
# No Xcode application build, simulator installation or VPN is involved.
set -eu
tool_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
app_dir=$(CDPATH= cd -- "$tool_dir/.." && pwd)
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/avalon-ios-storage-check.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT HUP INT TERM

xcrun swiftc \
  "$app_dir/ios/Shared/HostStorage.swift" \
  "$app_dir/ios/Tests/HostStorageChecks.swift" \
  -o "$check_dir/storage-check"
AVALON_STORAGE_CHECK_DIR="$check_dir" "$check_dir/storage-check"
