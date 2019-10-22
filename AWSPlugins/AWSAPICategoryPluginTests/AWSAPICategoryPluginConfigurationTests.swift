//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginConfigurationTests: AWSAPICategoryPluginTestBase {

    func testPluginKey() {
        XCTAssertEqual(apiPlugin.key, "AWSAPICategoryPlugin")
    }

    func testConfigureSuccess() throws {
        let apiPluginConfig = [String: JSONValue]()

        do {
            try apiPlugin.configure(using: apiPluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin")
        }
    }

}
