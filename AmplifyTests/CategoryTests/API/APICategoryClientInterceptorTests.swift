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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class APICategoryClientInterceptorTests: XCTestCase, @unchecked Sendable {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(api: apiConfig)
    }

    func testAddInterceptor() async throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "addInterceptor" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let interceptor = MockURLRequestInterceptor()
        _ = try Amplify.API.add(interceptor: interceptor, for: "apiName")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
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
