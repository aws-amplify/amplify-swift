//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

final class IncomingAsyncSubscriptionEventPublisherTests: XCTestCase {
    var apiPlugin: MockAPICategoryPlugin!
    override func setUp() {
        apiPlugin = MockAPICategoryPlugin()
    }

    /// This test was written to to reproduce a bug where the subscribe would miss events emitted by the publisher.
    /// The pattern in this test using the publisher (`IncomingAsyncSubscriptionEventPublisher`) and subscriber
    /// (`IncomingAsyncSubscriptionEventToAnyModelMapper`) are identical to the usage in `AWSModelReconciliationQueue.init()`.
    ///
    /// See the changes in this PR: https://github.com/aws-amplify/amplify-swift/pull/3489
    ///
    /// Before the PR changes, the publisher would emit events concurrently which caused some of them to be missed
    /// by the subscriber even though the subscriber applied back pressure to process one event at a time (demand
    /// of `max(1)`). For more details regarding back-pressure, see
    /// https://developer.apple.com/documentation/combine/processing-published-elements-with-subscribers
    ///
    /// The change, to publish the events though the same TaskQueue ensures that the events are properly buffered
    /// and sent only when the subscriber demands for it.
    func testSubscriberRecievedEvents() async throws {
        let expectedEvents = expectation(description: "Expected number of ")
        let numberOfEvents = 50
        expectedEvents.expectedFulfillmentCount = numberOfEvents
        let asyncEvents = await IncomingAsyncSubscriptionEventPublisher(
            modelSchema: Post.schema,
            api: apiPlugin,
            modelPredicate: nil,
            auth: nil,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            awsAuthService: nil)
        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        asyncEvents.subscribe(subscriber: mapper)
        let sink = mapper
            .publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectedEvents.fulfill()
                }
            )
        DispatchQueue.concurrentPerform(iterations: numberOfEvents) { index in
            asyncEvents.send(.connection(.connected))
        }

        await fulfillment(of: [expectedEvents], timeout: 2)
        sink.cancel()
    }
}
