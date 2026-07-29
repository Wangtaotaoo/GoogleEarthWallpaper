import SwiftUI

struct WallpaperListView: View {
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        let photos = downloadManager.getAllCachedPhotos()

        if photos.isEmpty {
            VStack {
                Spacer()
                Text(L10n.noWallpapers)
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(L10n.autoDownloadHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(photos) { photo in
                HStack(spacing: 12) {
                    // Thumbnail
                    if let path = photo.localPath,
                       let image = NSImage(contentsOfFile: path) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 40)
                            .cornerRadius(4)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(photo.locationDescription)
                            .font(.body)
                            .lineLimit(1)

                        HStack {
                            Text("ID: \(photo.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            if let date = photo.downloadDate {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Set as wallpaper button
                    Button(action: {
                        if let path = photo.localPath {
                            WallpaperManager.shared.setWallpaper(imagePath: path)
                            downloadManager.updateCurrentPhotoId(photo.id)
                        }
                    }) {
                        Image(systemName: "photo")
                            .font(.body)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.setAsWallpaper)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }
}
