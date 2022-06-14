//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// Only @testable so we can get access to `Amplify.reset()`
@testable import Amplify

@testable import AmplifyTestCommon

class APICategoryClientGraphQLTests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(api: apiConfig)
    }

    func testQuery() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message.hasPrefix("query(request:listener:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let request = GraphQLRequest(document: "", variables: nil, responseType: JSONValue.self)
        _ = Amplify.API.query(request: request) { _ in }

        waitForExpectations(timeout: 0.5)
    }

    func testMutate() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message.hasPrefix("mutate") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let request = GraphQLRequest(document: "", variables: nil, responseType: JSONValue.self)
        _ = Amplify.API.mutate(request: request) { _ in }

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
