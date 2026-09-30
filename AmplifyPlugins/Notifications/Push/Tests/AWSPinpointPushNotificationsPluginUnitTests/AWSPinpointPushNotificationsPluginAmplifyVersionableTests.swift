//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpointPushNotificationsPlugin
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPinpointPushNotificationsPluginAmplifyVersionableTests: AWSPinpointPushNotificationsPluginTestBase, @unchecked Sendable {
    func testVersion_shouldReturnNotNil() {
        XCTAssertNotNil(plugin.version)
    }
}
