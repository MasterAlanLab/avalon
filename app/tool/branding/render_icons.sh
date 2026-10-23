#!/bin/sh
# Renders the icons that are generated from the brand sources in
# app/branding/ (docs/UI_DESIGN_SYSTEM.md §5): iOS's app icons and the
# desktop tray icons. Needs rsvg-convert and Python with Pillow. The
# Android, macOS and Windows app icons were rendered with the brand
# package and are kept as they are.
#
#   app/tool/branding/render_icons.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
app=$here/../..
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# iOS masks the tile itself and wants a full-bleed square without
# transparency: the desktop geometry (the larger mark) with square corners.
sed 's/rx="230"/rx="0"/' "$app/branding/desktop_icon.svg" > "$work/ios.svg"
out=$app/ios/Runner/Assets.xcassets/AppIcon.appiconset
for size in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
  rsvg-convert -w "$size" -h "$size" -b '#17191D' "$work/ios.svg" -o "$work/$size.png"
done
python3 - "$work" "$out" <<'PY'
import sys
from PIL import Image
work, out = sys.argv[1], sys.argv[2]
names = {
    'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60, 'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120, 'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180, 'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152, 'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}
for name, size in names.items():
    # The App Store refuses icons with an alpha channel.
    Image.open(f'{work}/{size}.png').convert('RGB').save(f'{out}/{name}', optimize=True)
PY
echo "iOS icons written to $out"

# Tray and menu bar: idle (grey) and connected (saffron), from the status
# marks; PNG for macOS and Linux, ICO for Windows.
tray=$app/assets/tray
mkdir -p "$tray"
rsvg-convert -w 64 -h 64 "$app/branding/status/status_1.svg" -o "$tray/idle.png"
rsvg-convert -w 64 -h 64 "$app/branding/status/status_2.svg" -o "$tray/running.png"
python3 - "$tray" <<'PY'
import sys
from PIL import Image
tray = sys.argv[1]
for name in ('idle', 'running'):
    Image.open(f'{tray}/{name}.png').save(
        f'{tray}/{name}.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48)])
PY
echo "tray icons written to $tray"

