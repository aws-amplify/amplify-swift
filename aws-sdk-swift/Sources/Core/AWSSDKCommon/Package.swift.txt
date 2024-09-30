// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AWSSDKCommon",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSSDKCommon", targets: ["AWSSDKCommon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: "0.30.0"),
    ],
    targets: [
        .target(
            name: "AWSSDKCommon",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
            ]
        ),
    ]
)
