#!/bin/sh
# Connects through a real sing-box server with every protocol, transport
# and security combination Avalon offers (docs/STATUS.md#runtime-validation).
# Needs Docker. The server is the official image at the pinned version;
# the client is the bridge running the plan Avalon's compiler writes.
set -eu
cd "$(dirname "$0")"

VERSION=$(go list -m -f '{{.Version}}' github.com/sagernet/sing-box)
IMAGE="ghcr.io/sagernet/sing-box:$VERSION"
# Override these to run beside other servers using the same ports.
NAME=${S5_NAME:-avalon-s5}
MIXED_PORT=${S5_MIXED_PORT:-17900}
BASE_PORT=${S5_BASE_PORT:-21000}
work=${S5_WORK:-"$PWD/out/s5"}

rm -rf "$work" && mkdir -p "$work"
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

# A certificate for this run only, a Reality key pair, and an empty rule
# set so that nothing is downloaded while the plan starts.
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
  -keyout "$work/key.pem" -out "$work/cert.pem" -days 2 \
  -subj "/CN=s5.avalon.test" -addext "subjectAltName=DNS:s5.avalon.test" 2>/dev/null
chmod 644 "$work/key.pem"
keys=$(docker run --rm "$IMAGE" generate reality-keypair)
private=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
public=$(echo "$keys" | awk '/PublicKey/ {print $2}')
echo '{"version": 1, "rules": []}' > "$work/geosite-cn.json"
docker run --rm -v "$work":/etc/s5 "$IMAGE" rule-set compile \
  /etc/s5/geosite-cn.json -o /etc/s5/geosite-cn.srs

(cd ../packages/av_core && dart run tool/protocol_matrix.dart \
  "$work" "$MIXED_PORT" "$BASE_PORT" "$private" "$public")
count=$(grep -o '"name"' "$work/cases.json" | wc -l | tr -d ' ')
last=$((BASE_PORT + count - 1))

# Port hopping: the extra ports the server listens on (UDP).
hops=""
while IFS= read -r mapping; do
  [ -n "$mapping" ] && hops="$hops -p 127.0.0.1:$mapping/udp"
done < "$work/hop_ports.txt"
# shellcheck disable=SC2086
docker run -d --name "$NAME" -v "$work":/etc/s5:ro \
  -p "127.0.0.1:$BASE_PORT-$last:$BASE_PORT-$last" \
  -p "127.0.0.1:$BASE_PORT-$last:$BASE_PORT-$last/udp" $hops \
  "$IMAGE" run -c /etc/s5/server.json >/dev/null
for _ in $(seq 1 50); do
  docker logs "$NAME" 2>&1 | grep -q "sing-box started" && break
  sleep 0.2
done
docker logs "$NAME" 2>&1 | grep -q "sing-box started" || {
  echo "the server did not start:" >&2
  docker logs "$NAME" 2>&1 | tail -20 >&2
  exit 1
}

AVALON_MATRIX="$work" go test -tags "$(cat BUILD_TAGS)" -ldflags "-checklinkname=0" \
  -count=1 -run TestProtocolMatrix -v ./bridge/ > "$work/test.log" 2>&1 || {
  grep -E "^\s*(--- |protocols_test|FAIL)" "$work/test.log" >&2
  docker logs "$NAME" > "$work/server.log" 2>&1
  exit 1
}
grep -E "^\s*--- " "$work/test.log"

# Each case must have arrived at its own inbound on the server.
docker logs "$NAME" > "$work/server.log" 2>&1
missed=0
i=0
while [ "$i" -lt "$count" ]; do
  # A hopping case may arrive on any port of its range.
  grep -qE "\[in-$i(-h[0-9]+)?\]: inbound connection" "$work/server.log" || {
    echo "the server saw nothing on inbound in-$i" >&2
    missed=1
  }
  i=$((i + 1))
done
[ "$missed" -eq 0 ] && echo "all $count cases reached their own inbound on sing-box $VERSION"
exit "$missed"
