//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSAPICategoryPlugin

// @testable only so we can access `Amplify.reset()`
@testable import Amplify

class AWSAPICategoryPluginGetTests: XCTestCase {
    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        Amplify.reset()

        let plugin = AWSAPICategoryPlugin()

        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testSimpleGet() {
        let getCompleted = expectation(description: "get request completed")
        _ = Amplify.API.get(apiName: "simpleTest", path: "/") { event in
            getCompleted.fulfill()
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginGetTests.networkTimeout)
    }

}
