// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AWSClientRuntime",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSClientRuntime", targets: ["AWSClientRuntime"]),
    ],
    dependencies: [
        .package(id: "aws-sdk-swift.AWSSDKCommon", from: "0.0.1"),
        .package(id: "aws-sdk-swift.AWSSDKHTTPAuth", from: "0.0.1"),
        .package(id: "aws-sdk-swift.AWSSDKIdentity", from: "0.0.1"),
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: "0.30.0"),
        .package(id: "aws-sdk-swift.smithy-swift", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "AWSClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyRetriesAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyRetries", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyEventStreamsAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyEventStreamsAuthAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "AWSSDKCommon", package: "aws-sdk-swift.AWSSDKCommon"),
                .product(name: "AWSSDKHTTPAuth", package: "aws-sdk-swift.AWSSDKHTTPAuth"),
                .product(name: "AWSSDKIdentity", package: "aws-sdk-swift.AWSSDKIdentity"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AWSClientRuntimeTests",
            dependencies: [
                "AWSClientRuntime",
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyTestUtil", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "AWSSDKCommon", package: "aws-sdk-swift.AWSSDKCommon"),
            ],
            resources: [.process("Resources")]
        ),
    ]
)
