#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SOURCE="$ROOT/core/Clash.Meta"
PATCH="$ROOT/core/patches/tailscale-v2.patch"
test "$(git -C "$SOURCE" rev-parse HEAD)" = 0f7f05adff5e2c49775a112dcfe05a6aa36fda0c
if git -C "$SOURCE" apply --reverse --check "$PATCH" 2>/dev/null; then
  echo 'Tailscale v2 patch already applied'
else
  git -C "$SOURCE" apply --check "$PATCH"
  git -C "$SOURCE" apply "$PATCH"
  echo 'Tailscale v2 patch applied'
fi
