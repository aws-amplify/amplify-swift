//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSDataStorePlugin
@testable import AmplifyTestCommon
import Combine
import Amplify

// swiftlint:disable:next type_name
class AWSDataStorePluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        #if os(watchOS)
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(),
                                        configuration: .subscriptionsDisabled)
        #else
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
        #endif
        XCTAssertNotNil(plugin.version)
    }
    var sink: AnyCancellable?

//    func testExample() throws {
//        let expectation = expectation(description: "ok")
//        expectation.expectedFulfillmentCount = 5
//
//        let asyncEvents = EventPublisher()
//        let mapper = ExampleSubscriber()
//        asyncEvents.subscribe(subscriber: mapper)
//
//        sink = mapper.publisher.sink(receiveValue: { value in
//            print("Received", value)
//            expectation.fulfill()
//        })
//        let numberOfTasks = 5
//
//        DispatchQueue.concurrentPerform(iterations: numberOfTasks) { index in
//            asyncEvents.emit(value: index)
//        }
//
//        waitForExpectations(timeout: 100)
//    }
//
//    func test2() {
//        // mock IncomingAsyncSubscriptionEventPublisher
//        // publisher will send many events concurrently. like currentPerform
//        // we can capture the sequence of events emitted
//
//        // then wait for IncomingAsyncSubscriptionEventToAnyModelMapper to receive them
//        // and it will republish them in the same order.
//
//        //
//    }

}

class EventPublisher {
    let events: PassthroughSubject<Int, Never>
    var taskQueue: TaskQueue<Void>
    init() {
        events = PassthroughSubject<Int, Never>()
        taskQueue = TaskQueue<Void>()
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Int, S.Failure == Never {
        events.subscribe(subscriber)
    }
    func emit(value: Int) {
        taskQueue.async { [weak self] in
            guard let self else { return }
            print("Emitting value \(value)")
            events.send(value)
        }


    }
    func emit(_ values: [Int]) {
        for value in values {
            events.send(value)
        }
    }
}
class ExampleSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never

    private let subject: PassthroughSubject<Int, Never>
    var publisher: AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }

    var subscription: Subscription?
    var taskQueue: TaskQueue<Void>
    init() {
        self.subject = PassthroughSubject<Int, Never>()
        self.taskQueue = TaskQueue<Void>()
    }

    func receive(completion: Subscribers.Completion<Never>) {
        subject.send(completion: completion)
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription

        //subscription.request(.max(1))
        subscription.request(.unlimited)
    }

    func receive(_ input: Int) -> Subscribers.Demand {
        taskQueue.async { [weak self] in
            guard let self else { return }
            print("Control Demand", input)
            subject.send(input)
        }

        //return .max(1)
        return .unlimited
    }

}
