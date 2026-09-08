//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSHubPluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {

    func testVersionExists() {
        let plugin = AWSHubPlugin()
        XCTAssertNotNil(plugin.version)
    }
}
