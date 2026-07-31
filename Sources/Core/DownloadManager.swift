import Foundation
import AppKit

final class DownloadManager: ObservableObject {
    @Published var totalCached: Int = 0
    @Published var cacheSizeBytes: Int64 = 0

    private let baseURL = "https://www.gstatic.com/prettyearth/assets/data/v3"
    private let fileManager = FileManager.default
    private let session: URLSession
    private var appState: AppState
    private var metadata: [String: PhotoData] = [:]

    var supportDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EarthWallpaper")
    }

    var imagesDir: URL {
        supportDir.appendingPathComponent("images")
    }

    var metadataURL: URL {
        supportDir.appendingPathComponent("metadata.json")
    }

    var stateURL: URL {
        supportDir.appendingPathComponent("state.json")
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)

        appState = AppState()
        ensureDirectories()
        loadState()
        loadMetadata()
        refreshCacheStats()
    }

    // MARK: - Directory Setup

    private func ensureDirectories() {
        try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
    }

    // MARK: - State Persistence

    private func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            appState = AppState()
            return
        }
        appState = state

        // Reset daily count if date changed
        if let lastDate = appState.lastDownloadDate {
            if !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
                appState.downloadCountToday = 0
            }
        }
    }

    func saveState() {
        guard let data = try? JSONEncoder().encode(appState) else { return }
        try? data.write(to: stateURL)
    }

    func saveConfig(_ config: AppConfig) {
        let defaults = UserDefaults.standard
        defaults.set(config.switchIntervalSeconds, forKey: "switchIntervalSeconds")
        defaults.set(config.dailyDownloadLimit, forKey: "dailyDownloadLimit")
        defaults.set(config.maxCacheImages, forKey: "maxCacheImages")
    }

    func loadConfig() -> AppConfig {
        let defaults = UserDefaults.standard
        var config = AppConfig()
        if defaults.object(forKey: "switchIntervalSeconds") != nil {
            config.switchIntervalSeconds = defaults.integer(forKey: "switchIntervalSeconds")
        }
        if defaults.object(forKey: "dailyDownloadLimit") != nil {
            config.dailyDownloadLimit = defaults.integer(forKey: "dailyDownloadLimit")
        }
        if defaults.object(forKey: "maxCacheImages") != nil {
            config.maxCacheImages = defaults.integer(forKey: "maxCacheImages")
        }
        return config
    }

    // MARK: - Metadata

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let dict = try? JSONDecoder().decode([String: PhotoData].self, from: data) else { return }
        metadata = dict
    }

    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(metadata) else { return }
        try? data.write(to: metadataURL)
    }

    func getAllCachedPhotos() -> [PhotoData] {
        return Array(metadata.values).sorted { a, b in
            let dateA = a.downloadDate ?? Date.distantPast
            let dateB = b.downloadDate ?? Date.distantPast
            return dateA > dateB
        }
    }

    // MARK: - Photo ID Management

    private func loadPhotoIDs() -> [String] {
        let url: URL?
        // Prefer main bundle (packaged app), fall back to module (SPM run)
        if let u = Bundle.main.url(forResource: "PhotoIDs", withExtension: "json") {
            url = u
        } else if let u = Bundle.module.url(forResource: "PhotoIDs", withExtension: "json") {
            url = u
        } else {
            url = nil
        }
        guard let url = url,
              let data = try? Data(contentsOf: url),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }

    func getNextPhotoID() -> String? {
        let allIds = loadPhotoIDs()
        let unused = allIds.filter { !appState.downloadedIds.contains($0) }
        return unused.randomElement() ?? allIds.randomElement()
    }

    // MARK: - Download

    func canDownloadToday(limit: Int) -> Bool {
        return appState.downloadCountToday < limit
    }

    @discardableResult
    func downloadOne() async throws -> PhotoData? {
        guard let photoId = getNextPhotoID() else { return nil }

        let url = URL(string: "\(baseURL)/\(photoId).json")!
        let (data, _) = try await session.data(from: url)

        var photo = try JSONDecoder().decode(PhotoData.self, from: data)
        photo.localPath = saveImage(dataUri: photo.dataUri, photoId: photoId)
        photo.downloadDate = Date()

        // Update state
        appState.downloadedIds.append(photoId)
        appState.downloadCountToday += 1
        appState.lastDownloadDate = Date()

        metadata[photoId] = photo
        saveMetadata()
        saveState()
        refreshCacheStats()

        // Trim cache if needed
        let config = loadConfig()
        enforceCacheLimit(maxCount: config.maxCacheImages)

        return photo
    }

    func downloadBatch(count: Int) async {
        for _ in 0..<count {
            do {
                try await downloadOne()
            } catch {
                print("Download error: \(error)")
                // Continue with next on error
            }
        }
    }

    // MARK: - Image Saving

    private func saveImage(dataUri: String, photoId: String) -> String? {
        // dataUri format: "data:image/jpeg;base64,...."
        guard let commaIndex = dataUri.firstIndex(of: ",") else { return nil }
        let base64Part = String(dataUri[dataUri.index(after: commaIndex)...])
        // Strip newlines if any
        let cleaned = base64Part.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let imageData = Data(base64Encoded: cleaned) else { return nil }

        let fileName = "\(photoId).jpg"
        let fileURL = imagesDir.appendingPathComponent(fileName)
        try? imageData.write(to: fileURL)
        return fileURL.path
    }

    // MARK: - Cache Management

    private func enforceCacheLimit(maxCount: Int) {
        let cached = getAllCachedPhotos()
        guard cached.count > maxCount else { return }

        let toDelete = cached.suffix(cached.count - maxCount)
        for photo in toDelete {
            if let path = photo.localPath {
                try? fileManager.removeItem(atPath: path)
            }
            metadata.removeValue(forKey: photo.id)
            appState.downloadedIds.removeAll { $0 == photo.id }
        }
        saveMetadata()
        saveState()
        refreshCacheStats()
    }

    func clearCache() {
        // Delete all images
        if let files = try? fileManager.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        metadata.removeAll()
        appState.downloadedIds.removeAll()
        appState.downloadCountToday = 0
        saveMetadata()
        saveState()
        refreshCacheStats()
    }

    func refreshCacheStats() {
        totalCached = metadata.count

        var totalSize: Int64 = 0
        if let files = try? fileManager.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let attrs = try? file.resourceValues(forKeys: [.fileSizeKey]), let size = attrs.fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        cacheSizeBytes = totalSize
    }

    func cacheSizeFormatted() -> String {
        let mb = Double(cacheSizeBytes) / (1024.0 * 1024.0)
        if mb < 1 {
            let kb = Double(cacheSizeBytes) / 1024.0
            return String(format: "%.1f KB", kb)
        }
        return String(format: "%.1f MB", mb)
    }

    // MARK: - Photo lookup

    func getPhoto(byId id: String) -> PhotoData? {
        return metadata[id]
    }

    // MARK: - State helpers for ScheduleManager

    func loadStateCache() -> AppState {
        return appState
    }

    func todaysDownloadCount() -> Int {
        if let lastDate = appState.lastDownloadDate,
           !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            appState.downloadCountToday = 0
            saveState()
        }
        return appState.downloadCountToday
    }

    func updateCurrentPhotoId(_ id: String) {
        appState.currentPhotoId = id
        appState.lastSwitchDate = Date()
        saveState()
    }

    func getCurrentPhotoId() -> String? {
        return appState.currentPhotoId
    }

    func isNewDay() -> Bool {
        guard let lastDate = appState.lastDownloadDate else { return true }
        return !Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }

    func resetDailyCountIfNewDay() {
        if isNewDay() {
            appState.downloadCountToday = 0
            appState.lastDownloadDate = Date()
            saveState()
        }
    }
}
