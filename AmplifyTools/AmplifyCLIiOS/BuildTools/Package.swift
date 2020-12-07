// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", .upToNextMinor(from: "0.44.17")),
        .package(url: "https://github.com/realm/SwiftLint", .upToNextMinor(from: "0.41.0")),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
