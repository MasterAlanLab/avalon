#!/bin/sh
# Checks the plans Avalon's compiler writes against the pinned sing-box:
# compiles the fixtures with the Dart compiler, then has the core load each
# plan (what `sing-box check` does).
set -eu
cd "$(dirname "$0")"
plans=$(mktemp -d)
trap 'rm -rf "$plans"' EXIT
(cd ../packages/av_core && AV_EXPORT_PLANS="$plans" dart test test/compiler_test.dart >/dev/null)
AVALON_PLANS="$plans" go test -tags "$(cat BUILD_TAGS)" -ldflags "-checklinkname=0" \
  -count=1 -run TestCompilerPlans -v ./bridge/
