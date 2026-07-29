import SwiftUI

struct SettingsWindow: View {
    @ObservedObject var downloadManager: DownloadManager
    let scheduleManager: ScheduleManager

    @State private var selectedInterval: AppConfig.SwitchInterval
    @State private var dailyLimit: Double

    init(downloadManager: DownloadManager, scheduleManager: ScheduleManager) {
        self.downloadManager = downloadManager
        self.scheduleManager = scheduleManager
        let config = downloadManager.loadConfig()
        _selectedInterval = State(initialValue: AppConfig.SwitchInterval(rawValue: config.switchIntervalSeconds) ?? .oneHour)
        _dailyLimit = State(initialValue: Double(config.dailyDownloadLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Switch interval
            Group {
                Text(L10n.switchInterval)
                    .font(.headline)

                Picker(L10n.intervalLabel, selection: $selectedInterval) {
                    ForEach(AppConfig.SwitchInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedInterval) { _, newValue in
                    var config = downloadManager.loadConfig()
                    config.switchIntervalSeconds = newValue.rawValue
                    scheduleManager.updateConfig(config)
                }
            }

            Divider()

            // Daily download limit
            Group {
                Text(L10n.dailyDownloadLimit)
                    .font(.headline)

                Picker(L10n.dailyLabel, selection: Binding<Int>(
                    get: { Int(dailyLimit) },
                    set: { newValue in
                        dailyLimit = Double(newValue)
                        var config = downloadManager.loadConfig()
                        config.dailyDownloadLimit = Int(dailyLimit)
                        scheduleManager.updateConfig(config)
                    }
                )) {
                    Text(L10n.count5).tag(5)
                    Text(L10n.count10).tag(10)
                    Text(L10n.count15).tag(15)
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Cache stats
            Group {
                Text(L10n.cacheStats)
                    .font(.headline)

                HStack {
                    Text(L10n.cachedImages)
                    Spacer()
                    Text(L10n.cachedCount(downloadManager.totalCached))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(L10n.storageUsed)
                    Spacer()
                    Text(downloadManager.cacheSizeFormatted())
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Clear cache button
            HStack {
                Spacer()
                Button(action: {
                    downloadManager.clearCache()
                }) {
                    Label(L10n.clearCache, systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Spacer()
            }

            Spacer()
        }
        .padding()
        .frame(width: 380)
    }
}
