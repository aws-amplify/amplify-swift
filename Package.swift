// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Amplify",
            targets: ["Amplify"])
        
    ],
    dependencies: [
        .package(name: "AWSiOSSDKV2", url: "https://github.com/aws-amplify/aws-sdk-ios-spm.git", .upToNextMinor(from: "2.27.0")),
        .package(name: "AppSyncRealTimeClient", url: "https://github.com/aws-amplify/aws-appsync-realtime-client-ios.git", from: "2.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.13.2"))
    ],
    targets: [
        .target(
            name: "Amplify",
            path: "Amplify",
            exclude: [
                "Info.plist",
                "Categories/DataStore/Model/Temporal/README.md"
            ]
        )
    ]
)
