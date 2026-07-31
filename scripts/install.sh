#!/bin/bash
# Google Earth Wallpaper Installer
# 用法：在终端中运行 bash install.sh

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="EarthWallpaper.app"
SRC="$DIR/$APP"
DEST="/Applications/$APP"

if [ ! -d "$SRC" ]; then
    echo "❌ 找不到 $APP"
    echo "   请确保 install.sh 和 EarthWallpaper.app 在同一目录下。"
    echo "   Make sure install.sh and EarthWallpaper.app are in the same folder."
    exit 1
fi

echo "🚀 Installing Google Earth Wallpaper..."

# 杀掉旧进程
killall EarthWallpaper 2>/dev/null || true

# 拷贝到 Applications
echo "   → Copying to /Applications..."
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

# 清除下载隔离标记
echo "   → Removing quarantine flag..."
xattr -cr "$DEST" 2>/dev/null || true

# 在本机重新 ad-hoc 签名（Apple Silicon 必须）
echo "   → Signing for this machine..."
codesign --force --deep --sign - "$DEST" 2>/dev/null || true

# 启动
echo "   → Launching..."
open "$DEST"

echo ""
echo "✅ Done! Earth Wallpaper is running in your menu bar (🌍)."
echo "   安装完成！已在菜单栏运行 (🌍)。"
