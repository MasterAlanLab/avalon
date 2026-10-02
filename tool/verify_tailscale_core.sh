#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
"$ROOT/tool/apply_tailscale_patch.sh"
cd "$ROOT/core"
go test .
go vet .
go test -tags with_gvisor .
go vet -tags with_gvisor .
go test -tags 'with_gvisor,no_tailscale' .
go vet -tags 'with_gvisor,no_tailscale' .
go test -race -tags with_gvisor .
cd Clash.Meta
go test -tags with_gvisor ./adapter/outbound ./dns ./tunnel
