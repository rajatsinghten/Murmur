#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

CONFIGURATION="${1:-release}"

swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BIN="$BIN_DIR/Murmur"

APP="build/Murmur.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Murmur"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Build an .icns app icon from the Murmur.png at the repo root.
ICONSET="build/Murmur.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

sips -z 16 16     Murmur.png --out "$ICONSET/icon_16x16.png"       >/dev/null
sips -z 32 32     Murmur.png --out "$ICONSET/icon_16x16@2x.png"    >/dev/null
sips -z 32 32     Murmur.png --out "$ICONSET/icon_32x32.png"       >/dev/null
sips -z 64 64     Murmur.png --out "$ICONSET/icon_32x32@2x.png"    >/dev/null
sips -z 128 128   Murmur.png --out "$ICONSET/icon_128x128.png"     >/dev/null
sips -z 256 256   Murmur.png --out "$ICONSET/icon_128x128@2x.png"  >/dev/null
sips -z 256 256   Murmur.png --out "$ICONSET/icon_256x256.png"     >/dev/null
sips -z 512 512   Murmur.png --out "$ICONSET/icon_256x256@2x.png"  >/dev/null
sips -z 512 512   Murmur.png --out "$ICONSET/icon_512x512.png"     >/dev/null
sips -z 1024 1024 Murmur.png --out "$ICONSET/icon_512x512@2x.png"  >/dev/null

iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

# Ad-hoc sign the assembled bundle so Info.plist, the icon and the executable
# are bound together. This keeps Gatekeeper from reporting the app as "damaged".
codesign --force --sign - "$APP"

echo "Built $APP"
