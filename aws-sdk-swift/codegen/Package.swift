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
    // AWS modules
    static var awsClientRuntime: Self { .product(name: "AWSClientRuntime", package: "aws-sdk-swift") }
    static var awsSDKCommon: Self { .product(name: "AWSSDKCommon", package: "aws-sdk-swift") }
    static var awsSDKEventStreamsAuth: Self { .product(name: "AWSSDKEventStreamsAuth", package: "aws-sdk-swift") }
    static var awsSDKHTTPAuth: Self { .product(name: "AWSSDKHTTPAuth", package: "aws-sdk-swift") }
    static var awsSDKIdentity: Self { .product(name: "AWSSDKIdentity", package: "aws-sdk-swift") }
    static var awsSDKChecksums: Self { .product(name: "AWSSDKChecksums", package: "aws-sdk-swift") }

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
    name: "aws-sdk-swift-protocol-tests",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ]
)

// MARK: - CRT, Smithy ClientRuntime, AWS ClientRuntime Dependencies

func addDependencies() {
    addClientRuntimeDependency()
    addAWSClientRuntimeDependency()
    addCRTDependency()
}

func addClientRuntimeDependency() {
    let smithySwiftURL = "https://github.com/smithy-lang/smithy-swift"
    let useLocalDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_LOCAL_DEPS"] != nil
    let useMainDeps = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_MAIN_DEPS"] != nil
    switch (useLocalDeps, useMainDeps) {
    case (true, true):
        fatalError("Unable to determine which dependencies to use. Please only specify one of AWS_SWIFT_SDK_USE_LOCAL_DEPS or AWS_SWIFT_SDK_USE_MAIN_DEPS.")
    case (true, false):
        package.dependencies += [
            .package(path: "../../smithy-swift")
        ]
    case (false, true):
        package.dependencies += [
            .package(url: smithySwiftURL, branch: "main")
        ]
    case (false, false):
        package.dependencies += [
            .package(url: smithySwiftURL, .upToNextMajor(from: "0.0.0"))
        ]
    }
}

func addAWSClientRuntimeDependency() {
    package.dependencies += [
        .package(path: "../../aws-sdk-swift")
    ]
}

func addCRTDependency() {
    package.dependencies += [
        .package(url: "https://github.com/awslabs/aws-crt-swift", .upToNextMajor(from: "0.0.0"))
    ]
}

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

func addProtocolTests() {
    struct ProtocolTest {
        let name: String
        let sourcePath: String
        let testPath: String?
        let buildOnly: Bool

        init(name: String, sourcePath: String, testPath: String? = nil, buildOnly: Bool = false) {
            self.name = name
            self.sourcePath = sourcePath
            self.testPath = testPath
            self.buildOnly = buildOnly
        }
    }

    let baseDir = "../codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen"
    let baseDirLocal = "../codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local"

    let protocolTests: [ProtocolTest] = [
        .init(name: "AWSRestJsonTestSDK", sourcePath: "\(baseDir)/aws-restjson"),
        .init(name: "AWSRestJsonValidationTestSDK", sourcePath: "\(baseDir)/aws-restjson-validation"),
        .init(name: "AWSJson1_0TestSDK", sourcePath: "\(baseDir)/aws-json-10"),
        .init(name: "AWSJson1_1TestSDK", sourcePath: "\(baseDir)/aws-json-11"),
        .init(name: "RestXmlTestSDK", sourcePath: "\(baseDir)/rest-xml"),
        .init(name: "RestXmlWithNamespaceTestSDK", sourcePath: "\(baseDir)/rest-xml-xmlns"),
        .init(name: "Ec2QueryTestSDK", sourcePath: "\(baseDir)/ec2-query"),
        .init(name: "AWSQueryTestSDK", sourcePath: "\(baseDir)/aws-query"),
        .init(name: "APIGatewayTestSDK", sourcePath: "\(baseDir)/apigateway"),
        .init(name: "GlacierTestSDK", sourcePath: "\(baseDir)/glacier"),
        .init(name: "MachineLearningTestSDK", sourcePath: "\(baseDir)/machinelearning"),
        .init(name: "S3TestSDK", sourcePath: "\(baseDir)/s3"),
        .init(name: "rest_json_extras", sourcePath: "\(baseDirLocal)/rest_json_extras"),
        .init(name: "AwsQueryExtras", sourcePath: "\(baseDirLocal)/AwsQueryExtras"),
        .init(name: "EventStream", sourcePath: "\(baseDirLocal)/EventStream", buildOnly: true),
        .init(name: "RPCEventStream", sourcePath: "\(baseDirLocal)/RPCEventStream", buildOnly: true),
        .init(name: "Waiters", sourcePath: "\(baseDirLocal)/Waiters", testPath: "../codegen/protocol-test-codegen-local/Tests"),
        .init(name: "StringArrayEndpointParam", sourcePath: "\(baseDirLocal)/StringArrayEndpointParam")
    ]
    for protocolTest in protocolTests {
        let target = Target.target(
            name: protocolTest.name,
            dependencies: serviceTargetDependencies,
            path: "\(protocolTest.sourcePath)/swift-codegen/Sources/\(protocolTest.name)"
        )
        let testTarget = protocolTest.buildOnly ? nil : Target.testTarget(
            name: "\(protocolTest.name)Tests",
            dependencies: [.smithyTestUtils, .smithyStreams, .smithyWaitersAPI, .byNameItem(name: protocolTest.name, condition: nil)],
            path: "\(protocolTest.testPath ?? protocolTest.sourcePath)/swift-codegen/Tests/\(protocolTest.name)Tests"
        )
        package.targets += [target, testTarget].compactMap { $0 }
    }
}

addDependencies()
addProtocolTests()
