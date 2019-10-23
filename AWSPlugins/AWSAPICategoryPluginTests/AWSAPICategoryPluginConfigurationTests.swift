//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testPluginKey() {
        let apiPlugin = AWSAPICategoryPlugin()
        XCTAssertEqual(apiPlugin.key, "AWSAPICategoryPlugin")
    }

    func testConfigureSuccess() throws {
        let apiPlugin = AWSAPICategoryPlugin()
        let apiPluginConfig = [String: JSONValue]()

        do {
            try apiPlugin.configure(using: apiPluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin")
        }
    }

}
