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
        .package(name: "hierarchical-state-machine-swift", path: "../Hierarchical-state-machine-swift"),
        .package(url: "https://github.com/libtom/libtommath", branch: "develop"),
        .package(name: "AWSSwiftSDK", url: "https://github.com/awslabs/aws-sdk-swift", .upToNextMajor(from: "0.1.0")),
        .package(name: "CwlPreconditionTesting", url: "https://github.com/mattgallagher/CwlPreconditionTesting", .upToNextMinor(from: "2.1.0"))
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
