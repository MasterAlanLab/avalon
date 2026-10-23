#!/bin/sh
# D112: install/uninstall and CAP_NET_ADMIN on the real ordinary-user helper.
# All privilege changes occur in a disposable container, never on the host.
set -eu
cd "$(dirname "$0")"

architecture=$(docker info --format '{{.Architecture}}')
case "$architecture" in
  aarch64|arm64) goarch=arm64 ;;
  x86_64|amd64) goarch=amd64 ;;
  *) printf 'unsupported Docker architecture: %s\n' "$architecture" >&2; exit 1 ;;
esac
work="$PWD/out/linux-helper-install"
mkdir -p "$work"
CGO_ENABLED=0 GOOS=linux GOARCH=$goarch go build -trimpath -buildvcs=false \
  -tags "$(cat BUILD_TAGS)" -ldflags '-checklinkname=0' \
  -o "$work/avalon-helper" ./cmd/avalon-helper

image=avalon-helper-install-check
docker build -q -t "$image" -f - tool <<'DOCKERFILE'
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libcap2-bin python3 ca-certificates && rm -rf /var/lib/apt/lists/*
DOCKERFILE

# Serve an innocuous target on this host, with a fresh port for concurrent runs.
# Only this tracked process is terminated; no installed host service is changed.
rm -f -- "$work/port"
python3 -u - "$work/port" <<'PYTHON' >"$work/http.log" 2>&1 &
import http.server
from pathlib import Path
import sys
class Target(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'avalon Linux helper acceptance')
    def log_message(self, *args):
        pass
server = http.server.HTTPServer(('0.0.0.0', 0), Target)
Path(sys.argv[1]).write_text(str(server.server_port))
server.serve_forever()
PYTHON
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT
trap 'exit 1' HUP INT TERM
attempt=0
while [ ! -s "$work/port" ]; do
  attempt=$((attempt + 1))
  [ "$attempt" -lt 100 ] || { printf 'HTTP test target did not start\n' >&2; exit 1; }
  sleep 0.05
done
port=$(cat "$work/port")
docker run --rm --cap-add NET_ADMIN --cap-add SYS_PTRACE --device /dev/net/tun \
  --add-host host.docker.internal:host-gateway \
  -e AVALON_TUN_TARGET="http://host.docker.internal:$port/" \
  -v "$work/avalon-helper:/fixture/avalon-helper:ro" \
  -v "$PWD/install_linux_helper.sh:/fixture/install_linux_helper.sh:ro" \
  -v "$PWD/tool/linux_helper_install_test.py:/fixture/linux_helper_install_test.py:ro" \
  "$image" python3 /fixture/linux_helper_install_test.py
