# Google Earth Wallpaper

A native macOS menu bar app that downloads Google Earth satellite images and auto-rotates your desktop wallpaper daily.

原生 macOS 菜单栏应用，每天自动下载 Google Earth 卫星图片并定时切换桌面壁纸。

## Features / 功能

- **Daily Fresh Wallpapers** — Downloads up to 15 new satellite images every day
- **Auto Rotation** — Switch wallpapers on a schedule (30min / 1h / 3h / 6h)
- **Menu Bar Only** — Lives in your menu bar, no Dock icon
- **Multi-Screen** — Sets wallpaper on all connected displays
- **Google Earth Link** — Jump to the photo location in Google Earth with one click
- **Multi-Language** — Auto-detects system language (中文 / English)
- **Privacy First** — Everything stored locally, no data sent anywhere

---

- **每日新壁纸** — 每天自动下载最多 15 张新卫星图
- **定时切换** — 可选择 30 分钟 / 1 小时 / 3 小时 / 6 小时间隔自动切换
- **菜单栏驻留** — 只在菜单栏显示，无 Dock 图标
- **多屏支持** — 所有外接显示器同步更换
- **Google Earth 跳转** — 一键在 Google Earth 中查看当前壁纸的拍摄地点
- **多语言** — 自动根据系统语言显示中文或英文
- **纯本地** — 所有数据存在本地，不发送任何信息

## Requirements / 系统要求

- macOS 14.0+
- Internet connection (for downloading images)

## Installation / 安装

### Download / 下载

Download the latest `EarthWallpaper.dmg` from [Releases](https://github.com/Wangtaotaoo/GoogleEarthWallpaper/releases), open it, and drag the app to `Applications`.

从 [Releases](https://github.com/Wangtaotaoo/GoogleEarthWallpaper/releases) 下载最新的 `EarthWallpaper.dmg`，打开后拖入 `Applications` 文件夹。

> **Note:** The app is ad-hoc signed. On first launch, right-click the app and select "Open".
> **注意：** 应用使用自签名。首次打开请右键点击 → "打开"。

### Build from Source / 从源码编译

```bash
git clone https://github.com/Wangtaotaoo/GoogleEarthWallpaper.git
cd GoogleEarthWallpaper
swift build -c release
swift run
```

## Usage / 使用

Click the globe icon 🌍 in your menu bar:

- **Current Wallpaper** — Shows location and photo ID
- **View in Google Earth** — Opens the photo location in Google Earth
- **Next Wallpaper** — Manually switch to the next random image
- **Browse History** — View all cached wallpapers
- **Preferences** — Configure switch interval and download limits
- **Quit** — Exit the app

点击菜单栏的地球图标 🌍：

- **当前壁纸信息** — 显示拍摄地点和图片 ID
- **在 Google Earth 中查看** — 在 Google Earth 中打开当前壁纸的拍摄位置
- **切换下一张** — 手动切换到随机下一张
- **浏览历史** — 查看所有已缓存的壁纸
- **偏好设置** — 配置切换间隔和每日下载数量
- **退出** — 退出应用

## Storage / 存储

```
~/Library/Application Support/EarthWallpaper/
├── images/          # Cached wallpaper images (.jpg)
├── metadata.json    # Photo metadata (location, coordinates, etc.)
└── state.json       # App state (download count, current photo, etc.)
```

## Data Source / 数据来源

Images are sourced from Google's "Earth View" collection using the public API:
图片来源于 Google Earth View 公开接口：

```
https://www.gstatic.com/prettyearth/assets/data/v3/{id}.json
```

The app ships with 1,520 verified photo IDs extracted from the Earth View collection.
应用内置 1,520 个已验证的图片 ID。

## License / 协议

MIT License — see [LICENSE](LICENSE)
