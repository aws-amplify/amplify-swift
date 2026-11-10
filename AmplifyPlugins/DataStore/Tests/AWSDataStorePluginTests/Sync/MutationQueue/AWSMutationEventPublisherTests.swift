//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSMutationEventPublisherTests: XCTestCase, @unchecked Sendable {

    /// A result requested by a replaced subscriber is not delivered to its successor.
    ///
    /// - Given: A publisher whose first subscriber requested an event, and then was replaced by a second subscriber
    ///   that has not requested one yet
    /// - When:
    ///    - The source answers the first subscriber's request with an event
    ///    - The second subscriber then requests an event, and the source answers it
    /// - Then:
    ///    - The second subscriber receives nothing from the first request
    ///    - The second subscriber receives the event from its own request
    ///
    func testResultRequestedByAReplacedSubscriber_isNotDeliveredToItsSuccessor() async {
        await assertResultForAReplacedSubscriberIsDropped(.success(makeMutationEvent(modelId: "stale")))
    }

    /// A failure requested by a replaced subscriber is not delivered to its successor.
    ///
    /// - Given: A publisher whose first subscriber requested an event, and then was replaced by a second subscriber
    ///   that has not requested one yet
    /// - When:
    ///    - The source answers the first subscriber's request with a failure
    ///    - The second subscriber then requests an event, and the source answers it
    /// - Then:
    ///    - The second subscriber receives no completion from the first request
    ///    - The second subscriber receives the event from its own request
    ///
    func testFailureRequestedByAReplacedSubscriber_isNotDeliveredToItsSuccessor() async {
        await assertResultForAReplacedSubscriberIsDropped(.failure(.unknown("", "", nil)))
    }

    // MARK: - Helpers

    private func assertResultForAReplacedSubscriberIsDropped(
        _ staleResult: DataStoreResult<MutationEvent>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let eventSource = CapturingMutationEventSource()
        let firstRequest = expectation(description: "The first subscriber's request reached the source")
        let secondRequest = expectation(description: "The second subscriber's request reached the source")
        eventSource.onRequest = { requestIndex in
            switch requestIndex {
            case 1:
                firstRequest.fulfill()
            case 2:
                secondRequest.fulfill()
            default:
                XCTFail("Unexpected request \(requestIndex)", file: file, line: line)
            }
        }
        let publisher = AWSMutationEventPublisher(eventSource: eventSource)
        let firstSubscriber = RecordingSubscriber(initialDemand: .max(1))
        publisher.subscribe(firstSubscriber)
        await fulfillment(of: [firstRequest], timeout: 1)
        let secondSubscriber = RecordingSubscriber(initialDemand: .none)
        publisher.subscribe(secondSubscriber)

        eventSource.completion(forRequest: 1)(staleResult)

        XCTAssertTrue(secondSubscriber.events.isEmpty, file: file, line: line)
        XCTAssertTrue(secondSubscriber.completions.isEmpty, file: file, line: line)

        secondSubscriber.subscription?.request(.max(1))
        await fulfillment(of: [secondRequest], timeout: 1)
        let freshEvent = makeMutationEvent(modelId: "fresh")
        eventSource.completion(forRequest: 2)(.success(freshEvent))

        XCTAssertEqual(secondSubscriber.events.map(\.id), [freshEvent.id], file: file, line: line)
        XCTAssertTrue(secondSubscriber.completions.isEmpty, file: file, line: line)
    }

    private func makeMutationEvent(modelId: String) -> MutationEvent {
        MutationEvent(modelId: modelId, modelName: "Post", json: "{}", mutationType: .create)
    }
}

/// Holds each `getNextMutationEvent` completion, so a test decides when and how each request is answered
/// - Note: `@unchecked Sendable`: state is guarded by `lock`, and `onRequest` is called outside it.
final class CapturingMutationEventSource: MutationEventSource, @unchecked Sendable {
    private let lock = NSLock()
    private var completions: [DataStoreCallback<MutationEvent>] = []
    private var onRequestHook: ((Int) -> Void)?

    /// Called after each request is captured, with its 1-based index
    var onRequest: ((Int) -> Void)? {
        get { lock.execute { onRequestHook } }
        set { lock.execute { onRequestHook = newValue } }
    }

    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        let (requestIndex, hook) = lock.execute {
            completions.append(completion)
            return (completions.count, onRequestHook)
        }
        hook?(requestIndex)
    }

    func completion(forRequest requestIndex: Int) -> DataStoreCallback<MutationEvent> {
        lock.execute { completions[requestIndex - 1] }
    }
}

/// Records what a publisher delivers, after requesting `initialDemand` on subscription
/// - Note: `@unchecked Sendable`: state is guarded by `lock`.
final class RecordingSubscriber: Subscriber, @unchecked Sendable {
    typealias Input = MutationEvent
    typealias Failure = DataStoreError

    private let lock = NSLock()
    private let initialDemand: Subscribers.Demand
    private var receivedSubscription: Subscription?
    private var receivedEvents: [MutationEvent] = []
    private var receivedCompletions: [Subscribers.Completion<DataStoreError>] = []

    var subscription: Subscription? { lock.execute { receivedSubscription } }
    var events: [MutationEvent] { lock.execute { receivedEvents } }
    var completions: [Subscribers.Completion<DataStoreError>] { lock.execute { receivedCompletions } }

    init(initialDemand: Subscribers.Demand) {
        self.initialDemand = initialDemand
    }

    func receive(subscription: Subscription) {
        lock.execute { receivedSubscription = subscription }
        if initialDemand != .none {
            subscription.request(initialDemand)
        }
    }

    func receive(_ input: MutationEvent) -> Subscribers.Demand {
        lock.execute { receivedEvents.append(input) }
        return .none
    }

    func receive(completion: Subscribers.Completion<DataStoreError>) {
        lock.execute { receivedCompletions.append(completion) }
    }
}
