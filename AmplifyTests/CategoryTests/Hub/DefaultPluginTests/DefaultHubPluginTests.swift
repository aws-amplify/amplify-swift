//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class DefaultHubPluginTests: XCTestCase {

    var plugin: HubCategoryPlugin {
        guard let plugin = try? Amplify.Hub.getPlugin(for: "DefaultHubCategoryPlugin"),
            plugin.key == "DefaultHubCategoryPlugin" else {
                fatalError("Could not access DefaultHubCategoryPlugin")
        }
        return plugin
    }

    override func setUp() {
        Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Given: An Amplify system configured with default values
    /// When: I invoke Amplify.configure()
    /// Then: I have access to the framework-provided Hub plugin
    func testDefaultPluginAssigned() throws {
        let plugin = try? Amplify.Hub.getPlugin(for: "DefaultHubCategoryPlugin")
        XCTAssertNotNil(plugin)
        XCTAssertEqual(plugin?.key, "DefaultHubCategoryPlugin")
    }

    /// Given: The default Hub plugin
    /// When: I invoke listen()
    /// Then: I receive an unsubscription token
    func testDefaultPluginListen() throws {
        let unsubscribe = plugin.listen(to: .storage, isIncluded: nil) { _ in }
        XCTAssertNotNil(unsubscribe)
    }

    /// Given: The default Hub plugin with a registered listener
    /// When: I dispatch a message
    /// Then: My listener is invoked with the message
    func testDefaultPluginDispatches() throws {
        let messageReceived = expectation(description: "Message was received")
        let token = plugin.listen(to: .storage, isIncluded: nil) { _ in
            messageReceived.fulfill()
        }

        guard try DefaultHubPluginTestHelpers.waitForListener(with: token, plugin: plugin, timeout: 0.5) else {
            XCTFail("Token with \(token.id) was not registered")
            return
        }

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        waitForExpectations(timeout: 0.5)
    }

    /// Given: A subscription token from a previous call to the default Hub plugin's `listen` method
    /// When: I invoke removeListener()
    /// Then: My listener is removed, and I receive no more events
    func testDefaultPluginRemoveListener() throws {
        let expectedMessageReceived = expectation(description: "Message was received as expected")
        let unexpectedMessageReceived = expectation(description: "Message was received after removing listener")
        unexpectedMessageReceived.isInverted = true

        var messageHasBeenReceived = false
        let unsubscribeToken = plugin.listen(to: .storage, isIncluded: nil) { _ in
            if !messageHasBeenReceived {
                messageHasBeenReceived.toggle()
                expectedMessageReceived.fulfill()
            } else {
                unexpectedMessageReceived.fulfill()
            }
        }

        guard try DefaultHubPluginTestHelpers.waitForListener(with: unsubscribeToken,
                                                              plugin: plugin,
                                                              timeout: 0.5) else {
            XCTFail("Token with \(unsubscribeToken.id) was not registered")
            return
        }

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        wait(for: [expectedMessageReceived], timeout: 0.5)

        plugin.removeListener(unsubscribeToken)

        let isStillRegistered = try DefaultHubPluginTestHelpers.waitForListener(with: unsubscribeToken,
                                                                                plugin: plugin,
                                                                                timeout: 0.5)
        XCTAssertFalse(isStillRegistered, "Should not be registered after removeListener")

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        wait(for: [unexpectedMessageReceived], timeout: 0.5)
    }

    /// Given: The default Hub plugin
    /// When: I invoke listen() for a specified channel and subsequently dispatch a message to a different channel
    /// Then: My listener is not invoked
    func testMessagesAreDeliveredOnlyToSpecifiedChannel() {
        let messageShouldNotBeReceived = expectation(description: "Message should not be received")
        messageShouldNotBeReceived.isInverted = true
        _ = plugin.listen(to: .storage, isIncluded: nil) { _ in
            messageShouldNotBeReceived.fulfill()
        }
        plugin.dispatch(to: .custom("DifferentChannel"), payload: HubPayload(eventName: "TEST_EVENT"))
        waitForExpectations(timeout: 0.5)
    }

}
