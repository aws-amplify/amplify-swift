//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPIPluginRESTClientBehaviorTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testGetReturnsOperation() {
        setUpPlugin()

        let operation = Amplify.API.get(apiName: "foo", path: "/path", listener: nil)

        XCTAssertNotNil(operation)

        guard operation is AWSAPIGetOperation else {
            XCTFail("operation could not be cast as AWSAPIGetOperation")
            return
        }

        XCTAssertNotNil(operation.request)
    }

    /// - Given: A configured plugin
    /// - When: I invoke `APICategory.get(apiName:path:listener:)`
    /// - Then: The listener is invoked with the successful value
    func testGetReturnsValue() {
        let response = HTTPURLResponse()

        let mockHTTPTransport = MockHTTPTransport(response: response)
        setUpPlugin(with: mockHTTPTransport)

        let callbackInvoked = expectation(description: "Callback was invoked")
        _ = Amplify.API.get(apiName: "foo", path: "/path") { _ in
            callbackInvoked.fulfill()
        }

        wait(for: [callbackInvoked], timeout: 1.0)
    }

    // MARK: - Utilities

    func setUpPlugin(with httpTransport: HTTPTransport? = nil) {
        let apiPlugin: AWSAPICategoryPlugin

        if let httpTransport = httpTransport {
            apiPlugin = AWSAPICategoryPlugin(httpTransport: httpTransport)
        } else {
            apiPlugin = AWSAPICategoryPlugin()
        }

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "Prod": [
                    "Endpoint": "https://example.apiforintegrationtests.com",
                    "Region": "us-east-1"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

}

class MockHTTPTransport: HTTPTransport {
    let response: HTTPURLResponse

    init(response: HTTPURLResponse) {
        self.response = response
    }

    func get(urlRequest: URLRequest) {

    }

    func reset() {
        // Do nothing
    }
}
