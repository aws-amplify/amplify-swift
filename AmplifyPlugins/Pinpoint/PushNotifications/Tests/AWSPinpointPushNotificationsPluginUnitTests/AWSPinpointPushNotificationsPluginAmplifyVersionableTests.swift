//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpointPushNotificationsPlugin

class AWSPinpointPushNotificationsPluginAmplifyVersionableTests: AWSPinpointPushNotificationsPluginTestBase {
    func testVersion_shouldReturnNotNil() {
        XCTAssertNotNil(plugin.version)
    }
}
