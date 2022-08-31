//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// Only @testable so we can get access to `await Amplify.reset()`
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

    func testQuery() async throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message.hasPrefix("query(request:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let request = GraphQLRequest(document: "", variables: nil, responseType: JSONValue.self)
        let queryCompleted = asyncExpectation(description: "query completed")
        Task {
            _ = try await Amplify.API.query(request: request)
            await queryCompleted.fulfill()
        }
        await waitForExpectations([queryCompleted], timeout: 0.5)
        
        await waitForExpectations(timeout: 0.5)
    }

    func testMutate() async throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message.hasPrefix("mutate") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let request = GraphQLRequest(document: "", variables: nil, responseType: JSONValue.self)
        
        let mutateCompleted = asyncExpectation(description: "mutate completed")
        Task {
            _ = try await Amplify.API.mutate(request: request)
            await mutateCompleted.fulfill()
        }
        await waitForExpectations([mutateCompleted], timeout: 0.5)

        await waitForExpectations(timeout: 0.5)
    }

    // MARK: - Utilities

    func makeAndAddMockPlugin() throws -> MockAPICategoryPlugin {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)
        return plugin
    }

}
