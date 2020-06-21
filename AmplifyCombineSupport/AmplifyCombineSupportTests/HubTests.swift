//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class HubTests: XCTestCase {

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

    // This test relies on access to Hub plugin internals to ensure that the CombineSupport is only registering a
    // single Hub listener for each channel, regardless of how many subscriptions are called on that channel.
    func testMultipleSubscriptionsUseOnlyOneHubListener() throws {

        // swiftlint:disable:next force_cast
        let plugin = try Amplify.Hub.getPlugin(for: "awsHubPlugin") as! AWSHubPlugin
        let dispatcher = plugin.dispatcher

        let authSub1 = Amplify.Hub.publisher(for: .auth).sink { print($0) }
        let authSub2 = Amplify.Hub.publisher(for: .auth).sink { print($0) }
        let authSub3 = Amplify.Hub.publisher(for: .auth).sink { print($0) }

        let apiSub1 = Amplify.Hub.publisher(for: .api).sink { print($0) }

        XCTAssertEqual(dispatcher.listeners.count, 2)

        authSub1.cancel()
        authSub2.cancel()
        authSub3.cancel()
        apiSub1.cancel()
    }

}
