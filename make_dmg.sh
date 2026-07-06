#!/bin/bash
set -e

APP_NAME="SoundPaper"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
DMG_PATH="$SCRIPT_DIR/docs/$APP_NAME.dmg"
STAGING_DIR="$SCRIPT_DIR/.dmg-staging"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "$APP_BUNDLE not found. Run build_app.sh release first." >&2
    exit 1
fi

echo "Staging DMG contents..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating $APP_NAME.dmg..."
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "Done: $DMG_PATH"
