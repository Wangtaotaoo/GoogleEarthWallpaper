import Foundation
import AppKit

final class WallpaperManager {
    static let shared = WallpaperManager()

    private let workspace = NSWorkspace.shared

    private init() {}

    func setWallpaper(imagePath: String) {
        let url = URL(fileURLWithPath: imagePath)
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .allowClipping: true,
            .fillColor: NSColor.black
        ]

        for screen in NSScreen.screens {
            try? workspace.setDesktopImageURL(url, for: screen, options: options)
        }
    }

    func getRandomCachedWallpaper(from photos: [PhotoData]) -> PhotoData? {
        return photos.randomElement()
    }

    func getNextSequentialWallpaper(from photos: [PhotoData], currentId: String?) -> PhotoData? {
        guard !photos.isEmpty else { return nil }
        if let currentId = currentId,
           let idx = photos.firstIndex(where: { $0.id == currentId }) {
            let nextIdx = (idx + 1) % photos.count
            return photos[nextIdx]
        }
        return photos.first
    }
}
