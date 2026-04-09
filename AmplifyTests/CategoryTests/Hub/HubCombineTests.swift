//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class HubCombineTests: XCTestCase {

    func testValue() async {
        let receivedValue = expectation(description: "Received value")

        let sink = Amplify.Hub.publisher(for: .auth)
            .sink { _ in
                receivedValue.fulfill()
            }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "test"))
        await fulfillment(of: [receivedValue], timeout: 0.05)
        sink.cancel()
    }

    func testMultipleSubscribersReceiveValue() async {
        let sub1ReceivedValue = expectation(description: "Subscriber 1 received value")
        let sub2ReceivedValue = expectation(description: "Subscriber 2 received value")

        let sub1 = Amplify.Hub.publisher(for: .auth)
            .sink { _ in
                sub1ReceivedValue.fulfill()
            }

        let sub2 = Amplify.Hub.publisher(for: .auth)
            .sink { _ in
                sub2ReceivedValue.fulfill()
            }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "test"))

        await fulfillment(
            of: [
                sub1ReceivedValue,
                sub2ReceivedValue
            ],
            timeout: 0.05
        )

        sub1.cancel()
        sub2.cancel()
    }

    func testCustomChannel() async {
        let receivedValueForAuth = expectation(description: "receivedValueForAuth")
        let receivedValueForCustom = expectation(description: "receivedValueForCustom")

        let authSink = Amplify.Hub.publisher(for: .auth)
            .sink { _ in receivedValueForAuth.fulfill() }
        let customSink = Amplify.Hub.publisher(for: .custom("testChannel"))
            .sink { _ in receivedValueForCustom.fulfill() }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "test"))
        Amplify.Hub.dispatch(to: .custom("testChannel"), payload: HubPayload(eventName: "test"))

        await fulfillment(
            of: [
                receivedValueForAuth,
                receivedValueForCustom
            ],
            timeout: 0.05
        )

        authSink.cancel()
        customSink.cancel()
    }

    /// Test that Combine publishers receive the `Amplify.configured` event
    /// dispatched by `notifyAllHubChannels()` during `Amplify.configure()`.
    /// This verifies the fix for https://github.com/aws-amplify/amplify-swift/issues/3980
    func testPublisherReceivesConfiguredEvent() async throws {
        await Amplify.reset()

        let receivedConfigured = expectation(description: "Publisher received Amplify.configured event")

        let sink = Amplify.Hub.publisher(for: .auth)
            .filter { $0.eventName == HubPayload.EventName.Amplify.configured }
            .sink { _ in
                receivedConfigured.fulfill()
            }

        let config = AmplifyConfiguration()
        try Amplify.configure(config)

        await fulfillment(of: [receivedConfigured], timeout: 1.0)
        sink.cancel()
    }

}
#endif
