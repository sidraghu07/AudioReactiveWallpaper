// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AudioReactiveWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "AudioReactiveWallpaper",
            resources: [.copy("Shaders.metal"), .copy("AppIcon.icns")]),
    ]
)
