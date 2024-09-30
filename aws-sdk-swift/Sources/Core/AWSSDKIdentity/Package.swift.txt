// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AWSSDKIdentity",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSSDKIdentity", targets: ["AWSSDKIdentity"]),
    ],
    dependencies: [
        .package(id: "aws-sdk-swift.AWSSDKCommon", from: "0.0.1"),
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: "0.30.0"),
        .package(id: "aws-sdk-swift.smithy-swift", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "AWSSDKIdentity",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "ClientRuntime", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "Smithy", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyHTTPAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyIdentityAPI", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyIdentity", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "AWSSDKCommon", package: "aws-sdk-swift.AWSSDKCommon"),
            ]
        ),
        .testTarget(
            name: "AWSSDKIdentityTests",
            dependencies: [
                "AWSSDKIdentity",
                .product(name: "Smithy", package: "aws-sdk-swift.smithy-swift"),
                .product(name: "SmithyIdentity", package: "aws-sdk-swift.smithy-swift"),
            ]
        ),
    ]
)
