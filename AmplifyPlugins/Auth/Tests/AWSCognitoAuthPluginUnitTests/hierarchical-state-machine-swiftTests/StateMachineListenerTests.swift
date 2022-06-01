//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class StateMachineListenerTests: XCTestCase {

    var stateMachine: CounterStateMachine!
    var tokens = Set<CounterStateMachine.StateChangeListenerToken>()

    override func setUpWithError() throws {
        stateMachine = CounterStateMachine.logging()
    }

    func testNotifiesOnListen() {
        stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let subscribed = expectation(description: "subscribed")
        let notified = expectation(description: "notified")
        stateMachine.listen { state in
            notified.fulfill()
            XCTAssertEqual(state.value, 1)
        }
        onSubscribe: {
            subscribed.fulfill()
        }
        .store(in: &tokens)

        waitForExpectations(timeout: 0.1)
    }

    func testNotifiesOnStateChange() {
        stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let subscribed = expectation(description: "subscribed")
        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 2
        stateMachine.listen { _ in
            notified.fulfill()
        }
        onSubscribe: {
            subscribed.fulfill()
        }
        .store(in: &tokens)

        wait(for: [subscribed], timeout: 0.1)

        let event = Counter.Event(id: "test", eventType: .increment)
        stateMachine.send(event)
        waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyOnNoStateChange() {
        stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let subscribed = expectation(description: "subscribed")
        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        stateMachine.listen { _ in
            notified.fulfill()
        }
        onSubscribe: {
            subscribed.fulfill()
        }
        .store(in: &tokens)

        wait(for: [subscribed], timeout: 0.1)

        let event = Counter.Event(id: "test", eventType: .adjustBy(0))
        stateMachine.send(event)
        waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyAfterUnsubscribe() {
        stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let subscribed = expectation(description: "subscribed")
        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let token = stateMachine.listen { _ in
            notified.fulfill()
        }
        onSubscribe: {
            subscribed.fulfill()
        }

        wait(for: [subscribed], timeout: 0.1)

        stateMachine.cancel(listenerToken: token)
        let event = Counter.Event(id: "test", eventType: .increment)
        stateMachine.send(event)
        waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyIfCancelledImmediately() {
        stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.isInverted = true
        let token = stateMachine.listen({ _ in
                notified.fulfill()
            },
            onSubscribe: nil
        )

        stateMachine.cancel(listenerToken: token)
        let event = Counter.Event(id: "test", eventType: .increment)
        stateMachine.send(event)
        waitForExpectations(timeout: 0.1)
    }

}
