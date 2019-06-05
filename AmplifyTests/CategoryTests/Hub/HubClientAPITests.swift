//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class HubClientAPITests: XCTestCase {
    var mockAmplifyConfig: BasicAmplifyConfiguration!

    override func setUp() {
        Amplify.reset()

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        mockAmplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)
    }

    func testDispatch() throws {
        let plugin = MockHubCategoryPlugin()
        Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let payload = BasicHubPayload()
        let channel = HubChannel.core

        Amplify.Hub.dispatch(to: channel, payload: payload)

        waitForExpectations(timeout: 0.5)
    }

    func testListen() throws {
        XCTFail("Not yet implemented")
    }

    func testRemove() throws {
        XCTFail("Not yet implemented")
    }

    func testProtectedChannels() throws {
        XCTFail("Not yet implemented")
    }

    func testCannotDispatchMessageOnProtectedChannel() throws {
        XCTFail("Not yet implemented")
    }

}
