//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSPinpointPushNotificationsPlugin
import XCTest

class AWSPinpointPushNotificationsPluginResetTests: AWSPinpointPushNotificationsPluginTestBase {
    func testReset_shouldResetValues() async {
        let resettable = plugin as Resettable
        await resettable.reset()

        XCTAssertNil(plugin.pinpoint)
        XCTAssertTrue(plugin.options.isEmpty)
    }
}
