//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class DefaultHubPluginTests: XCTestCase {

    var plugin: HubCategoryPlugin {
        guard let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin"),
            plugin.key == "awsHubPlugin" else {
                fatalError("Could not access AWSHubPlugin")
        }
        return plugin
    }

    override func setUp() async throws {
        await Amplify.reset()
        // This test suite will have a lot of in-flight messages at the time of the `reset`. Give them time to finis
        // being delivered before moving to the next step.
        Thread.sleep(forTimeInterval: 1.0)
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// Given: An Amplify system configured with default values
    /// When: I invoke Amplify.configure()
    /// Then: I have access to the framework-provided Hub plugin
    func testDefaultPluginAssigned() throws {
        let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin")
        XCTAssertNotNil(plugin)
        XCTAssertEqual(plugin?.key, "awsHubPlugin")
    }

    /// Given: The default Hub plugin
    /// When: I invoke listen()
    /// Then: I receive an unsubscription token
    func testDefaultPluginListen() throws {
        let unsubscribe = plugin.listen(to: .storage, isIncluded: nil) { _ in }
        XCTAssertNotNil(unsubscribe)
    }

    /// Given: The default Hub plugin
    /// When: I invoke listen(to:eventName:)
    /// Then: I receive messages with that event name
    func testDefaultPluginListenEventName() throws {
        let expectedMessageReceived = expectation(description: "Message was received as expected")
        let unsubscribeToken = plugin.listen(to: .storage, eventName: "TEST_EVENT") { _ in
            expectedMessageReceived.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: unsubscribeToken, plugin: plugin, timeout: 0.5) else {
            XCTFail("Token with \(unsubscribeToken.id) was not registered")
            return
        }

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        wait(for: [expectedMessageReceived], timeout: 0.5)
    }

    /// Given: The default Hub plugin with a registered listener
    /// When: I dispatch a message
    /// Then: My listener is invoked with the message
    func testDefaultPluginDispatches() throws {
        let messageReceived = expectation(description: "Message was received")

        // We have other tests for multiple message delivery, and since Amplify.reset() is known to leave in-process
        // messages going, we'll let this test's expectation pass as long as it fulfills at least once
        messageReceived.assertForOverFulfill = false

        let token = plugin.listen(to: .storage, isIncluded: nil) { _ in
            messageReceived.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, plugin: plugin, timeout: 0.5) else {
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

        let isStillRegistered = AtomicValue(initialValue: true)
        let unsubscribeToken = plugin.listen(to: .storage, isIncluded: nil) { hubPayload in
            if isStillRegistered.get() {
                // Ignore system-generated notifications (e.g., "configuration finished"). After we `removeListener`
                // though, we don't expect to receive any message, so we only check for the message name if we haven't
                // yet unsubscribed.
                guard hubPayload.eventName == "TEST_EVENT" else {
                    return
                }
                expectedMessageReceived.fulfill()
            } else {
                unexpectedMessageReceived.fulfill()
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: unsubscribeToken,
                                                              plugin: plugin,
                                                              timeout: 0.5) else {
            XCTFail("Token with \(unsubscribeToken.id) was not registered")
            return
        }

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        wait(for: [expectedMessageReceived], timeout: 0.5)

        plugin.removeListener(unsubscribeToken)

        isStillRegistered.set(
            try HubListenerTestUtilities.waitForListener(with: unsubscribeToken,
                                                         plugin: plugin,
                                                         timeout: 0.5)
        )

        XCTAssertFalse(isStillRegistered.get(), "Should not be registered after removeListener")

        plugin.dispatch(to: .storage, payload: HubPayload(eventName: "TEST_EVENT"))
        wait(for: [unexpectedMessageReceived], timeout: 0.5)
    }

    /// Given: The default Hub plugin
    /// When: I invoke listen() for a specified channel and subsequently dispatch a message to a different channel
    /// Then: My listener is not invoked
    func testMessagesAreDeliveredOnlyToSpecifiedChannel() {
        let messageShouldNotBeReceived = expectation(description: "Message should not be received")
        messageShouldNotBeReceived.isInverted = true
        _ = plugin.listen(to: .storage, isIncluded: nil) { hubPayload in
            // Ignore system-generated notifications (e.g., "configuration finished")
            guard hubPayload.eventName == "TEST_EVENT" else {
                return
            }
            messageShouldNotBeReceived.fulfill()
        }
        plugin.dispatch(to: .custom("DifferentChannel"), payload: HubPayload(eventName: "TEST_EVENT"))
        waitForExpectations(timeout: 0.5)
    }

}
