//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSPinpointPushNotificationsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPinpointPushNotificationsPluginResetTests: AWSPinpointPushNotificationsPluginTestBase, @unchecked Sendable {
    func testReset_shouldResetValues() async {
        let resettable = plugin as Resettable
        await resettable.reset()

        XCTAssertNil(plugin.pinpoint)
        XCTAssertTrue(plugin.options.isEmpty)
    }
}
