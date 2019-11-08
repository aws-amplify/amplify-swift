//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// Only @testable so we can get access to `Amplify.reset()`
@testable import Amplify

@testable import AmplifyTestCommon

class APICategoryClientGraphQLTests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() {
        Amplify.reset()

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(api: apiConfig)
    }

    func testQuery() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "query" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        _ = Amplify.API.query(apiName: "foo",
                              document: "foo",
                              responseType: JSONValue.self) { _ in }

        waitForExpectations(timeout: 0.5)
    }

    func testMutate() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "mutate" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        _ = Amplify.API.mutate(apiName: "foo",
                               document: "foo",
                               responseType: JSONValue.self) { _ in }

        waitForExpectations(timeout: 0.5)
    }

    // MARK: - Utilities

    func makeAndAddMockPlugin() throws -> MockAPICategoryPlugin {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)
        return plugin
    }

}
