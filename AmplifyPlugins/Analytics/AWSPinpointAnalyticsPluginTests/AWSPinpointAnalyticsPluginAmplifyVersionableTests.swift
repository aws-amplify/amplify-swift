//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpointAnalyticsPlugin

// swiftlint:disable:next type_name
class AWSPinpointAnalyticsPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSPinpointAnalyticsPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
