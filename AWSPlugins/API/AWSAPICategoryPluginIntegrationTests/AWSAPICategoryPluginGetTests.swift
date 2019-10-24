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

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
              "Prod": [
                "Endpoint": "https://rqdxvfh3ue.execute-api.us-east-1.amazonaws.com/Prod",
                "Region": "us-east-1"
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
        _ = Amplify.API.get(apiName: "Prod", path: "/simplesuccess") { event in
            switch event {
            case .completed(let data):
                if let string = String(data: data, encoding: .utf8) {
                    XCTAssertEqual(string, "TODO: FIX THIS ASSERTION")
                } else {
                    XCTFail("Could not convert data to string: \(data)")
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
