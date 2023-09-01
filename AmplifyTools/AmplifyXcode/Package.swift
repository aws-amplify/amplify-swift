// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AmplifyXcode",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "AmplifyXcodeCore", targets: ["AmplifyXcodeCore"]),
        .executable(name: "amplify-xcode", targets: ["AmplifyXcode"])
    ],
    dependencies: [
        .package(name: "XcodeProj", url: "https://github.com/tuist/xcodeproj", .upToNextMinor(from: "8.10.0")),
        .package(url: "https://github.com/yonaskolb/XcodeGen", from: "2.35.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "AmplifyXcodeCore",
            dependencies: [
                "XcodeProj",
                .product(name: "XcodeGenKit", package: "XcodeGen"),
                .product(name: "ProjectSpec", package: "XcodeGen"),
                "PathKit"
            ]),
        .testTarget(
            name: "AmplifyXcodeCoreTests",
            dependencies: ["AmplifyXcodeCore"]),

        .target(
            name: "AmplifyXcode",
            dependencies: [
                "AmplifyXcodeCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "AmplifyXcodeTests",
            dependencies: ["AmplifyXcode"])
    ]
)
