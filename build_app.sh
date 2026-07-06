#!/bin/bash
set -e

APP_NAME="SoundPaper"
BUILD_CONFIG="${1:-debug}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"

if [ "$BUILD_CONFIG" = "release" ]; then
    # Universal binary (Apple Silicon + Intel) for distribution.
    BUILD_DIR="$SCRIPT_DIR/.build/apple/Products/Release"
    echo "Building (release, universal arm64 + x86_64)..."
    swift build -c release --arch arm64 --arch x86_64 --package-path "$SCRIPT_DIR"
else
    BUILD_DIR="$SCRIPT_DIR/.build/arm64-apple-macosx/$BUILD_CONFIG"
    echo "Building ($BUILD_CONFIG)..."
    swift build -c "$BUILD_CONFIG" --package-path "$SCRIPT_DIR"
fi

echo "Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$RESOURCE_BUNDLE/Contents/Resources" ]; then
    RESOURCE_BUNDLE="$RESOURCE_BUNDLE/Contents/Resources"
fi
cp "$RESOURCE_BUNDLE/"* "$APP_BUNDLE/Contents/Resources/"

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.siddharth.soundpaper</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Code signing (stable local identity)..."
signed=0
for attempt in 1 2 3 4 5; do
    xattr -cr "$APP_BUNDLE"
    if codesign --force --sign "SoundPaperCert" "$APP_BUNDLE"; then
        signed=1
        break
    fi
    sleep 1
done
if [ "$signed" -ne 1 ]; then
    echo "Code signing failed after retries." >&2
    exit 1
fi

echo "Done: $APP_BUNDLE"
echo "Run with: open \"$APP_BUNDLE\""
