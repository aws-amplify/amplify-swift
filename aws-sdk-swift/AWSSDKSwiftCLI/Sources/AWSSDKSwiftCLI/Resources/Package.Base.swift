// swift-tools-version:5.9

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// This manifest is auto-generated.  Do not commit edits to this file;
// they will be overwritten.

import Foundation
import PackageDescription

// MARK: - Target Dependencies

extension Target.Dependency {
    // AWS modules
    static var awsClientRuntime: Self { "AWSClientRuntime" }
    static var awsSDKCommon: Self { "AWSSDKCommon" }
    static var awsSDKEventStreamsAuth: Self { "AWSSDKEventStreamsAuth" }
    static var awsSDKHTTPAuth: Self { "AWSSDKHTTPAuth" }
    static var awsSDKIdentity: Self { "AWSSDKIdentity" }
    static var awsSDKChecksums: Self { "AWSSDKChecksums" }

    // CRT module
    static var crt: Self { .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift") }

    // Smithy modules
    static var clientRuntime: Self { .product(name: "ClientRuntime", package: "smithy-swift") }
    static var smithy: Self { .product(name: "Smithy", package: "smithy-swift") }
    static var smithyChecksumsAPI: Self { .product(name: "SmithyChecksumsAPI", package: "smithy-swift") }
    static var smithyChecksums: Self { .product(name: "SmithyChecksums", package: "smithy-swift") }
    static var smithyEventStreams: Self { .product(name: "SmithyEventStreams", package: "smithy-swift") }
    static var smithyEventStreamsAPI: Self { .product(name: "SmithyEventStreamsAPI", package: "smithy-swift") }
    static var smithyEventStreamsAuthAPI: Self { .product(name: "SmithyEventStreamsAuthAPI", package: "smithy-swift") }
    static var smithyHTTPAPI: Self { .product(name: "SmithyHTTPAPI", package: "smithy-swift") }
    static var smithyHTTPAuth: Self { .product(name: "SmithyHTTPAuth", package: "smithy-swift") }
    static var smithyIdentity: Self { .product(name: "SmithyIdentity", package: "smithy-swift") }
    static var smithyIdentityAPI: Self { .product(name: "SmithyIdentityAPI", package: "smithy-swift") }
    static var smithyRetries: Self { .product(name: "SmithyRetries", package: "smithy-swift") }
    static var smithyRetriesAPI: Self { .product(name: "SmithyRetriesAPI", package: "smithy-swift") }
    static var smithyWaitersAPI: Self { .product(name: "SmithyWaitersAPI", package: "smithy-swift") }
    static var smithyTestUtils: Self { .product(name: "SmithyTestUtil", package: "smithy-swift") }
    static var smithyStreams: Self { .product(name: "SmithyStreams", package: "smithy-swift") }
}

// MARK: - Base Package

let package = Package(
    name: "aws-sdk-swift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "AWSClientRuntime", targets: ["AWSClientRuntime"]),
        .library(name: "AWSSDKCommon", targets: ["AWSSDKCommon"]),
        .library(name: "AWSSDKEventStreamsAuth", targets: ["AWSSDKEventStreamsAuth"]),
        .library(name: "AWSSDKHTTPAuth", targets: ["AWSSDKHTTPAuth"]),
        .library(name: "AWSSDKIdentity", targets: ["AWSSDKIdentity"]),
        .library(name: "AWSSDKChecksums", targets: ["AWSSDKChecksums"]),
    ],
    targets: [
        .target(
            name: "AWSSDKForSwift",
            path: "Sources/Core/AWSSDKForSwift",
            exclude: ["Documentation.docc/AWSSDKForSwift.md"]
        ),
        .target(
            name: "AWSClientRuntime",
            dependencies: [
                .crt,
                .clientRuntime,
                .smithyRetriesAPI,
                .smithyRetries,
                .smithyEventStreamsAPI,
                .smithyEventStreamsAuthAPI,
                .awsSDKCommon,
                .awsSDKHTTPAuth,
                .awsSDKIdentity
            ],
            path: "Sources/Core/AWSClientRuntime/Sources/AWSClientRuntime",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "AWSSDKCommon",
            dependencies: [.crt],
            path: "Sources/Core/AWSSDKCommon/Sources"
        ),
        .target(
            name: "AWSSDKEventStreamsAuth",
            dependencies: [.smithyEventStreamsAPI, .smithyEventStreamsAuthAPI, .smithyEventStreams, .crt, .clientRuntime, "AWSSDKHTTPAuth"],
            path: "Sources/Core/AWSSDKEventStreamsAuth/Sources"
        ),
        .target(
            name: "AWSSDKHTTPAuth",
            dependencies: [.crt, .smithy, .clientRuntime, .smithyHTTPAuth, "AWSSDKIdentity", "AWSSDKChecksums"],
            path: "Sources/Core/AWSSDKHTTPAuth/Sources"
        ),
        .target(
            name: "AWSSDKIdentity",
            dependencies: [.crt, .smithy, .clientRuntime, .smithyIdentity, .smithyIdentityAPI, .smithyHTTPAPI, .awsSDKCommon],
            path: "Sources/Core/AWSSDKIdentity/Sources"
        ),
        .target(
            name: "AWSSDKChecksums",
            dependencies: [.crt, .smithy, .clientRuntime, .smithyChecksumsAPI, .smithyChecksums, .smithyHTTPAPI],
            path: "Sources/Core/AWSSDKChecksums/Sources"
        ),
        .testTarget(
            name: "AWSClientRuntimeTests",
            dependencies: [.awsClientRuntime, .clientRuntime, .smithyTestUtils, .awsSDKCommon],
            path: "Sources/Core/AWSClientRuntime/Tests/AWSClientRuntimeTests",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AWSSDKEventStreamsAuthTests",
            dependencies: ["AWSClientRuntime", "AWSSDKEventStreamsAuth", .smithyStreams, .smithyTestUtils],
            path: "Sources/Core/AWSSDKEventStreamsAuth/Tests/AWSSDKEventStreamsAuthTests"
        ),
        .testTarget(
            name: "AWSSDKHTTPAuthTests",
            dependencies: ["AWSSDKHTTPAuth", "AWSClientRuntime", "AWSSDKEventStreamsAuth", .crt, .clientRuntime, .smithyTestUtils],
            path: "Sources/Core/AWSSDKHTTPAuth/Tests/AWSSDKHTTPAuthTests"
        ),
        .testTarget(
            name: "AWSSDKIdentityTests",
            dependencies: [.smithy, .smithyIdentity, "AWSSDKIdentity", .awsClientRuntime],
            path: "Sources/Core/AWSSDKIdentity/Tests/AWSSDKIdentityTests",
            resources: [.process("Resources")]
        )
    ]
)

