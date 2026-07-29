import AppKit
import SwiftUI

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let scheduleManager: ScheduleManager
    private let downloadManager: DownloadManager
    private var currentPhoto: PhotoData?

    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?

    init(scheduleManager: ScheduleManager, downloadManager: DownloadManager) {
        self.scheduleManager = scheduleManager
        self.downloadManager = downloadManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupMenuBar()
    }

    private func setupMenuBar() {
        if let button = statusItem.button {
            button.title = L10n.lang == "zh" ? "🌍" : "🌎"
            button.font = NSFont.systemFont(ofSize: 14)
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        // Current wallpaper info
        if let photo = currentPhoto {
            let infoItem = NSMenuItem()
            infoItem.title = "📍 \(photo.locationDescription)"
            infoItem.isEnabled = false
            menu.addItem(infoItem)

            let idItem = NSMenuItem()
            idItem.title = "ID: \(photo.id)"
            idItem.isEnabled = false
            menu.addItem(idItem)

            menu.addItem(.separator())

            // Open in Google Earth
            let mapItem = NSMenuItem(
                title: L10n.viewInGoogleEarth,
                action: #selector(openInGoogleMaps),
                keyEquivalent: ""
            )
            mapItem.target = self
            menu.addItem(mapItem)
        } else {
            let loadingItem = NSMenuItem()
            loadingItem.title = L10n.loading
            loadingItem.isEnabled = false
            menu.addItem(loadingItem)
        }

        menu.addItem(.separator())

        // Switch to next wallpaper
        let nextItem = NSMenuItem(
            title: L10n.switchToNext,
            action: #selector(switchToNext),
            keyEquivalent: "n"
        )
        nextItem.target = self
        menu.addItem(nextItem)

        menu.addItem(.separator())

        // Browse history
        let historyItem = NSMenuItem(
            title: L10n.browseHistory,
            action: #selector(showHistory),
            keyEquivalent: ""
        )
        historyItem.target = self
        menu.addItem(historyItem)

        // Settings
        let settingsItem = NSMenuItem(
            title: L10n.preferences,
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: L10n.quit,
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func switchToNext() {
        Task {
            let cached = downloadManager.getAllCachedPhotos()
            guard !cached.isEmpty else { return }
            let currentId = downloadManager.getCurrentPhotoId()
            let photo: PhotoData
            if cached.count > 1, let currentId = currentId {
                let candidates = cached.filter { $0.id != currentId }
                photo = candidates.randomElement() ?? cached[0]
            } else {
                photo = cached[0]
            }
            if let path = photo.localPath {
                WallpaperManager.shared.setWallpaper(imagePath: path)
                downloadManager.updateCurrentPhotoId(photo.id)
                currentPhoto = photo
            }
        }
    }

    @objc private func openInGoogleMaps() {
        guard let photo = currentPhoto else { return }
        // Same formula as the original Chrome extension
        let latRad = photo.lat * (.pi / 180)
        let zoomLevel = Double((photo.zoom > 0 ? photo.zoom : 10) + 1)
        let range = Int(abs(cos(latRad)) / pow(2.0, zoomLevel) * 255125480)
        let urlString = "https://earth.google.com/web/@\(photo.lat),\(photo.lng),0a,\(range)d,35y,0h,0t,0r"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showHistory() {
        if historyWindow == nil {
            let contentView = WallpaperListView(downloadManager: downloadManager)
            let hostingController = NSHostingController(rootView: contentView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = L10n.wallpaperHistoryTitle
            window.setContentSize(NSSize(width: 500, height: 400))
            window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            window.isReleasedWhenClosed = false
            historyWindow = window
        }
        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let contentView = SettingsWindow(
                downloadManager: downloadManager,
                scheduleManager: scheduleManager
            )
            let hostingController = NSHostingController(rootView: contentView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = L10n.preferencesTitle
            window.setContentSize(NSSize(width: 400, height: 320))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Update

    func updateCurrentPhoto(_ photo: PhotoData?) {
        currentPhoto = photo
    }
}
