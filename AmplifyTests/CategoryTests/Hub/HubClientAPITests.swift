//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

@testable import AmplifyTestCommon

class HubClientAPITests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let hubConfig = HubCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(hub: hubConfig)
    }

    func testDispatch() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "dispatch" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Hub.dispatch(to: .storage, payload: HubPayload(eventName: ""))

        waitForExpectations(timeout: 0.5)
    }

    func testListen() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "listen" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        _ = Amplify.Hub.listen(to: .storage) { _ in }
        waitForExpectations(timeout: 0.5)
    }

    func testListenToEventName() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "listenEventName" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        _ = Amplify.Hub.listen(to: .storage, eventName: "testEvent") { _ in }
        waitForExpectations(timeout: 0.5)
    }

    func testRemove() throws {
        let plugin = try makeAndAddMockPlugin()
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "removeListener" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }
        let unsubscribeToken = UnsubscribeToken(channel: .storage, id: UUID())
        Amplify.Hub.removeListener(unsubscribeToken)
        waitForExpectations(timeout: 0.5)
    }

    // MARK: - Utilities

    func makeAndAddMockPlugin() throws -> MockHubCategoryPlugin {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)
        return plugin
    }
}