// MARK: - Dependencies

func addDependencies(clientRuntimeVersion: Version, crtVersion: Version) {
    addClientRuntimeDependency(clientRuntimeVersion)
    addCRTDependency(crtVersion)
    addDoccDependency()
}

func addClientRuntimeDependency(_ version: Version) {
    let smithySwiftURL = "https://github.com/smithy-lang/smithy-swift"
    let useLocalDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_LOCAL_DEPS"] != nil
    let useMainDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_MAIN_DEPS"] != nil
    switch (useLocalDeps, useMainDeps) {
    case (true, true):
        fatalError("Unable to determine which dependencies to use. Please only specify one of AWS_SWIFT_SDK_USE_LOCAL_DEPS or AWS_SWIFT_SDK_USE_MAIN_DEPS.")
    case (true, false):
        package.dependencies += [
            .package(path: "../smithy-swift")
        ]
    case (false, true):
        package.dependencies += [
            .package(url: smithySwiftURL, branch: "main")
        ]
    case (false, false):
        package.dependencies += [
            .package(url: smithySwiftURL, exact: version)
        ]
    }
}

func addCRTDependency(_ version: Version) {
    package.dependencies += [
        .package(url: "https://github.com/awslabs/aws-crt-swift", exact: version)
    ]
}

func addDoccDependency() {
    guard ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_ENABLE_DOCC"] != nil else { return }
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ]
}

// MARK: - Services

let serviceTargetDependencies: [Target.Dependency] = [
    .clientRuntime,
    .awsClientRuntime,
    .smithyRetriesAPI,
    .smithyRetries,
    .smithy,
    .smithyIdentity,
    .smithyIdentityAPI,
    .smithyEventStreamsAPI,
    .smithyEventStreamsAuthAPI,
    .smithyEventStreams,
    .smithyChecksumsAPI,
    .smithyChecksums,
    .smithyWaitersAPI,
    .awsSDKCommon,
    .awsSDKIdentity,
    .awsSDKHTTPAuth,
    .awsSDKEventStreamsAuth,
    .awsSDKChecksums,
]

func addServiceTarget(_ name: String) {
    package.products += [
        .library(name: name, targets: [name]),
    ]
    package.targets += [
        .target(
            name: name,
            dependencies: serviceTargetDependencies,
            path: "Sources/Services/\(name)/Sources/\(name)",
            resources: [.process("Resources")]
        )
    ]
}

func addServiceUnitTestTarget(_ name: String) {
    let testName = "\(name)Tests"
    package.targets += [
        .testTarget(
            name: "\(testName)",
            dependencies: [.clientRuntime, .awsClientRuntime, .byName(name: name), .smithyTestUtils],
            path: "Sources/Services/\(name)/Tests/\(testName)"
        )
    ]
}

var enabledServices = Set<String>()
var enabledServiceUnitTests = Set<String>()

func addAllServices() {
    enabledServices = Set(serviceTargets)
    enabledServiceUnitTests = Set(serviceTargets)
}

func excludeRuntimeUnitTests() {
    package.targets.removeAll {
        $0.name == "AWSClientRuntimeTests" ||
        $0.name == "AWSSDKHTTPAuthTests" ||
        $0.name == "AWSSDKEventStreamsAuthTests" ||
        $0.name == "AWSSDKIdentityTests"
    }
}

func addResolvedTargets() {
    enabledServices.forEach(addServiceTarget)
    enabledServiceUnitTests.forEach(addServiceUnitTestTarget)
}
