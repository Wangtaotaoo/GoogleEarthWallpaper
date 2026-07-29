import Foundation

struct PhotoData: Codable, Identifiable {
    let id: String
    let lat: Double
    let lng: Double
    let zoom: Int
    let country: String?
    let region: String?
    let attribution: String
    var dataUri: String
    var localPath: String?
    var downloadDate: Date?

    var locationDescription: String {
        var parts: [String] = []
        if let region = region, !region.isEmpty {
            parts.append(region)
        }
        if let country = country, !country.isEmpty {
            parts.append(country)
        }
        if parts.isEmpty {
            return attribution
        }
        return parts.joined(separator: ", ")
    }
}

struct AppState: Codable {
    var downloadCountToday: Int = 0
    var lastDownloadDate: Date?
    var lastSwitchDate: Date?
    var currentPhotoId: String?
    var downloadedIds: [String] = []
}

struct AppConfig: Codable {
    enum SwitchInterval: Int, CaseIterable, Identifiable {
        case halfHour = 1800
        case oneHour = 3600
        case threeHours = 10800
        case sixHours = 21600

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .halfHour: return L10n.interval30min
            case .oneHour: return L10n.interval1hour
            case .threeHours: return L10n.interval3hours
            case .sixHours: return L10n.interval6hours
            }
        }
    }

    var switchIntervalSeconds: Int = SwitchInterval.oneHour.rawValue
    var dailyDownloadLimit: Int = 10
    var maxCacheImages: Int = 200
}
