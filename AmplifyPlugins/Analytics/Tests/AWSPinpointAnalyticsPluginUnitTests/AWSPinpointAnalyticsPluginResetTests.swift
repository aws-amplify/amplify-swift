//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import XCTest
@testable import AWSPinpointAnalyticsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPinpointAnalyticsPluginResetTests: AWSPinpointAnalyticsPluginTestBase, @unchecked Sendable {
    func testReset() async {
        let resettable = analyticsPlugin as Resettable
        await resettable.reset()

        XCTAssertNil(analyticsPlugin.pinpoint)
        XCTAssertNil(analyticsPlugin.globalProperties)
        XCTAssertNil(analyticsPlugin.isEnabled)
    }
}
