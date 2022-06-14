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

class APICategoryClientInterceptorTests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(api: apiConfig)
    }

    func testAddInterceptor() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "addInterceptor" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let interceptor = MockURLRequestInterceptor()
        _ = try Amplify.API.add(interceptor: interceptor, for: "apiName")

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

struct MockURLRequestInterceptor: URLRequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        return request
    }
}
