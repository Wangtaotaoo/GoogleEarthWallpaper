#!/bin/bash
# EarthWallpaper installer — run this after downloading the ZIP
# 用法：解压 ZIP 后在终端运行 bash install.sh

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="EarthWallpaper.app"
SRC="$DIR/$APP_NAME"
DEST="/Applications/$APP_NAME"

if [ ! -d "$SRC" ]; then
    echo "找不到 $APP_NAME，请确保 install.sh 和 EarthWallpaper.app 在同一目录。"
    echo "Cannot find $APP_NAME. Make sure install.sh and EarthWallpaper.app are in the same folder."
    exit 1
fi

echo "Installing Google Earth Wallpaper..."

# Step 1: Kill existing instance
killall EarthWallpaper 2>/dev/null || true

# Step 2: Copy to Applications
echo "  Copying to /Applications..."
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

# Step 3: Remove quarantine flag
echo "  Removing quarantine..."
xattr -cr "$DEST" 2>/dev/null || true

# Step 4: Sign with ad-hoc signature on THIS machine
echo "  Signing for this machine..."
codesign --force --deep --sign - "$DEST" 2>/dev/null || true

# Step 5: Launch
echo "  Launching..."
open "$DEST"

echo ""
echo "Done! Earth Wallpaper is now running in your menu bar (🌍)."
echo "安装完成！Earth Wallpaper 已在菜单栏运行 (🌍)。"
