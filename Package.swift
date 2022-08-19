// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let platforms: [SupportedPlatform] = [.iOS(.v13)]
let dependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/stephencelis/SQLite.swift.git",
        .exact("0.12.2")
    ),
    .package(
        name: "AppSyncRealTimeClient",
        url: "https://github.com/aws-amplify/aws-appsync-realtime-client-ios.git",
        from: "2.1.1"
    ),
    .package(
        name: "AWSSwiftSDK",
        url: "https://github.com/awslabs/aws-sdk-swift.git",
        .upToNextMinor(from: "0.2.6")
    ),
    .package(
        name: "CwlPreconditionTesting",
        url: "https://github.com/mattgallagher/CwlPreconditionTesting.git",
        .upToNextMinor(from: "2.1.0")
    )
]
let swiftSettings: [SwiftSetting]? = [.define("DEV_PREVIEW_BUILD")]

let amplifyTargets: [Target] = [
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
        path: "AmplifyPlugins/Core/AWSPluginsCore",
        exclude: [
            "Info.plist"
        ]
    ),
    .target(
        name: "AmplifyTestCommon",
        dependencies: [
            "Amplify",
            "CwlPreconditionTesting",
            "AWSPluginsCore"
        ],
        path: "AmplifyTestCommon",
        exclude: [
            "Info.plist",
            "Models/schema.graphql",
            "Models/Restaurant/schema.graphql",
            "Models/TeamProject/schema.graphql",
            "Models/M2MPostEditorUser/schema.graphql",
            "Models/Collection/connection-schema.graphql",
            "Models/TransformerV2/schema.graphql",
            "Models/CustomPrimaryKey/primarykey_schema.graphql"
        ]
    ),
    .testTarget(
        name: "AmplifyTests",
        dependencies: [
            "Amplify",
            "AmplifyTestCommon"
        ],
        path: "AmplifyTests",
        exclude: [
            "Info.plist",
            "CoreTests/README.md"
        ]
    ),
    .target(
        name: "AWSPluginsTestCommon",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            .product(name: "AWSClientRuntime", package: "AWSSwiftSDK")
        ],
        path: "AmplifyPlugins/Core/AWSPluginsTestCommon",
        exclude: [
            "Info.plist"
        ]
    ),
    .testTarget(
        name: "AWSPluginsCoreTests",
        dependencies: [
            "AWSPluginsCore",
            "AmplifyTestCommon",
            .product(name: "AWSClientRuntime", package: "AWSSwiftSDK")
        ],
        path: "AmplifyPlugins/Core/AWSPluginsCoreTests",
        exclude: [
            "Info.plist"
        ]
    )
]

let apiTargets: [Target] = [
    .target(
        name: "AWSAPIPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .product(name: "AppSyncRealTimeClient", package: "AppSyncRealTimeClient")],
        path: "AmplifyPlugins/API/Sources/AWSAPIPlugin",
        exclude: [
            "Info.plist",
            "AWSAPIPlugin.md"
        ],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "AWSAPIPluginTests",
        dependencies: [
            "AWSAPIPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
        ],
        path: "AmplifyPlugins/API/Tests/AWSAPIPluginTests",
        exclude: [
            "Info.plist"
        ]
    )
]

let authTargets: [Target] = [
    .target(name: "AmplifyBigInteger",
            dependencies: [
                "libtommathAmplify"
            ],
            path: "AmplifyPlugins/Auth/Sources/AmplifyBigInteger"
           ),
    .target(
        name: "AmplifySRP",
        dependencies: [
            .target(name: "AmplifyBigInteger")
        ],
        path: "AmplifyPlugins/Auth/Sources/AmplifySRP"
    ),
    .target(
        name: "AWSCognitoAuthPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AmplifySRP"),
            .target(name: "AWSPluginsCore"),
            .product(name: "AWSClientRuntime", package: "AWSSwiftSDK"),
            .product(name: "AWSCognitoIdentityProvider", package: "AWSSwiftSDK"),
            .product(name: "AWSCognitoIdentity", package: "AWSSwiftSDK")
        ],
        path: "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin",
        swiftSettings: swiftSettings
    ),
    .target(
        name: "libtommathAmplify",
        path: "AmplifyPlugins/Auth/Sources/libtommath",
        exclude: [
            "changes.txt",
            "LICENSE",
            "README.md"
        ],
        cSettings: [
            .unsafeFlags(["-flto=thin"])  // for Dead Code Elimination
        ]    ),
    .testTarget(
        name: "AWSCognitoAuthPluginUnitTests",
        dependencies: [
            "AWSCognitoAuthPlugin",
            "AWSPluginsTestCommon"
        ],
        path: "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests"
    ),
    .testTarget(
        name: "AmplifyBigIntegerTests",
        dependencies: [
            "AmplifyBigInteger"
        ],
        path: "AmplifyPlugins/Auth/Tests/AmplifyBigIntegerUnitTests"
    )
]

