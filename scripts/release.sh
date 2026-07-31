#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== Building universal binary (arm64 + x86_64) ==="
arch -arm64 swift build -c release --build-path .build/arm64
arch -x86_64 swift build -c release --build-path .build/x86_64

mkdir -p .build/universal
lipo -create \
  .build/arm64/release/EarthWallpaper \
  .build/x86_64/release/EarthWallpaper \
  -output .build/universal/EarthWallpaper

echo "=== Creating .app bundle ==="
APP="EarthWallpaper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/universal/EarthWallpaper "$APP/Contents/MacOS/"
cp .build/arm64/release/EarthWallpaper_EarthWallpaper.bundle/PhotoIDs.json "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EarthWallpaper</string>
    <key>CFBundleIdentifier</key>
    <string>com.earthwallpaper.app</string>
    <key>CFBundleName</key>
    <string>Google Earth Wallpaper</string>
    <key>CFBundleDisplayName</key>
    <string>Google Earth Wallpaper</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"

echo "=== Packaging ZIP ==="
PUBLISH_DIR="/tmp/EarthWallpaper"
rm -rf "$PUBLISH_DIR"
mkdir -p "$PUBLISH_DIR"
cp -R "$APP" "$PUBLISH_DIR/"
cp scripts/install.sh "$PUBLISH_DIR/"

ZIP="$PROJECT_DIR/EarthWallpaper.zip"
rm -f "$ZIP"
cd /tmp && ditto -c -k --keepParent EarthWallpaper "$ZIP"
cd "$PROJECT_DIR"

echo "=== Creating Release ==="
gh release create "v$VERSION" \
    --title "Google Earth Wallpaper v$VERSION" \
    --notes "## Install / 安装

1. Download \`EarthWallpaper.zip\` and unzip
2. Open **Terminal** and run:
   \`\`\`bash
   cd ~/Downloads/EarthWallpaper && bash install.sh
   \`\`\`

Supports Apple Silicon (M1/M2/M3/M4) and Intel Macs.  
支持 Apple Silicon 和 Intel 芯片。

macOS 14.0+ required." \
    "$ZIP"

echo "=== Done ==="
echo "Release: https://github.com/Wangtaotaoo/GoogleEarthWallpaper/releases/tag/v$VERSION"
