//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

@testable import AmplifyTestCommon

class HubClientAPITests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() {
        Amplify.reset()

        let hubConfig = HubCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(hub: hubConfig)
    }

    func testDispatch() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let payload = HubPayload(event: "")
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

    func testMessagesAreProcessedInOrder() throws {
        XCTFail("Not yet implemented")
    }
}
