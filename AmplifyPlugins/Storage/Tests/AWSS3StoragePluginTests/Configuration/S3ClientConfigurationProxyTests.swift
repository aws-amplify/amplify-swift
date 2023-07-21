//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import AWSClientRuntime
import ClientRuntime
import Foundation
import XCTest

@testable import AWSS3StoragePlugin

final class S3ClientConfigurationProxyTests: XCTestCase {

    /// Given: A client configuration that has a value for a property such as `accelerate`.
    /// When: An override is set on its proxy configuration.
    /// Then: The proxy returns the value from the override.
    func testPropertyOverrides() async throws {
        let target = try await S3Client.S3ClientConfiguration()
        target.accelerate = true
        
        let sut = S3ClientConfigurationProxy(target: target, accelerateOverride: false)
        XCTAssertEqual(sut.accelerate, false)
        XCTAssertEqual(target.accelerate, true)
    }

    /// Given: A client configuration with random values.
    /// When: A proxy configuration around it is created **without overrides**.
    /// Then: The values returned by the proxy are equal to those from the **client configuration**.
    func testPropertyBypass() async throws {
        let target = try await S3Client.S3ClientConfiguration(
            accelerate: Bool.random(),
            credentialsProvider: nil,
            disableMultiRegionAccessPoints: Bool.random(),
            endpoint: UUID().uuidString,
            endpointResolver: nil,
            forcePathStyle: Bool.random(),
            frameworkMetadata: nil,
            regionResolver: nil,
            signingRegion: UUID().uuidString,
            useArnRegion: Bool.random(),
            useDualStack: Bool.random(),
            useFIPS: Bool.random(),
            useGlobalEndpoint: Bool.random()
        )
        
        var sut = S3ClientConfigurationProxy(target: target, accelerateOverride: nil)
        XCTAssertEqual(sut.accelerate, target.accelerate)
        XCTAssertEqual(sut.disableMultiRegionAccessPoints, target.disableMultiRegionAccessPoints)
        XCTAssertEqual(sut.forcePathStyle, target.forcePathStyle)
        XCTAssertEqual(sut.useArnRegion, target.useArnRegion)
        XCTAssertEqual(sut.useDualStack, target.useDualStack)
        XCTAssertEqual(sut.region, target.region)
        XCTAssertEqual(sut.signingRegion, target.signingRegion)
        XCTAssertEqual(sut.useFIPS, target.useFIPS)
        XCTAssertEqual(sut.useGlobalEndpoint, target.useGlobalEndpoint)
        XCTAssertEqual(sut.endpoint, target.endpoint)

        sut.region = UUID().uuidString
        sut.signingRegion = UUID().uuidString
        sut.useFIPS = !(sut.useFIPS ?? false)
        sut.useDualStack = !(sut.useDualStack ?? false)
        sut.endpoint = UUID().uuidString

        XCTAssertEqual(sut.accelerate, target.accelerate)
        XCTAssertEqual(sut.disableMultiRegionAccessPoints, target.disableMultiRegionAccessPoints)
        XCTAssertEqual(sut.forcePathStyle, target.forcePathStyle)
        XCTAssertEqual(sut.useArnRegion, target.useArnRegion)
        XCTAssertEqual(sut.useDualStack, target.useDualStack)
        XCTAssertEqual(sut.region, target.region)
        XCTAssertEqual(sut.signingRegion, target.signingRegion)
        XCTAssertEqual(sut.useFIPS, target.useFIPS)
        XCTAssertEqual(sut.useGlobalEndpoint, target.useGlobalEndpoint)
        XCTAssertEqual(sut.endpoint, target.endpoint)
    }
}
