// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GeminiChecker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "GeminiChecker",
            path: "Sources/GeminiChecker"
        )
    ]
)
