// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Amplify",
            targets: ["Amplify"]),
        
        .library(name: "AWSPluginsCore",
                 targets: ["AWSPluginsCore"]),
        
        .library(name: "AWSAPIPlugin",
                 targets: ["AWSAPIPlugin"]),
        
        .library(name: "AWSCognitoAuthPlugin",
                 targets: ["AWSCognitoAuthPlugin"]),
        
        .library(name: "AWSDataStorePlugin",
                 targets: ["AWSDataStorePlugin"]),
        
        .library(name: "AWSPinpointAnalyticsPlugin",
                 targets: ["AWSPinpointAnalyticsPlugin"]),
        
        .library(name: "AWSS3StoragePlugin",
                 targets: ["AWSS3StoragePlugin"]),
        
    ],
    dependencies: [

        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "Amplify",
            path: "Amplify"
        ),
        .target(
            name: "AWSPluginsCore",
            dependencies: [.target(name: "Amplify"),
                           .product(name: "AWSCore", package: "AWSiOSSDKV2")],
            path: "AmplifyPlugins/Core/AWSPluginsCore"
        ),
        .target(
            name: "AWSAPIPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AppSyncRealTimeClient", package: "AppSyncRealTimeClient")
            ],
            path: "AmplifyPlugins/API/AWSAPICategoryPlugin"
        ),
        .target(
            name: "AWSCognitoAuthPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSAuthCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSMobileClientXCF", package: "AWSiOSSDKV2"),
                .product(name: "AWSCognitoIdentityProvider", package: "AWSiOSSDKV2"),
                .product(name: "AWSCognitoIdentityProviderASF", package: "AWSiOSSDKV2")],
            path: "AmplifyPlugins/Auth/AWSCognitoAuthPlugin"
        ),
        .target(
            name: "AWSDataStorePlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "SQLite", package: "SQLite.swift")],
            path: "AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin"
        ),
        .target(
            name: "AWSPinpointAnalyticsPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSPinpoint", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Analytics/AWSPinpointAnalyticsPlugin"
        ),
        .target(
            name: "AWSS3StoragePlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSS3", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Storage/AWSS3StoragePlugin"
        )
    ]
)
