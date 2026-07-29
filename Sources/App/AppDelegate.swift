import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var scheduleManager: ScheduleManager!
    private var downloadManager: DownloadManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock (menu bar only)
        NSApp.setActivationPolicy(.accessory)

        // Initialize managers
        let dm = DownloadManager()
        downloadManager = dm

        let sm = ScheduleManager(downloadManager: dm, wallpaperManager: .shared)
        scheduleManager = sm

        // Setup menu bar
        let mbc = MenuBarController(scheduleManager: sm, downloadManager: dm)
        menuBarController = mbc

        // Wire up wallpaper change callback
        sm.onWallpaperChanged = { [weak mbc] photo in
            DispatchQueue.main.async {
                mbc?.updateCurrentPhoto(photo)
            }
        }

        // Start scheduling
        sm.start()
    }
}
