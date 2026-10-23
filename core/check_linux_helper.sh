#!/bin/sh
# Spike S4, Linux: the helper serves the bridge on a Unix socket, opens a
# TUN interface when it has CAP_NET_ADMIN and says so when it has not.
# Needs Docker; runs the helper's tests in a Linux container for this
# machine's architecture.
set -eu
cd "$(dirname "$0")"

arch=$(docker info --format '{{.Architecture}}')
case "$arch" in
  aarch64|arm64) goarch=arm64 ;;
  x86_64|amd64) goarch=amd64 ;;
  *) echo "unsupported Docker architecture $arch" >&2; exit 1 ;;
esac
work="$PWD/out/s4-linux"
rm -rf "$work" && mkdir -p "$work"
GOOS=linux GOARCH=$goarch CGO_ENABLED=0 go test -c -o "$work/helper.test" \
  -tags "$(cat BUILD_TAGS)" -ldflags "-checklinkname=0" ./cmd/avalon-helper/

# Where requests through the tunnel go: a small server on this machine.
port=18765
python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT
sleep 1

image=debian:bookworm-slim
echo "== as root with CAP_NET_ADMIN and /dev/net/tun"
docker run --rm --cap-add NET_ADMIN --device /dev/net/tun \
  -e AVALON_TUN_TARGET="http://host.docker.internal:$port/" \
  -v "$work":/s4:ro "$image" /s4/helper.test -test.v -test.count=1 2>&1 \
  | grep -E "^(=== RUN|--- |PASS|FAIL|ok|\s+\w+_test.go)" 
echo "== as an unprivileged user"
docker run --rm --user 65534:65534 -e AVALON_TUN_EXPECT_NONE=1 -e HOME=/tmp \
  -v "$work":/s4:ro "$image" /s4/helper.test -test.v -test.count=1 2>&1 \
  | grep -E "^(=== RUN|--- |PASS|FAIL|ok|\s+\w+_test.go)"
