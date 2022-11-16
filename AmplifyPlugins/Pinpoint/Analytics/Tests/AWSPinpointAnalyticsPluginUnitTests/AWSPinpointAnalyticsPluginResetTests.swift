//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import XCTest

class AWSPinpointAnalyticsPluginResetTests: AWSPinpointAnalyticsPluginTestBase {
    func testReset() {
        analyticsPlugin.reset()
        XCTAssertNil(analyticsPlugin.pinpoint)
        XCTAssertNil(analyticsPlugin.globalProperties)
        XCTAssertNil(analyticsPlugin.isEnabled)
    }
}
