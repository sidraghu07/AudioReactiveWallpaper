// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SoundPaper",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SoundPaper",
            resources: [.copy("Shaders.metal"), .copy("AppIcon.icns")]),
    ]
)
