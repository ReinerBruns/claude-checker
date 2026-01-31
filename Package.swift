// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeChecker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ClaudeChecker",
            path: "Sources/ClaudeChecker"
        )
    ]
)
