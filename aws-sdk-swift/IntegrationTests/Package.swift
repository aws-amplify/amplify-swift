// swift-tools-version:5.9

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PackageDescription

// MARK: - Target dependencies

extension Target.Dependency {
    // Test utility module
    static var awsIntegrationTestUtils: Self { "AWSIntegrationTestUtils" }

    // AWS modules
    static var awsClientRuntime: Self { .product(name: "AWSClientRuntime", package: "aws-sdk-swift") }
    static var awsSDKCommon: Self { .product(name: "AWSSDKCommon", package: "aws-sdk-swift") }
    static var awsSDKIdentity: Self { .product(name: "AWSSDKIdentity", package: "aws-sdk-swift") }

    // CRT module
    static var crt: Self { .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift") }

    // Smithy modules
    static var clientRuntime: Self { .product(name: "ClientRuntime", package: "smithy-swift") }
    static var smithyIdentity: Self { .product(name: "SmithyIdentity", package: "smithy-swift") }
    static var smithyTestUtils: Self { .product(name: "SmithyTestUtil", package: "smithy-swift") }
}

// MARK: - Base Package

let package = Package(
    name: "aws-sdk-swift-integration-tests",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    targets: [
        .target(
            name: "AWSIntegrationTestUtils",
            path: "./AWSIntegrationTestUtils"
        )
    ]
)

// MARK: - CRT, Smithy ClientRuntime, AWS ClientRuntime Dependencies

func addDependencies() {
    addRuntimeDependencies()
    addCRTDependency()
}

func addRuntimeDependencies() {
    let smithySwiftURL = "https://github.com/smithy-lang/smithy-swift"
    let awsSDKSwiftURL = "https://github.com/awslabs/aws-sdk-swift"
    let useLocalDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_LOCAL_DEPS"] != nil
    let useMainDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_MAIN_DEPS"] != nil
    switch (useLocalDeps, useMainDeps) {
    case (true, true):
        fatalError("Unable to determine which dependencies to use. Please only specify one of AWS_SWIFT_SDK_USE_LOCAL_DEPS or AWS_SWIFT_SDK_USE_MAIN_DEPS.")
    case (true, false):
        package.dependencies += [
            .package(path: "../../smithy-swift"),
            .package(path: "../../aws-sdk-swift")
        ]
    case (false, true):
        package.dependencies += [
            .package(url: smithySwiftURL, branch: "main"),
            .package(url: awsSDKSwiftURL, branch: "main")
        ]
    case (false, false):
        package.dependencies += [
            .package(url: smithySwiftURL, .upToNextMajor(from: "0.0.0")),
            .package(url: awsSDKSwiftURL, .upToNextMajor(from: "0.0.0"))
        ]
    }
}

func addCRTDependency() {
    package.dependencies += [
        .package(url: "https://github.com/awslabs/aws-crt-swift", .upToNextMajor(from: "0.0.0"))
    ]
}

// MARK: - Integration test target helper functions


func addIntegrationTestTarget(_ name: String) {
    let integrationTestName = "\(name)IntegrationTests"
    var additionalDependencies: [String] = []
    var exclusions: [String] = []
    switch name {
    case "AWSEC2":
        additionalDependencies = ["AWSIAM", "AWSSTS", "AWSCloudWatchLogs"]
        exclusions = [
            "Resources/IMDSIntegTestApp"
        ]
    case "AWSECS":
        additionalDependencies = ["AWSCloudWatchLogs", "AWSEC2",  "AWSIAM", "AWSSTS"]
        exclusions = [
            "README.md",
            "Resources/ECSIntegTestApp/"
        ]
    case "AWSGlacier":
        additionalDependencies = ["AWSSTS"]
    case "AWSS3":
        additionalDependencies = ["AWSSSOAdmin", "AWSS3Control", "AWSSTS"]
    case "AWSEventBridge":
        additionalDependencies = ["AWSRoute53"]
    case "AWSCloudFrontKeyValueStore":
        additionalDependencies = ["AWSCloudFront"]
    case "AWSSTS":
        additionalDependencies = ["AWSIAM", "AWSCognitoIdentity"]
    case "AWSCognitoIdentity":
        additionalDependencies = ["AWSSTS"]
    default:
        break
    }
    package.targets += [
        .testTarget(
            name: integrationTestName,
            dependencies: [
                .crt,
                .clientRuntime,
                .awsClientRuntime,
                .smithyTestUtils,
                .awsSDKIdentity,
                .smithyIdentity,
                .awsSDKCommon,
                .awsIntegrationTestUtils,
                .product(name: name, package: "aws-sdk-swift")
            ] + additionalDependencies.map {
                Target.Dependency.product(name: $0, package: "aws-sdk-swift", condition: nil)
            },
            path: "./Services/\(integrationTestName)",
            exclude: exclusions,
            resources: [.process("Resources")]
        )
    ]
}

let servicesWithIntegrationTests: [String] = [
    "AWSCloudFrontKeyValueStore",
    "AWSEC2",
    "AWSECS",
    "AWSEventBridge",
    "AWSGlacier",
    "AWSKinesis",
    "AWSMediaConvert",
    "AWSRoute53",
    "AWSS3",
    "AWSSQS",
    "AWSSTS",
    "AWSTranscribeStreaming",
    "AWSCognitoIdentity",
]

func addIntegrationTests() {
    servicesWithIntegrationTests.forEach { addIntegrationTestTarget($0) }
}

addDependencies()
addIntegrationTests()
