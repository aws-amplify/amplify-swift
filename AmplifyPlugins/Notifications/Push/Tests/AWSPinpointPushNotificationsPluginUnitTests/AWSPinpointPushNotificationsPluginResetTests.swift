//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointPushNotificationsPlugin
import XCTest

class AWSPinpointPushNotificationsPluginResetTests: AWSPinpointPushNotificationsPluginTestBase {
    func testReset_shouldResetValues() {
        plugin.reset()
        XCTAssertNil(plugin.pinpoint)
        XCTAssertTrue(plugin.options.isEmpty)
    }
}
