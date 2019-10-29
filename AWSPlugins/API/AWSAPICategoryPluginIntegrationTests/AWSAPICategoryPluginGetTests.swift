//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify

class AWSAPICategoryPluginGetTests: XCTestCase {
    static let networkTimeout = TimeInterval(180)

    override static func setUp() {
        //        initializeMobileClient()
    }

    override func setUp() {
        Amplify.reset()

        let plugin = AWSAPICategoryPlugin()

        // TODO: Move this to a test credentials file before final merge
        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "none": [
                    "Endpoint": "https://rqdxvfh3ue.execute-api.us-east-1.amazonaws.com/Prod",
                    "Region": "us-east-1",
                    "AuthorizationType": "NONE"
                ],
                "apiKey": [
                    "Endpoint": "https://rqdxvfh3ue.execute-api.us-east-1.amazonaws.com/Prod",
                    "Region": "us-east-1",
                    "AuthorizationType": "API_KEY",
                    "ApiKey": "KjbPeqbh9F7hc2n2UVkpfD8WKF1kkYX3ydrkyHq6"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testSimpleGet() {
        let getCompleted = expectation(description: "get request completed")
        _ = Amplify.API.get(apiName: "none", path: "/simplesuccess") { event in
            switch event {
            case .completed(let data):
                // The endpoint echoes the request back, so we don't need to assert the whole thing
                if let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: data),
                    case .object(let response) = jsonValue,
                    case .object(let context) = response["context"],
                    case .string(let resourcePath) = context["resource-path"] {
                    XCTAssertEqual(resourcePath, "/simplesuccess")
                } else {
                    XCTFail("Could not access response object's [context][resource-path]: \(data)")
                }
                getCompleted.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginGetTests.networkTimeout)
    }

    func testAPIKeyGet() {
        let getCompleted = expectation(description: "get request completed")
        _ = Amplify.API.get(apiName: "apiKey", path: "/simplesuccessapikey") { event in
            switch event {
            case .completed(let data):
                // The endpoint echoes the request back, so we don't need to assert the whole thing
                if let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: data),
                    case .object(let response) = jsonValue,
                    case .object(let context) = response["context"],
                    case .string(let resourcePath) = context["resource-path"] {
                    XCTAssertEqual(resourcePath, "/simplesuccessapikey")
                } else {
                    XCTFail("Could not access response object's [context][resource-path]: \(data)")
                }
                getCompleted.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginGetTests.networkTimeout)
    }

    // MARK: - Utilities

    static func initializeMobileClient() {
        let callbackInvoked = DispatchSemaphore(value: 1)

        AWSMobileClient.default().initialize { userState, error in
            if let error = error {
                XCTFail("Error initializing AWSMobileClient. Error: \(error.localizedDescription)")
                return
            }

            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }

            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }

            callbackInvoked.signal()
        }

        _ = callbackInvoked.wait(timeout: .now() + networkTimeout)
    }
}
