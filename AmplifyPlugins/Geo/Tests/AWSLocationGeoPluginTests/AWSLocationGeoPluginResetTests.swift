//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSLocationGeoPlugin

class AWSLocationGeoPluginResetTests: AWSLocationGeoPluginTestBase {
    func testReset() async {
        let resettable = geoPlugin as Resettable
        await resettable.reset()
        XCTAssertNil(geoPlugin.locationService)
        XCTAssertNil(geoPlugin.authService)
        XCTAssertNil(geoPlugin.pluginConfig)
    }
}
