// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let platforms: [SupportedPlatform] = [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v9)
]
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/awslabs/aws-sdk-swift.git", exact: "0.36.2"),
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.15.3"),
    .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.1.0"),
    .package(url: "https://github.com/aws-amplify/amplify-swift-utils-notifications.git", from: "1.1.0")
]

let amplifyTargets: [Target] = [
    .target(
        name: "Amplify",
        path: "Amplify",
        exclude: [
            "Info.plist",
            "Categories/DataStore/Model/Temporal/README.md"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "AWSPluginsCore",
        dependencies: [
            "Amplify"
        ],
        path: "AmplifyPlugins/Core/AWSPluginsCore",
        exclude: [
            "Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "InternalAmplifyCredentials",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Core/AmplifyCredentials",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "AmplifyTestCommon",
        dependencies: [
            "Amplify",
            "CwlPreconditionTesting",
            "InternalAmplifyCredentials"
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
            "AmplifyTestCommon",
            "AmplifyAsyncTesting"
        ],
        path: "AmplifyTests",
        exclude: [
            "Info.plist",
            "CoreTests/README.md"
        ]
    ),
    .target(
        name: "AmplifyAsyncTesting",
        dependencies: [],
        path: "AmplifyAsyncTesting/Sources/AsyncTesting",
        linkerSettings: [.linkedFramework("XCTest")]
    ),
    .testTarget(
        name: "AmplifyAsyncTestingTests",
        dependencies: ["AmplifyAsyncTesting"],
        path: "AmplifyAsyncTesting/Tests/AsyncTestingTests"
    ),
    .target(
        name: "AWSPluginsTestCommon",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            "InternalAmplifyCredentials",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
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
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Core/AWSPluginsCoreTests",
        exclude: [
            "Info.plist"
        ]
    ),
    .testTarget(
        name: "InternalAmplifyCredentialsTests",
        dependencies: [
            "InternalAmplifyCredentials",
            "AmplifyTestCommon",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Core/AmplifyCredentialsTests"
    )
]

let apiTargets: [Target] = [
    .target(
        name: "AWSAPIPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "InternalAmplifyCredentials")
        ],
        path: "AmplifyPlugins/API/Sources/AWSAPIPlugin",
        exclude: [
            "Info.plist",
            "AWSAPIPlugin.md"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSAPIPluginTests",
        dependencies: [
            "AWSAPIPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon",
            "AmplifyAsyncTesting"
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
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift"),
            .product(name: "AWSCognitoIdentityProvider", package: "aws-sdk-swift"),
            .product(name: "AWSCognitoIdentity", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "libtommathAmplify",
        path: "AmplifyPlugins/Auth/Sources/libtommath",
        exclude: [
            "changes.txt",
            "LICENSE",
            "README.md"
        ]
    ),
    .testTarget(
        name: "AWSCognitoAuthPluginUnitTests",
        dependencies: [
            "AWSCognitoAuthPlugin",
            "AWSPluginsTestCommon",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests",
        resources: [.copy("TestResources")]
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
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSDataStoreCategoryPluginTests",
        dependencies: [
            "AWSDataStorePlugin",
            "AmplifyTestCommon",
            "AmplifyAsyncTesting"
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
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "AWSS3", package: "aws-sdk-swift")],
        path: "AmplifyPlugins/Storage/Sources/AWSS3StoragePlugin",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSS3StoragePluginTests",
        dependencies: [
            "AWSS3StoragePlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon",
            "AmplifyAsyncTesting"
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
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "AWSLocation", package: "aws-sdk-swift")],
        path: "AmplifyPlugins/Geo/Sources/AWSLocationGeoPlugin",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSLocationGeoPluginTests",
        dependencies: [
            "AWSLocationGeoPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
            ],
        path: "AmplifyPlugins/Geo/Tests/AWSLocationGeoPluginTests",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: []
    )
]

let internalPinpointTargets: [Target] = [
    .target(
        name: "InternalAWSPinpoint",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSCognitoAuthPlugin"),
            .target(name: "AWSPluginsCore"),
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "SQLite", package: "SQLite.swift"),
            .product(name: "AWSPinpoint", package: "aws-sdk-swift"),
            .product(name: "AmplifyUtilsNotifications", package: "amplify-swift-utils-notifications")
        ],
        path: "AmplifyPlugins/Internal/Sources/InternalAWSPinpoint",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "InternalAWSPinpointUnitTests",
        dependencies: [
            "InternalAWSPinpoint",
            "AmplifyTestCommon",
            "AmplifyAsyncTesting"
        ],
        path: "AmplifyPlugins/Internal/Tests/InternalAWSPinpointUnitTests"
    )
]

let analyticsTargets: [Target] = [
    .target(
        name: "AWSPinpointAnalyticsPlugin",
        dependencies: [
            .target(name: "InternalAWSPinpoint")
        ],
        path: "AmplifyPlugins/Analytics/Sources/AWSPinpointAnalyticsPlugin",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
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

let pushNotificationsTargets: [Target] = [
    .target(
        name: "AWSPinpointPushNotificationsPlugin",
        dependencies: [
            .target(name: "InternalAWSPinpoint")
        ],
        path: "AmplifyPlugins/Notifications/Push/Sources/AWSPinpointPushNotificationsPlugin",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSPinpointPushNotificationsPluginUnitTests",
        dependencies: [
            "AWSPinpointPushNotificationsPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Notifications/Push/Tests/AWSPinpointPushNotificationsPluginUnitTests"
    )
]

let predictionsTargets: [Target] = [
    .target(
        name: "AWSPredictionsPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .target(name: "InternalAmplifyCredentials"),
            .target(name: "CoreMLPredictionsPlugin"),
            .product(name: "AWSComprehend", package: "aws-sdk-swift"),
            .product(name: "AWSPolly", package: "aws-sdk-swift"),
            .product(name: "AWSRekognition", package: "aws-sdk-swift"),
            .product(name: "AWSTextract", package: "aws-sdk-swift"),
            .product(name: "AWSTranscribeStreaming", package: "aws-sdk-swift"),
            .product(name: "AWSTranslate", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Predictions/AWSPredictionsPlugin",
        exclude: [],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSPredictionsPluginUnitTests",
        dependencies: ["AWSPredictionsPlugin"],
        path: "AmplifyPlugins/Predictions/Tests/AWSPredictionsPluginUnitTests",
        resources: [.copy("TestResources/TestImages") ]
    ),
    .target(
        name: "CoreMLPredictionsPlugin",
        dependencies: [
            .target(name: "Amplify")
        ],
        path: "AmplifyPlugins/Predictions/CoreMLPredictionsPlugin",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "CoreMLPredictionsPluginUnitTests",
        dependencies: [
            "CoreMLPredictionsPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Predictions/Tests/CoreMLPredictionsPluginUnitTests",
        resources: [.copy("TestResources/TestImages")]
    )
]

let loggingTargets: [Target] = [
    .target(
        name: "AWSCloudWatchLoggingPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "AWSCloudWatchLogs", package: "aws-sdk-swift"),
        ],
        path: "AmplifyPlugins/Logging/Sources/AWSCloudWatchLoggingPlugin",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSCloudWatchLoggingPluginTests",
        dependencies: [
            "AWSCloudWatchLoggingPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
        ],
        path: "AmplifyPlugins/Logging/Tests/AWSCloudWatchLoggingPluginTests",
        resources: [
            .copy("TestResources")
        ]
    )
]

let targets: [Target] = amplifyTargets
    + apiTargets
    + authTargets
    + dataStoreTargets
    + storageTargets
    + geoTargets
    + analyticsTargets
    + pushNotificationsTargets
    + internalPinpointTargets
    + predictionsTargets
    + loggingTargets

let package = Package(
    name: "Amplify",
    platforms: platforms,
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
        ),
        .library(
            name: "AWSPinpointPushNotificationsPlugin",
            targets: ["AWSPinpointPushNotificationsPlugin"]
        ),
        .library(
            name: "AWSPredictionsPlugin",
            targets: ["AWSPredictionsPlugin"]
        ),
        .library(
            name: "CoreMLPredictionsPlugin",
            targets: ["CoreMLPredictionsPlugin"]
        ),
        .library(
            name: "AWSCloudWatchLoggingPlugin",
            targets: ["AWSCloudWatchLoggingPlugin"]
        ),
    ],
    dependencies: dependencies,
    targets: targets
)
