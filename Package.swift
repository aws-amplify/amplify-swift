// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v13)],
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
        ),
        .target(
            name: "AWSCognitoAuthPlugin",
            dependencies: [
                "hierarchical-state-machine-swift",
                .target(name: "Amplify"),
                .target(name: "AmplifySRP"),
                .product(name: "AWSCognitoIdentityProvider", package: "AWSSwiftSDK"),
            ],
            path: "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AmplifySRP",
            dependencies: [
                .target(name: "AmplifyBigInteger"),
            ],
            path: "AmplifyPlugins/Auth/Sources/AmplifySRP"
        ),
        .target(
            name: "AmplifyBigInteger",
            dependencies: [
                "libtommath"
            ],
            path: "AmplifyPlugins/Auth/Sources/AmplifyBigInteger"
        ),
        .target(
            name: "AmplifyTestCommon",
            dependencies: [
                "Amplify",
                "CwlPreconditionTesting"
            ],
            path: "AmplifyTestCommon"
        ),
        .testTarget(
            name: "AmplifyTests",
            dependencies: [
                "Amplify",
                "AmplifyTestCommon"
            ],
            path: "AmplifyTests"
        ),
        .testTarget(
            name: "AmplifyBigIntegerTests",
            dependencies: [
                "AmplifyBigInteger"
            ],
            path: "AmplifyPlugins/Auth/Tests/AmplifyBigIntegerUnitTests"
        ),
        .testTarget(
            name: "AWSCognitoAuthPluginUnitTests",
            dependencies: [
                "AWSCognitoAuthPlugin"
            ],
            path: "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests"
        ),
        .testTarget(
            name: "AWSCognitoAuthPluginIntegrationTests",
            dependencies: [
                "AWSCognitoAuthPlugin"
            ],
            path: "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginIntegrationTests"
        ),
            
    ]
)
