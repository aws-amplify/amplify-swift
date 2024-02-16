//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSAPIPlugin

class AWSAPICategoryPluginResetTests: AWSAPICategoryPluginTestBase {

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
