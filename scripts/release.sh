#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/arm64-apple-macosx/release"
APP_DIR="$PROJECT_DIR/EarthWallpaper.app"
ZIP_PATH="$PROJECT_DIR/EarthWallpaper.zip"

echo "=== Building release ==="
cd "$PROJECT_DIR"
swift build -c release

echo "=== Creating .app bundle ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/EarthWallpaper" "$APP_DIR/Contents/MacOS/"
cp -R "$BUILD_DIR/EarthWallpaper_EarthWallpaper.bundle" "$APP_DIR/Contents/Resources/"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EarthWallpaper</string>
    <key>CFBundleIdentifier</key>
    <string>com.earthwallpaper.app</string>
    <key>CFBundleName</key>
    <string>EarthWallpaper</string>
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

# Clean metadata
xattr -cr "$APP_DIR"
rm -rf "$APP_DIR/_CodeSignature" "$APP_DIR/Contents/_CodeSignature" 2>/dev/null
find "$APP_DIR" -name "._*" -delete
find "$APP_DIR" -name ".DS_Store" -delete

echo "=== Creating ZIP ==="
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "=== Pushing tag ==="
cd "$PROJECT_DIR"
git tag "v$VERSION" -m "Release v$VERSION" 2>/dev/null || true
git push origin "v$VERSION" 2>/dev/null || true

echo "=== Creating GitHub Release ==="
gh release create "v$VERSION" \
    --title "Google Earth Wallpaper v$VERSION" \
    --notes "See [README](https://github.com/Wangtaotaoo/GoogleEarthWallpaper) for installation instructions." \
    "$ZIP_PATH"

echo "=== Done ==="
echo "Release: https://github.com/Wangtaotaoo/GoogleEarthWallpaper/releases/tag/v$VERSION"
