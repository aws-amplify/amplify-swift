//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest

class EndpointInformationProviderTests: XCTestCase {

    /// Given: DefaultEndpointInformationProvider
    /// When: endpointInfo() is called
    /// Then: endpoint information is returned not nil
    func testGetEndpointInformation() async {
        let provider = DefaultEndpointInformationProvider()
        let endpointInfo = await provider.endpointInfo()
        XCTAssertNotNil(endpointInfo)
    }

    /// Given: DefaultEndpointInformationProvider
    /// When: endpointInfo() is called
    /// Then: endpoint information returned contains platform name/version, app version, model, 
    func testGetEndpointInformationDetails() async {
        let provider = DefaultEndpointInformationProvider()
        let endpointInfo = await provider.endpointInfo()
        let platformName = endpointInfo.platform.name
        let platformVersion = endpointInfo.platform.version
        let model = endpointInfo.model
        let version = endpointInfo.appVersion

        XCTAssertNotNil(platformName)
        XCTAssertNotNil(platformVersion)
        XCTAssertNotNil(model)
        XCTAssertNotNil(version)

        #if os(macOS)
        XCTAssertEqual(platformName, "macOS")
        #elseif os(iOS)
        XCTAssertEqual(platformName, "iOS")
        XCTAssertEqual(model, "iPhone")
        #elseif os(tvOS)
        XCTAssertEqual(platformName, "tvOS")
        XCTAssertEqual(model, "Apple TV")
        #elseif os(watchOS)
        XCTAssertEqual(platformName, "watchOS")
        XCTAssertEqual(model, "Apple Watch")
        #endif
    }
}
