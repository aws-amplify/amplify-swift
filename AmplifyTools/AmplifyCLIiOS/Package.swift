// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AmplifyCLIiOS",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "amplify-ios", targets: ["AmplifyCLIiOS"])
    ],
    dependencies: [
        .package(name: "XcodeProj", url: "https://github.com/tuist/xcodeproj", .upToNextMajor(from: "7.13.0")),
        .package(url: "https://github.com/yonaskolb/XcodeGen", from: "2.18.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "AmplifyCLIiOS",
            dependencies: [
                "XcodeProj",
                .product(name: "XcodeGenKit", package: "XcodeGen"),
                .product(name: "ProjectSpec", package: "XcodeGen"),
                "PathKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "AmplifyCLIiOSTests",
            dependencies: ["AmplifyCLIiOS"]),
    ]
)
