//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class DefaultHubPluginConcurrencyTests: XCTestCase {
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

    /// Given: The default configuration
    /// When: Events are submitted...
    /// - ...from multiple threads
    /// - ...to multiple channels
    /// - ...to multiple subscribers
    /// Then: All messages are delivered, to the correct listeners
    func testConcurrentMessageDelivery() async throws {
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

                let token = plugin.listen(to: channel, isIncluded: nil) { _ in
                    messageReceived.fulfill()
                }

                guard try await HubListenerTestUtilities.waitForListener(with: token, plugin: plugin, timeout: 1.0) else {
                    XCTFail("Listener \(listenerIteration) on channel \(channel) not registered")
                    return
                }
                messagesReceived.append(messageReceived)
            }
        }
        
        let capturedChannels = channels

        DispatchQueue.concurrentPerform(iterations: channels.count) { iteration in
            let channel = capturedChannels[iteration]
            for messageIteration in 0 ..< messagesExpectedPerListener {
                let payload = HubPayload(eventName: "Message \(messageIteration), channel \(channel)")
                plugin.dispatch(to: channel, payload: payload)
            }
        }

        await waitForExpectations(timeout: 5.0)
    }

}
