// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EarthWallpaper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "EarthWallpaper",
            path: "Sources",
            resources: [
                .process("Resources/PhotoIDs.json")
            ]
        )
    ]
)
