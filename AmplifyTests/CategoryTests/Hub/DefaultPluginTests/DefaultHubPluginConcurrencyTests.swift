//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

class DefaultHubPluginConcurrencyTests: XCTestCase {
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

    /// Given: The default configuration
    /// When: Events are submitted...
    /// - ...from multiple threads
    /// - ...to multiple channels
    /// - ...to multiple subscribers
    /// Then: All messages are delivered, to the correct listeners
    func testConcurrentMessageDelivery() throws {
        let channelCount = 10
        let listenersPerChannel = 50
        let messagesExpectedPerListener = 10

        var channels = [HubChannel]()

        var messagesReceived = [XCTestExpectation]()

        for channelIteration in 0 ..< channelCount {
            let channel = HubChannel.custom("Channel\(channelIteration)")
            channels.append(channel)

            for listenerIteration in 0 ..< listenersPerChannel {
                let messageReceived = expectation(description:
                    "\(messagesExpectedPerListener) messages received by listener \(listenerIteration) on \(channel)"
                )
                messageReceived.expectedFulfillmentCount = messagesExpectedPerListener

                let token = plugin.listen(to: channel, filteringWith: nil) { _ in
                    messageReceived.fulfill()
                }

                guard try DefaultHubPluginTestHelpers.waitForListener(with: token, plugin: plugin, timeout: 1.0) else {
                    XCTFail("Listener \(listenerIteration) on channel \(channel) not registered")
                    return
                }
                messagesReceived.append(messageReceived)
            }
        }

        DispatchQueue.concurrentPerform(iterations: channels.count) { iteration in
            let channel = channels[iteration]
            for messageIteration in 0 ..< messagesExpectedPerListener {
                let payload = HubPayload(event: "Message \(messageIteration), channel \(channel)")
                plugin.dispatch(to: channel, payload: payload)
            }
        }

        wait(for: messagesReceived, timeout: 5.0)
    }

    /// Given: The default configuration
    /// When: Events are submitted...
    /// - ...from multiple threads
    /// Then: The system delivers messages in the order they were received
    func testDispatchedMessagesAreProcessedInOrder() throws {

        let event1Received = expectation(description: "Event 1 received")
        let event2Received = expectation(description: "Event 2 received")
        let event3Received = expectation(description: "Event 3 received")

        let expectations = [event1Received, event2Received, event3Received]

        let listener1 = plugin.listen(to: .storage, filteringWith: nil) { event in
            switch event.event {
            case "EVENT_1":
                event1Received.fulfill()
            case "EVENT_2":
                event2Received.fulfill()
            case "EVENT_3":
                event3Received.fulfill()
            default:
                break
            }
        }

        guard try DefaultHubPluginTestHelpers.waitForListener(with: listener1, plugin: plugin, timeout: 1.0) else {
            XCTFail("listener1 not registered")
            return
        }

        let queue1 = DispatchQueue(label: "queue1")
        let queue2 = DispatchQueue(label: "queue2")
        let queue3 = DispatchQueue(label: "queue3")

        queue1.sync {
            plugin.dispatch(to: .storage, payload: HubPayload(event: "EVENT_1"))
        }

        queue2.sync {
            plugin.dispatch(to: .storage, payload: HubPayload(event: "EVENT_2"))
        }

        queue3.sync {
            plugin.dispatch(to: .storage, payload: HubPayload(event: "EVENT_3"))
        }

        wait(for: expectations, timeout: 5.0, enforceOrder: true)
    }

}
