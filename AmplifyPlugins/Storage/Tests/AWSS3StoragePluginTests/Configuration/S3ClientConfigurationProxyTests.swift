//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSS3
import ClientRuntime
import Foundation
import XCTest

@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class S3ClientConfigurationAccelerateTestCase: XCTestCase, @unchecked Sendable {

    /// Given: A base configuration that has a value for a property such as `accelerate`.
    /// When: An override is set through `withAccelerate(_:)`
    /// Then: The base configuration is not mutated.
    func testPropertyOverrides() async throws {
        let baseConfiguration = try configuration(accelerate: true)
        let sut = try baseConfiguration.withAccelerate(false)
        XCTAssertEqual(sut.accelerate, false)
        XCTAssertEqual(baseConfiguration.accelerate, true)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a `nil` value.
    /// Then: The configuration is returned unchanged.
    func test_copySemantics_nilAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try configuration(accelerate: baseAccelerate)

        let nilAccelerate = try baseConfiguration.withAccelerate(nil)
        XCTAssertEqual(nilAccelerate.accelerate, baseAccelerate)
        assertSameSettings(nilAccelerate, baseConfiguration)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a non-nil value equal to that of the existing config's.
    /// Then: The configuration is returned unchanged.
    func test_copySemantics_equalAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try configuration(accelerate: baseAccelerate)

        let equalAccelerate = try baseConfiguration.withAccelerate(baseAccelerate)
        XCTAssertEqual(equalAccelerate.accelerate, baseAccelerate)
        assertSameSettings(equalAccelerate, baseConfiguration)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a non-nil value **not** equal to that of the existing config's.
    /// Then: Only `accelerate` differs in the returned configuration, and the existing one is unchanged.
    func test_copySemantics_nonEqualAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try configuration(accelerate: baseAccelerate)

        let nonEqualAccelerate = try baseConfiguration.withAccelerate(!baseAccelerate)
        XCTAssertEqual(nonEqualAccelerate.accelerate, !baseAccelerate)
        XCTAssertEqual(baseConfiguration.accelerate, baseAccelerate)
        assertSameSettings(nonEqualAccelerate, baseConfiguration)
    }

    // Helper configuration method
    private func configuration(accelerate: Bool) throws -> S3Client.S3ClientConfig {
        let baseConfiguration = try S3Client.S3ClientConfig(
            useFIPS: .random(),
            useDualStack: .random(),
            appID: UUID().uuidString,
            awsCredentialIdentityResolver: nil,
            region: "us-east-1",
            signingRegion: UUID().uuidString,
            forcePathStyle: .random(),
            useArnRegion: .random(),
            disableMultiRegionAccessPoints: .random(),
            accelerate: accelerate,
            useGlobalEndpoint: .random(),
            endpoint: UUID().uuidString
        )

        return baseConfiguration
    }

    private func assertSameSettings(
        _ actual: S3Client.S3ClientConfig,
        _ expected: S3Client.S3ClientConfig,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.useFIPS, expected.useFIPS, file: file, line: line)
        XCTAssertEqual(actual.useDualStack, expected.useDualStack, file: file, line: line)
        XCTAssertEqual(actual.appID, expected.appID, file: file, line: line)
        XCTAssertEqual(actual.region, expected.region, file: file, line: line)
        XCTAssertEqual(actual.signingRegion, expected.signingRegion, file: file, line: line)
        XCTAssertEqual(actual.forcePathStyle, expected.forcePathStyle, file: file, line: line)
        XCTAssertEqual(actual.useArnRegion, expected.useArnRegion, file: file, line: line)
        XCTAssertEqual(actual.disableMultiRegionAccessPoints, expected.disableMultiRegionAccessPoints, file: file, line: line)
        XCTAssertEqual(actual.useGlobalEndpoint, expected.useGlobalEndpoint, file: file, line: line)
        XCTAssertEqual(actual.endpoint, expected.endpoint, file: file, line: line)
    }
}
