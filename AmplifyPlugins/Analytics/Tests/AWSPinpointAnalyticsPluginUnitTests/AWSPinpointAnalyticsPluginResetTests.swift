//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import XCTest

class AWSPinpointAnalyticsPluginResetTests: AWSPinpointAnalyticsPluginTestBase {
    func testReset() async {
        let resettable = analyticsPlugin as Resettable
        await resettable.reset()

        XCTAssertNil(analyticsPlugin.pinpoint)
        XCTAssertNil(analyticsPlugin.globalProperties)
        XCTAssertNil(analyticsPlugin.isEnabled)
    }
}
