//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSAPIPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSAPICategoryPluginResetTests: AWSAPICategoryPluginTestBase, @unchecked Sendable {

    func testReset() async {
        let resettable = apiPlugin as Resettable
        await resettable.reset()

        XCTAssertNotNil(apiPlugin.mapper)
        XCTAssertEqual(apiPlugin.mapper.operations.count, 0)
        XCTAssertEqual(apiPlugin.mapper.tasks.count, 0)
        XCTAssertNil(apiPlugin.session)
        XCTAssertNil(apiPlugin.pluginConfig)
        XCTAssertNil(apiPlugin.authService)
        apiPlugin = nil
    }

}
