//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPredictionsPlugin

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPredictionsPluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {
    func testVersionExists() {
        let plugin = AWSPredictionsPlugin()
        XCTAssertNotNil(plugin.version)
    }
}
