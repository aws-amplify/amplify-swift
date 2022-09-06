//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class DefaultHubPluginCustomChannelTests: XCTestCase {

    var plugin: HubCategoryPlugin {
        guard let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin"),
            plugin.key == "awsHubPlugin" else {
                fatalError("Could not access AWSHubPlugin")
        }
        return plugin
    }

    override func setUp() async throws {
        await Amplify.reset()
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

    /// Given: A listener to a custom channel
    /// When: A message is dispatched to that custom channel
    /// Then: The listener is invoked
    func testMessageReceivedOnCustomChannel() async throws {
        let eventReceived = expectation(description: "Event received")

        let listener = plugin.listen(to: .custom("CustomChannel1"), isIncluded: nil) { _ in
            eventReceived.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: listener, plugin: plugin, timeout: 0.5) else {
            XCTFail("listener1 not registered")
            return
        }

        plugin.dispatch(to: .custom("CustomChannel1"), payload: HubPayload(eventName: "TEST_EVENT"))

        await waitForExpectations(timeout: 0.5)
    }

    /// Given: A listener to a custom channel
    /// When: A message is dispatched to a different custom channel
    /// Then: The listener is not invoked
    func testMessageNotReceivedOnDifferentCustomChannel() async throws {
        let eventReceived = expectation(description: "Event received")
        eventReceived.isInverted = true

        let listener = plugin.listen(to: .custom("CustomChannel1"), isIncluded: nil) { _ in
            eventReceived.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: listener, plugin: plugin, timeout: 0.5) else {
            XCTFail("listener1 not registered")
            return
        }

        plugin.dispatch(to: .custom("CustomChannel2"), payload: HubPayload(eventName: "TEST_EVENT"))

        await waitForExpectations(timeout: 0.5)
    }

    /// Given: Multiple listeners to a custom channel
    /// When: A message is dispatched to that custom channel
    /// Then: All listeners are invoked
    func testMultipleSubscribersOnCustomChannel() async throws {
        let listener1Invoked = expectation(description: "Listener 1 invoked")
        let listener2Invoked = expectation(description: "Listener 2 invoked")

        let listener1 = plugin.listen(to: .custom("CustomChannel1"), isIncluded: nil) { _ in
            listener1Invoked.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: listener1, plugin: plugin, timeout: 0.5) else {
            XCTFail("listener1 not registered")
            return
        }

        let listener2 = plugin.listen(to: .custom("CustomChannel1"), isIncluded: nil) { _ in
            listener2Invoked.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: listener2, plugin: plugin, timeout: 0.5) else {
            XCTFail("listener2 not registered")
            return
        }

        plugin.dispatch(to: .custom("CustomChannel1"), payload: HubPayload(eventName: "TEST_EVENT"))

        await waitForExpectations(timeout: 0.5)
    }

}
