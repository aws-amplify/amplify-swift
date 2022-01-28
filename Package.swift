// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let amplifyTargets: [Target] = [
    .target(
        name: "Amplify",
        path: "Amplify",
        exclude: [
            "Info.plist",
            "Categories/DataStore/Model/Temporal/README.md"
        ]
    ),
    .testTarget(
        name: "AmplifyTests",
        dependencies: [
            "Amplify",
            "AmplifyTestCommon"
        ],
        path: "AmplifyTests"
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
            "Info.plist"
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
        name: "AWSPluginsTestCommon",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            .product(name: "AWSClientRuntime", package: "AWSSwiftSDK")
        ],
        path: "AmplifyPlugins/Core/AWSPluginsTestCommon"
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
]

let apiTargets: [Target] = [
    .target(
        name: "AWSAPIPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .product(name: "AppSyncRealTimeClient", package: "AppSyncRealTimeClient")],
        path: "AmplifyPlugins/API/AWSAPICategoryPlugin",
        exclude: [
            "Info.plist",
            "AWSAPIPlugin.md"
        ]
    ),
    .testTarget(
        name: "AWSAPIPluginTests",
        dependencies: [
            "AWSAPIPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon"
        ],
        path: "AmplifyPlugins/API/AWSAPICategoryPluginTests"
    ),
    .testTarget(
        name: "AWSAPICategoryPluginFunctionalTests",
        dependencies: [
            "AWSAPIPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/API/AWSAPICategoryPluginFunctionalTests",
        resources: [
            .process("Resources/GraphQLModelBasedTests-amplifyconfiguration.json")
        ]
    ),
    .testTarget(
        name: "GraphQLWithIAMIntegrationTests",
        dependencies: [
            "AWSAPIPlugin",
            "AWSCognitoAuthPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/API/AWSAPICategoryPluginIntegrationTests/GraphQL/GraphQLWithIAMIntegrationTests/",
        resources: [
            .process("Resources/GraphQLWithIAMIntegrationTests-amplifyconfiguration.json"),
            .process("Resources/GraphQLWithIAMIntegrationTests-credentials.json")
        ]
    ),
    .testTarget(
        name: "RESTWithIAMIntegrationTests",
        dependencies: [
            "AWSAPIPlugin",
            "AWSCognitoAuthPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/API/AWSAPICategoryPluginIntegrationTests/REST/RESTWithIAMIntegrationTests/",
        resources: [
            .process("Resources/RESTWithIAMIntegrationTests-amplifyconfiguration.json")
        ]
    ),
]

let authTargets: [Target] = [
    .target(name: "AmplifyBigInteger",
            dependencies: [
                "libtommath"
            ],
            path: "AmplifyPlugins/Auth/Sources/AmplifyBigInteger"
           ),
    .target(
        name: "AmplifySRP",
        dependencies: [
            .target(name: "AmplifyBigInteger"),
        ],
        path: "AmplifyPlugins/Auth/Sources/AmplifySRP"
    ),
    .target(
        name: "AWSCognitoAuthPlugin",
        dependencies: [
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
        name: "AmplifyBigIntegerTests",
        dependencies: [
            "AmplifyBigInteger"
        ],
        path: "AmplifyPlugins/Auth/Tests/AmplifyBigIntegerUnitTests"
    ),
]

let dataStoreTargets: [Target] = [
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
    .testTarget(
        name: "AWSDataStoreCategoryPluginTests",
        dependencies: [
            "AWSDataStorePlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/DataStore/AWSDataStoreCategoryPluginTests"
    ),
    .testTarget(
        name: "AWSDataStoreCategoryPluginIntegrationTests",
        dependencies: [
            "AWSDataStorePlugin",
            "AWSAPIPlugin",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/DataStore/AWSDataStoreCategoryPluginIntegrationTests",
        resources: [
            .process("Resources/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration.json")
        ]
    ),
]

let targets: [Target] = amplifyTargets + apiTargets + authTargets + dataStoreTargets

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v13)],
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
        
    ],
    dependencies: [
        .package(
            url: "https://github.com/libtom/libtommath",
            branch: "develop"
        ),
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            .exact("0.12.2")
        ),
        .package(
            name: "AppSyncRealTimeClient",
            url: "https://github.com/aws-amplify/aws-appsync-realtime-client-ios.git",
            from: "1.4.3"
        ),
        .package(
            name: "AWSSwiftSDK",
            url: "https://github.com/awslabs/aws-sdk-swift",
            .upToNextMajor(from: "0.1.0")
        ),
        .package(
            name: "CwlPreconditionTesting",
            url: "https://github.com/mattgallagher/CwlPreconditionTesting",
            .upToNextMinor(from: "2.1.0"))
    ],
    targets: targets
)
