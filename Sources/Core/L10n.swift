import Foundation

enum L10n {
    // Menu
    static var viewInGoogleEarth: String {
        lang == "zh" ? "在 Google Earth 中查看" : "View in Google Earth"
    }
    static var loading: String {
        lang == "zh" ? "加载中..." : "Loading..."
    }
    static var switchToNext: String {
        lang == "zh" ? "切换下一张" : "Next Wallpaper"
    }
    static var browseHistory: String {
        lang == "zh" ? "浏览历史" : "Browse History"
    }
    static var preferences: String {
        lang == "zh" ? "偏好设置..." : "Preferences..."
    }
    static var quit: String {
        lang == "zh" ? "退出" : "Quit"
    }

    // Window titles
    static var wallpaperHistoryTitle: String {
        lang == "zh" ? "壁纸历史" : "Wallpaper History"
    }
    static var preferencesTitle: String {
        lang == "zh" ? "偏好设置" : "Preferences"
    }

    // Settings
    static var switchInterval: String {
        lang == "zh" ? "壁纸切换间隔" : "Switch Interval"
    }
    static var intervalLabel: String {
        lang == "zh" ? "切换间隔" : "Interval"
    }
    static var dailyDownloadLimit: String {
        lang == "zh" ? "每日下载数量" : "Daily Downloads"
    }
    static var dailyLabel: String {
        lang == "zh" ? "每日数量" : "Per Day"
    }
    static var count5: String { "5\u{A0}" + (lang == "zh" ? "张" : "") }
    static var count10: String { "10\u{A0}" + (lang == "zh" ? "张" : "") }
    static var count15: String { "15\u{A0}" + (lang == "zh" ? "张" : "") }
    static var cacheStats: String {
        lang == "zh" ? "缓存统计" : "Cache Statistics"
    }
    static var cachedImages: String {
        lang == "zh" ? "已缓存图片:" : "Cached Images:"
    }
    static func cachedCount(_ n: Int) -> String {
        lang == "zh" ? "\(n) 张" : "\(n)"
    }
    static var storageUsed: String {
        lang == "zh" ? "占用空间:" : "Storage:"
    }
    static var clearCache: String {
        lang == "zh" ? "清除全部缓存" : "Clear All Cache"
    }

    // History
    static var noWallpapers: String {
        lang == "zh" ? "暂无已下载的壁纸" : "No wallpapers downloaded yet"
    }
    static var autoDownloadHint: String {
        lang == "zh" ? "应用启动后将自动下载壁纸" : "Wallpapers will download automatically"
    }
    static var setAsWallpaper: String {
        lang == "zh" ? "设为桌面壁纸" : "Set as Wallpaper"
    }

    // Interval labels
    static var interval30min: String {
        lang == "zh" ? "30 分钟" : "30 min"
    }
    static var interval1hour: String {
        lang == "zh" ? "1 小时" : "1 hour"
    }
    static var interval3hours: String {
        lang == "zh" ? "3 小时" : "3 hours"
    }
    static var interval6hours: String {
        lang == "zh" ? "6 小时" : "6 hours"
    }

    // MARK: - Language detection

    static var lang: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return "zh" }
        return "en"
    }
}
