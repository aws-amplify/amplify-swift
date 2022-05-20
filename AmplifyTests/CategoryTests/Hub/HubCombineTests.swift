//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon

class HubCombineTests: XCTestCase {

    func testValue() {
        let receivedValue = expectation(description: "Received value")

        let sink = Amplify.Hub.publisher(for: .auth)
            .sink { _ in
                receivedValue.fulfill()
            }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "test"))
        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testMultipleSubscribersReceiveValue() {
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

        waitForExpectations(timeout: 0.05)

        sub1.cancel()
        sub2.cancel()
    }

    func testCustomChannel() {
        let receivedValueForAuth = expectation(description: "receivedValueForAuth")
        let receivedValueForCustom = expectation(description: "receivedValueForCustom")

        let authSink = Amplify.Hub.publisher(for: .auth)
            .sink { _ in receivedValueForAuth.fulfill() }
        let customSink = Amplify.Hub.publisher(for: .custom("testChannel"))
            .sink { _ in receivedValueForCustom.fulfill() }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "test"))
        Amplify.Hub.dispatch(to: .custom("testChannel"), payload: HubPayload(eventName: "test"))

        waitForExpectations(timeout: 0.05)

        authSink.cancel()
        customSink.cancel()
    }

}
#endif
