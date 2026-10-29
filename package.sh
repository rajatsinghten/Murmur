#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

./build.sh release

APP="build/Murmur.app"
STAGING="build/dmg-staging"
DMG_RW="build/Murmur-rw.dmg"
DMG="build/Murmur.dmg"
VOLNAME="Murmur"

rm -rf "$STAGING" "$DMG_RW" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/Murmur.app"
ln -s /Applications "$STAGING/Applications"

# Build an uncompressed image, arrange it in Finder, then compress it.
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -ov -format UDRW "$DMG_RW" >/dev/null

MOUNT_POINT="$(hdiutil attach "$DMG_RW" -readwrite -nobrowse | grep -o '/Volumes/[^ ]*' | head -1)"

# Best-effort layout. If Finder automation is not permitted yet, the DMG still
# contains both the app and the Applications shortcut.
osascript <<EOF >/dev/null 2>&1 || true
tell application "Finder"
    tell disk "$VOLNAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set position of item "Murmur.app" to {140, 160}
        set position of item "Applications" to {360, 160}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

hdiutil detach "$MOUNT_POINT" >/dev/null

hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -rf "$STAGING" "$DMG_RW"

echo "Built $DMG"
