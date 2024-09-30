// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AWSSDKEventStreamsAuth",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSSDKEventStreamsAuth", targets: ["AWSSDKEventStreamsAuth"]),
    ],
    dependencies: [
        .package(id: "aws-sdk-swift.AWSSDKHTTPAuth", from: "0.0.1"),
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: "0.30.0"),
        .package(id: "aws-sdk-swift.smithy-swift", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "AWSSDKEventStreamsAuth",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyEventStreamsAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyEventStreamsAuthAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyEventStreams", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "AWSSDKHTTPAuth", package: "aws-sdk-swift.AWSSDKHTTPAuth"),
            ]
        ),
        .testTarget(name: "AWSSDKEventStreamsAuthTests", dependencies: [
            "AWSSDKEventStreamsAuth",
            .product(name: "SmithyStreams", package: "aws-sdk-swift.smithy-swift"),
            .product(name: "SmithyTestUtil", package: "aws-sdk-swift.smithy-swift"),
        ]),
    ]
)
