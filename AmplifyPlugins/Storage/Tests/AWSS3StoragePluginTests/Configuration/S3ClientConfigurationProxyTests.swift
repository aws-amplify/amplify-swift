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

final class S3ClientConfigurationAccelerateTestCase: XCTestCase {

    /// Given: A base configuration that has a value for a property such as `accelerate`.
    /// When: An override is set through `withAccelerate(_:)`
    /// Then: The base configuration is not mutated.
    func testPropertyOverrides() async throws {
        let baseConfiguration = try await configuration(accelerate: true)
        let sut = try baseConfiguration.withAccelerate(false)
        XCTAssertEqual(sut.accelerate, false)
        XCTAssertEqual(baseConfiguration.accelerate, true)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a `nil` value.
    /// Then: The existing and new configurations should share a reference.
    func test_copySemantics_nilAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try await configuration(accelerate: baseAccelerate)

        let nilAccelerate = try baseConfiguration.withAccelerate(nil)
        XCTAssert(baseConfiguration === nilAccelerate)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a non-nil value equal to that of the existing config's.
    /// Then: The existing and new configurations should share a reference.
    func test_copySemantics_equalAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try await configuration(accelerate: baseAccelerate)

        let equalAccelerate = try baseConfiguration.withAccelerate(baseAccelerate)
        XCTAssert(baseConfiguration === equalAccelerate)
    }

    /// Given: A client configuration.
    /// When: Calling `withAccelerate` with a non-nil value **not** equal to that of the existing config's.
    /// Then: The existing and new configurations should not share a reference.
    func test_copySemantics_nonEqualAccelerate() async throws {
        let baseAccelerate = Bool.random()
        let baseConfiguration = try await configuration(accelerate: baseAccelerate)

        let nonEqualAccelerate = try baseConfiguration.withAccelerate(!baseAccelerate)
        XCTAssert(baseConfiguration !== nonEqualAccelerate)
    }


    // Helper configuration method
    private func configuration(accelerate: Bool) async throws -> S3Client.S3ClientConfiguration {
        let baseConfiguration = try await S3Client.S3ClientConfiguration(
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
}
