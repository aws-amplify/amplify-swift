// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v13)],
    products: [
        
        .library(
            name: "Amplify",
            targets: ["Amplify"]
        ),
        .library(
            name: "AWSPluginsCore",
            targets: ["AWSPluginsCore"]
        ),
        .library(
            name: "AWSCognitoAuthPlugin",
            targets: ["AWSCognitoAuthPlugin"]
        ),
        .library(name: "AWSDataStorePlugin",
                targets: ["AWSDataStorePlugin"]),
    ],
    dependencies: [
        .package(name: "hierarchical-state-machine-swift", path: "../Hierarchical-state-machine-swift"),
        .package(url: "https://github.com/libtom/libtommath", branch: "develop"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.12.2")),
        .package(name: "AWSSwiftSDK", url: "https://github.com/awslabs/aws-sdk-swift", .upToNextMajor(from: "0.1.1")),
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
            name: "AWSPluginsCore",
            dependencies: [
                "Amplify",
                .product(name: "AWSClientRuntime", package: "AWSSwiftSDK")
            ],
            path: "AmplifyPlugins/Core/AWSPluginsCore"
        ),
        .target(
            name: "AWSCognitoAuthPlugin",
            dependencies: [
                "hierarchical-state-machine-swift",
                .target(name: "Amplify"),
                .target(name: "AmplifySRP"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCognitoIdentityProvider", package: "AWSSwiftSDK"),
                .product(name: "AWSCognitoIdentity", package: "AWSSwiftSDK")
            ],
            path: "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AWSDataStorePlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "SQLite", package: "SQLite.swift")],
            path: "AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin",
            exclude: [
                "Info.plist"
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
            name: "AWSPluginsCoreTests",
            dependencies: [
                "AWSPluginsCore",
                "AmplifyTestCommon",
                .product(name: "AWSClientRuntime", package: "AWSSwiftSDK")
            ],
            path: "AmplifyPlugins/Core/AWSPluginsCoreTests"
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
        .testTarget(
            name: "AWSDataStoreCategoryPluginTests",
            dependencies: [
                "AWSDataStorePlugin",
                "AmplifyTestCommon"
            ],
            path: "AmplifyPlugins/Datastore/AWSDataStoreCategoryPluginTests"
        ),
        
    ]
)
