// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AWSSDKHTTPAuth",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSSDKHTTPAuth", targets: ["AWSSDKHTTPAuth"]),
    ],
    dependencies: [
        .package(id: "aws-sdk-swift.AWSSDKIdentity", from: "0.0.1"),
        .package(id: "aws-sdk-swift.AWSSDKChecksums", from: "0.0.1"),
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: "0.30.0"),
        .package(id: "aws-sdk-swift.smithy-swift", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "AWSSDKHTTPAuth",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "Smithy", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyHTTPAuth", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "AWSSDKIdentity", package: "aws-sdk-swift.AWSSDKIdentity"),
                .product(name: "AWSSDKChecksums", package: "aws-sdk-swift.AWSSDKChecksums"),
            ]
        ),
        .testTarget(
            name: "AWSSDKHTTPAuthTests",
            dependencies: [
                "AWSSDKHTTPAuth",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyTestUtil", package: "aws-sdk-swift.smithy-swift"),
            ]
        ),
    ]
)
