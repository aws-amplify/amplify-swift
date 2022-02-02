//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class StateMachineTests: XCTestCase {

    func testDefaultState() {
        let testMachine = CounterStateMachine.logging()
        let notified = expectation(description: "notified")
        testMachine.getCurrentState {
            XCTAssertEqual($0.value, 0)
            notified.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    func testBasicReceive() {
        let testMachine = CounterStateMachine.logging()
        let increment = Counter.Event(id: "1", eventType: .increment)
        testMachine.send(increment)
        let notified = expectation(description: "notified")
        testMachine.getCurrentState {
            XCTAssertEqual($0.value, 1)
            notified.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    /// Given:
    /// - A state machine
    /// When:
    /// - The StateMachine receives multiple events concurrently
    /// Then:
    /// - It applies the events in order of receipt
    func testConcurrentReceive() {
        // Logging will significantly impact performance on these tight loops, so adjust expectation
        // timeout accordingly if you need to log
        let testMachine = CounterStateMachine.default()
        let increment = Counter.Event(id: "increment", eventType: .increment)
        let decrement = Counter.Event(id: "decrement", eventType: .decrement)

        DispatchQueue.concurrentPerform(iterations: 1_000) {
            if $0.isMultiple(of: 2) {
                testMachine.send(increment)
            } else {
                testMachine.send(decrement)
            }
        }

        let notified = expectation(description: "notified")
        testMachine.getCurrentState {
            XCTAssertEqual($0.value, 0)
            notified.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    /// Given:
    /// - A state machine
    /// When:
    /// - The StateMachine receives an event
    /// - A caller reads the current state
    /// Then:
    /// - The read blocks until the state is resolved
    ///
    /// The way we assert this is to immediately read the current value after
    /// receiving an event. `receive` is asynchronous, so we'd expect some of
    /// the current values to be out of sync if the state machine didn't
    /// properly serialize access.
    func testConcurrentReceiveAndRead() {
        // Logging will significantly impact performance on these tight loops, so adjust expectation
        // timeout accordingly if you need to log
        let testMachine = CounterStateMachine.default()
        let increment = Counter.Event(id: "1", eventType: .increment)
        var allExpectations = [XCTestExpectation]()
        for iteration in 1 ... 10 {
            testMachine.send(increment)
            let notified = expectation(description: "notified")
            allExpectations.append(notified)
            testMachine.getCurrentState {
                XCTAssertEqual($0.value, iteration)
                notified.fulfill()
            }
        }

        waitForExpectations(timeout: 0.1)
    }

    /// Given:
    /// - A state machine
    /// When:
    /// - The state machine receives a resolution that includes actions
    /// Then:
    /// - It executes the action
    func testExecutesEffects() {
        let action1WasExecuted = expectation(description: "action1WasExecuted")
        let action2WasExecuted = expectation(description: "action2WasExecuted")

        let action1 = BasicAction(identifier: "basic") { _, _ in
            action1WasExecuted.fulfill()
        }

        let action2 = BasicAction(identifier: "basic") { _, _ in
            action2WasExecuted.fulfill()
        }

        let testMachine = CounterStateMachine.logging()

        let event = Counter.Event(
            id: "1",
            eventType: .incrementAndDoActions([action1, action2])
        )

        testMachine.send(event)
        waitForExpectations(timeout: 0.1)
    }

    /// Given:
    /// - A State machine
    /// When:
    /// - The state machine receives a resolution that includes an effect
    /// - The effect `dispatches` a new event
    /// Then:
    /// - The StateMachine processes the new event
    func testDispatchesFromAction() {
        let action1WasExecuted = expectation(description: "action1WasExecuted")
        let action2WasExecuted = expectation(description: "action2WasExecuted")

        let action1 = BasicAction(identifier: "basic") { dispatcher, _ in
            action1WasExecuted.fulfill()

            let action2 = BasicAction(identifier: "basic") { _, _ in
                action2WasExecuted.fulfill()
            }

            let event = Counter.Event(
                id: "2",
                eventType: .incrementAndDoActions([action2])
            )
            dispatcher.send(event)
        }

        let testMachine = CounterStateMachine.logging()

        let event = Counter.Event(
            id: "1",
            eventType: .incrementAndDoActions([action1])
        )

        testMachine.send(event)
        wait(for: [action1WasExecuted, action2WasExecuted], timeout: 0.1, enforceOrder: true)
    }

}
