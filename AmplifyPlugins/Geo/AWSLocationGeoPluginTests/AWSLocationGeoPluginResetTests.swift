//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSLocationGeoPlugin
import XCTest

class AWSLocationGeoPluginResetTests: AWSLocationGeoPluginTestBase {
    func testReset() {
        geoPlugin.reset()

        XCTAssertNil(geoPlugin.locationService)
        XCTAssertNil(geoPlugin.authService)
        XCTAssertNil(geoPlugin.pluginConfig)
    }
}
