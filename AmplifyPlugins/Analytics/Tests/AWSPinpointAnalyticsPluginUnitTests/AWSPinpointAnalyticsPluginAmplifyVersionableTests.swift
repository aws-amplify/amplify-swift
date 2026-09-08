//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpointAnalyticsPlugin
import XCTest

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPinpointAnalyticsPluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {

    func testVersionExists() {
        let plugin = AWSPinpointAnalyticsPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
