// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SPRCLI",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.46.0"),
        .package(path: "../AWSSDKSwiftCLI"),
    ],
    targets: [
        .executableTarget(
            name: "spr-publish",
            dependencies: [
                "SPR",
                .product(name: "AWSCLIUtils", package: "AWSSDKSwiftCLI"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "spr-multi-publish",
            dependencies: [
                "SPR",
                .product(name: "AWSCLIUtils", package: "AWSSDKSwiftCLI"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "SPR",
            dependencies: [
                .product(name: "AWSCLIUtils", package: "AWSSDKSwiftCLI"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "AWSCloudFront", package: "aws-sdk-swift"),
            ]
        ),
    ]
)
