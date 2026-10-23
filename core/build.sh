#!/bin/sh
# Builds the Core Bridge for each host (docs/RUNTIME_HOST.md §8).
#
#   build.sh tools            install the pinned gomobile into .bin/
#   build.sh test             run the Go tests against the real core
#   build.sh android [ABIS]   out/avalon-core.aar   (default: all four ABIs)
#   build.sh apple [TARGETS]  out/AvalonCore.xcframework
#   build.sh helper OS ARCH   out/avalon-helper-OS-ARCH[.exe]
#
# Flags follow sing-box's own release build (cmd/internal/build_libbox):
# the feature tags in BUILD_TAGS, and the linker flags below.
set -eu
cd "$(dirname "$0")"

GOMOBILE_VERSION=v0.1.13 # as sing-box's Makefile pins it
TAGS=$(cat BUILD_TAGS)
VERSION=$(go list -m -f '{{.Version}}' github.com/sagernet/sing-box | sed 's/^v//')
LDFLAGS="-X github.com/sagernet/sing-box/constant.Version=$VERSION -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0 -s -w -buildid="
PACKAGES="./mobile github.com/sagernet/sing-box/experimental/libbox"
PATH="$PWD/.bin:$PATH"
export PATH
mkdir -p out

case "${1:-}" in
tools)
  GOBIN="$PWD/.bin" go install \
    "github.com/sagernet/gomobile/cmd/gomobile@$GOMOBILE_VERSION" \
    "github.com/sagernet/gomobile/cmd/gobind@$GOMOBILE_VERSION"
  ;;
test)
  go vet -tags "$TAGS" ./...
  go test -tags "$TAGS" -ldflags "-checklinkname=0" -count=1 ./...
  ;;
android)
  # The ABIs Flutter builds release engines for; 32-bit x86 has none.
  abis=${2:-arm64,arm,amd64}
  targets=$(echo "$abis" | sed 's/[^,]*/android\/&/g')
  : "${ANDROID_HOME:=$HOME/Library/Android/sdk}"
  : "${ANDROID_NDK_HOME:=$(ls -d "$ANDROID_HOME"/ndk/* | sort | tail -1)}"
  export ANDROID_HOME ANDROID_NDK_HOME
  gomobile bind -o out/avalon-core.aar -target "$targets" -androidapi 23 \
    -javapkg=dev.avalon.core -libname=avaloncore \
    -trimpath -buildvcs=false -ldflags "$LDFLAGS" -tags "$TAGS" $PACKAGES
  ;;
apple)
  targets=${2:-ios,iossimulator,macos}
  gomobile bind -o out/AvalonCore.xcframework -target "$targets" \
    -libname=avaloncore -iosversion=15.0 -macosversion=13.0 \
    -tags-not-macos=with_low_memory \
    -trimpath -buildvcs=false -ldflags "$LDFLAGS" \
    -tags "$TAGS,with_dhcp,grpcnotrace" $PACKAGES
  ;;
helper)
  os=$2 arch=$3
  suffix=""
  [ "$os" = windows ] && suffix=".exe"
  CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -trimpath -buildvcs=false \
    -ldflags "$LDFLAGS" -tags "$TAGS" \
    -o "out/avalon-helper-$os-$arch$suffix" ./cmd/avalon-helper
  if [ "$os" = windows ]; then
    python3 tool/seal_windows_helper.py "out/avalon-helper-$os-$arch$suffix"
  fi
  ;;
*)
  sed -n '2,9p' "$0"
  exit 2
  ;;
esac
