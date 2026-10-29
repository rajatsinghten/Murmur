#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

./build.sh release

APP="build/Murmur.app"
DMG="build/Murmur.dmg"

rm -f "$DMG"
hdiutil create -volname "Murmur" -srcfolder "$APP" -ov -format UDZO "$DMG"

echo "Built $DMG"
