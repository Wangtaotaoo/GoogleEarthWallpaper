import Foundation
import AppKit

final class ScheduleManager {
    private let downloadManager: DownloadManager
    private let wallpaperManager: WallpaperManager
    private var switchTimer: Timer?
    private var dailyCheckTimer: Timer?

    private var currentConfig: AppConfig

    var onWallpaperChanged: ((PhotoData?) -> Void)?

    init(downloadManager: DownloadManager, wallpaperManager: WallpaperManager = .shared) {
        self.downloadManager = downloadManager
        self.wallpaperManager = wallpaperManager
        self.currentConfig = downloadManager.loadConfig()
    }

    // MARK: - Start / Stop

    func start() {
        stop()
        currentConfig = downloadManager.loadConfig()
        scheduleSwitching(interval: TimeInterval(currentConfig.switchIntervalSeconds))
        scheduleDailyCheck()
        Task {
            await setupInitialWallpaper()
            await downloadDailyBatchIfNeeded()
        }
    }

    func stop() {
        switchTimer?.invalidate()
        switchTimer = nil
        dailyCheckTimer?.invalidate()
        dailyCheckTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Daily Check

    private func scheduleDailyCheck() {
        // Check every 60 seconds if a new day has started
        dailyCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForNewDay()
        }
        dailyCheckTimer?.tolerance = 10

        // Also check immediately when system wakes from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(onSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func onSystemWake() {
        checkForNewDay()
    }

    private func checkForNewDay() {
        guard downloadManager.isNewDay() else { return }
        downloadManager.resetDailyCountIfNewDay()
        Task {
            await downloadDailyBatchIfNeeded()
        }
    }

    func updateConfig(_ config: AppConfig) {
        currentConfig = config
        downloadManager.saveConfig(config)
        stop()
        start()
    }

    // MARK: - Initial Setup

    private func setupInitialWallpaper() async {
        let cached = downloadManager.getAllCachedPhotos()
        if let photo = wallpaperManager.getRandomCachedWallpaper(from: cached),
           let path = photo.localPath {
            wallpaperManager.setWallpaper(imagePath: path)
            onWallpaperChanged?(photo)
        } else {
            // Download one immediately
            if let photo = try? await downloadManager.downloadOne(),
               let path = photo.localPath {
                wallpaperManager.setWallpaper(imagePath: path)
                onWallpaperChanged?(photo)
            }
        }
    }

    // MARK: - Switching

    private func scheduleSwitching(interval: TimeInterval) {
        guard interval > 0 else { return }

        switchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.switchToNextWallpaper()
        }
        // Tolerate some drift for energy efficiency
        switchTimer?.tolerance = interval * 0.1
    }

    func switchToNextWallpaper() {
        // Check if it's a new day and download fresh images
        if downloadManager.isNewDay() {
            downloadManager.resetDailyCountIfNewDay()
            Task {
                await downloadDailyBatchIfNeeded()
            }
        }

        let cached = downloadManager.getAllCachedPhotos()
        guard !cached.isEmpty else { return }

        let currentId = downloadManager.loadStateCache().currentPhotoId
        let photo: PhotoData

        if cached.count > 1, let currentId = currentId {
            // Pick a random photo different from current
            let candidates = cached.filter { $0.id != currentId }
            photo = candidates.randomElement() ?? cached[0]
        } else {
            photo = cached[0]
        }

        if let path = photo.localPath {
            wallpaperManager.setWallpaper(imagePath: path)
            downloadManager.updateCurrentPhotoId(photo.id)
            onWallpaperChanged?(photo)
        }
    }

    // MARK: - Daily Download

    private func downloadDailyBatchIfNeeded() async {
        let remaining = currentConfig.dailyDownloadLimit - downloadManager.todaysDownloadCount()
        guard remaining > 0 else { return }
        await downloadManager.downloadBatch(count: remaining)
    }

    func checkAndDownload() async {
        let remaining = currentConfig.dailyDownloadLimit - downloadManager.todaysDownloadCount()
        guard remaining > 0 else { return }
        await downloadManager.downloadBatch(count: remaining)
    }
}
