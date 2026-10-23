#!/bin/sh
# Real GNOME gsettings/DBus acceptance in a disposable ordinary-user container.
# The production Dart backend runs on the host test runner, while each native
# command is transported to this container. Host OS proxy settings are untouched.
set -eu
repo=$(CDPATH= cd -- "$(dirname "$0")/../../.." && pwd)
docker_command=$(command -v docker)
flutter_command=${FLUTTER:-flutter}
container=
cleanup() {
  if [ -n "$container" ]; then "$docker_command" rm -f "$container" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

image=avalon-gnome-proxy-check
"$docker_command" build -q -t "$image" -f - "$repo/core/tool" <<'DOCKERFILE'
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends dbus dconf-gsettings-backend gsettings-desktop-schemas libglib2.0-bin passwd && rm -rf /var/lib/apt/lists/*
RUN useradd -u 1000 -m -d /home/avalon-test avalon-test && chmod 0700 /home/avalon-test
DOCKERFILE
container=$("$docker_command" run -d --user 1000:1000 \
  -e HOME=/home/avalon-test -e XDG_RUNTIME_DIR=/home/avalon-test \
  "$image" dbus-daemon --session --address=unix:path=/home/avalon-test/bus --nofork --nopidfile)
attempt=0
while ! "$docker_command" exec "$container" test -S /home/avalon-test/bus 2>/dev/null; do
  if [ "$("$docker_command" inspect --format '{{.State.Running}}' "$container")" != true ]; then
    "$docker_command" logs "$container" >&2
    printf 'DBus session exited before opening its socket\n' >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  [ "$attempt" -lt 100 ] || { printf 'DBus session did not start\n' >&2; exit 1; }
  sleep 0.05
done
cd "$repo/app"
AVALON_GNOME_CONTAINER=$container AVALON_DOCKER=$docker_command \
  "$flutter_command" test --no-pub test/platform/gnome_system_proxy_integration_test.dart
