//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSLocationGeoPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSLocationGeoPluginResetTests: AWSLocationGeoPluginTestBase, @unchecked Sendable {
    func testReset() async {
        let resettable = geoPlugin as Resettable
        await resettable.reset()
        XCTAssertNil(geoPlugin.locationService)
        XCTAssertNil(geoPlugin.authService)
        XCTAssertNil(geoPlugin.pluginConfig)
    }
}
