// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "AmplifyAsyncTesting",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "AmplifyAsyncTesting",
            targets: ["AmplifyAsyncTesting"]
        )
    ],
    dependencies: [],
    targets: [
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
)