let dataStoreTargets: [Target] = [
    .target(
        name: "AWSDataStorePlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .product(name: "SQLite", package: "SQLite.swift")],
        path: "AmplifyPlugins/DataStore/Sources/AWSDataStorePlugin",
        exclude: [
            "Info.plist",
            "Sync/MutationSync/OutgoingMutationQueue/SyncMutationToCloudOperation.mmd"
        ],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "AWSDataStoreCategoryPluginTests",
        dependencies: [
            "AWSDataStorePlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/DataStore/Tests/AWSDataStorePluginTests",
        exclude: [
            "Info.plist"
        ]
    )
]

let storageTargets: [Target] = [
    .target(
        name: "AWSS3StoragePlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .product(name: "AWSS3", package: "AWSSwiftSDK")],
        path: "AmplifyPlugins/Storage/Sources/AWSS3StoragePlugin",
        exclude: [
            "Resources/Info.plist"
        ],
        swiftSettings: swiftSettings
    ),
    .testTarget(
        name: "AWSS3StoragePluginTests",
        dependencies: [
            "AWSS3StoragePlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
        ],
        path: "AmplifyPlugins/Storage/Tests/AWSS3StoragePluginTests",
        exclude: [
            "Resources/Info.plist"
        ]
    )
]

let geoTargets: [Target] = [
    .target(
        name: "AWSLocationGeoPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .product(name: "AWSLocation", package: "AWSSwiftSDK")],
        path: "AmplifyPlugins/Geo/AWSLocationGeoPlugin",
        exclude: [
            "Resources/Info.plist"
        ]
    ),
    .testTarget(
        name: "AWSLocationGeoPluginTests",
        dependencies: [
            "AWSLocationGeoPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
            ],
        path: "AmplifyPlugins/Geo/AWSLocationGeoPluginTests",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: []
    )
]

let analyticsTargets: [Target] = [
    .target(
        name: "AWSPinpointAnalyticsPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSCognitoAuthPlugin"),
            .target(name: "AWSPluginsCore"),
            .product(name: "SQLite", package: "SQLite.swift"),
            .product(name: "AWSPinpoint", package: "AWSSwiftSDK")],
        path: "AmplifyPlugins/Analytics/Sources/AWSPinpointAnalyticsPlugin"
    ),
    .testTarget(
        name: "AWSPinpointAnalyticsPluginUnitTests",
        dependencies: [
            "AWSPinpointAnalyticsPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Analytics/Tests/AWSPinpointAnalyticsPluginUnitTests"
    )
]

let targets: [Target] = amplifyTargets + apiTargets + authTargets + dataStoreTargets + storageTargets + geoTargets + analyticsTargets

let package = Package(
    name: "Amplify",
    platforms: platforms,
    products: [
        .library(
            name: "Amplify",
            targets: ["Amplify"]
        ),
        .library(
            name: "AWSAPIPlugin",
            targets: ["AWSAPIPlugin"]
        ),
        .library(
            name: "AWSCognitoAuthPlugin",
            targets: ["AWSCognitoAuthPlugin"]
        ),
        .library(
            name: "AWSDataStorePlugin",
            targets: ["AWSDataStorePlugin"]
        ),
        .library(
            name: "AWSS3StoragePlugin",
            targets: ["AWSS3StoragePlugin"]
        ),
        .library(
            name: "AWSLocationGeoPlugin",
            targets: ["AWSLocationGeoPlugin"]
        ),
        .library(
            name: "AWSPinpointAnalyticsPlugin",
            targets: ["AWSPinpointAnalyticsPlugin"]
        )
    ],
    dependencies: dependencies,
    targets: targets
)
