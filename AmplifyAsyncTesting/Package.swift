// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let platforms: [SupportedPlatform] = [.iOS(.v13), .macOS(.v10_15)]
let dependencies: [Package.Dependency] = [

]
let swiftSettings: [SwiftSetting]? = [.define("DEV_PREVIEW_BUILD")]

let asyncTestingTargets: [Target] = [
    .target(
        name: "AmplifyAsyncTesting",
        dependencies: [],
        path: "Sources/AsyncTesting",
        linkerSettings: [.linkedFramework("XCTest")]
    ),
    .testTarget(
        name: "AmplifyAsyncTestingTests",
        dependencies: ["AmplifyAsyncTesting"],
        path: "Tests/AsyncTestingTests"
    )
]

let targets: [Target] =  asyncTestingTargets

let package = Package(
    name: "AmplifyAsyncTesting",
    platforms: platforms,
    products: [
        .library(
            name: "AmplifyAsyncTesting",
            targets: ["AmplifyAsyncTesting"]
        )
    ],
    dependencies: dependencies,
    targets: targets
)
