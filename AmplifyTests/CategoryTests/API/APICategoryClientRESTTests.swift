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

class APICategoryClientRESTTests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(api: apiConfig)
    }

    func testGet() async throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "get" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let getCompleted = asyncExpectation(description: "get completed")
        Task {
            _ = try await Amplify.API.get(request: RESTRequest())
            await getCompleted.fulfill()
        }
        await waitForExpectations([getCompleted], timeout: 0.5)
        
        await waitForExpectations(timeout: 0.5)
    }

    func testCacheInRequest() {
        let request = RESTRequest(apiName: "someapi")
        XCTAssertEqual(request.headers?["Cache-Control"], "no-store")
    }

    func testCustomCacheInRequest() {
        let request = RESTRequest(apiName: "someapi", headers: ["Cache-Control": "private"])
        XCTAssertEqual(request.headers?["Cache-Control"], "private")
    }

    func testCacheWithExistingValuesInRequest() {
        let request = RESTRequest(apiName: "someapi", headers: ["somekey": "somevalue"])
        XCTAssertEqual(request.headers?["Cache-Control"], "no-store")
        XCTAssertEqual(request.headers?["somekey"], "somevalue")
    }

    // MARK: - Utilities

    func makeAndAddMockPlugin() throws -> MockAPICategoryPlugin {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)
        return plugin
    }

}
