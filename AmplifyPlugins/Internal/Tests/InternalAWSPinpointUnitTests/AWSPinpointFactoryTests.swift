//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyTestCommon
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest

final class AWSPinpointFactoryTests: XCTestCase {
    private var appId: String {
        UUID().uuidString
    }
    private let region = "region"
    private var mockedProfileReader: MockProvisioningProfileReader!

    override func setUp() {
        mockedProfileReader = MockProvisioningProfileReader()
        AWSPinpointFactory.provisioningProfileReader = mockedProfileReader
        AWSPinpointFactory.credentialsProvider = MockCredentialsProvider()
    }

    /// - Given: There is a provisioning profile that set the APS entitlement to production
    /// - When: A Pinpoint Context is created
    /// - Then: The endpoint's isDebug flag should be set to false
    func testSharedPinpoint_withProvisioningProfile_andAPSProduction_shouldSetDebugToFalse() async throws {
        mockedProfileReader.mockedProfile = .init(
            apsEnvironment: .production
        )

        let pinpoint = try AWSPinpointFactory.sharedPinpoint(appId: appId, region: region)
        let context = try XCTUnwrap(pinpoint as? PinpointContext)
        let endpoint = await context.endpointClient.currentEndpointProfile()
        XCTAssertFalse(endpoint.isDebug)
    }

    /// - Given: There is a provisioning profile that set the APS entitlement to development
    /// - When: A Pinpoint Context is created
    /// - Then: The endpoint's isDebug flag should be set to true
    func testSharedPinpoint_withProvisioningProfile_andAPSDevelopment_shouldSetDebugToFalse() async throws {
        mockedProfileReader.mockedProfile = .init(
            apsEnvironment: .development
        )

        let pinpoint = try AWSPinpointFactory.sharedPinpoint(appId: appId, region: region)
        let context = try XCTUnwrap(pinpoint as? PinpointContext)
        let endpoint = await context.endpointClient.currentEndpointProfile()
        XCTAssertTrue(endpoint.isDebug)
    }

    /// - Given: There is no provisioning profile
    /// - When: A Pinpoint Context is created
    /// - Then: The endpoint's isDebug flag should be determined based on the presence of the DEBUG flag
    func testSharedPinpoint_withoutProvisioningProfile_shouldSetDebugAccodingToDEBUGFlag() async throws {
        mockedProfileReader.mockedProfile = nil
        var isDebug: Bool
    #if DEBUG
        isDebug = true
    #else
        isDebug = false
    #endif

        let pinpoint = try AWSPinpointFactory.sharedPinpoint(appId: appId, region: region)
        let context = try XCTUnwrap(pinpoint as? PinpointContext)
        let endpoint = await context.endpointClient.currentEndpointProfile()
        XCTAssertEqual(endpoint.isDebug, isDebug)
    }
}
