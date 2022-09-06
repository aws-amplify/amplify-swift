//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class StateMachineTests: XCTestCase {

    func testDefaultState() async {
        let testMachine = CounterStateMachine.logging()
        let state = await testMachine.currentState
        XCTAssertEqual(state.value, 0)
    }

    func testBasicReceive() async  {
        let testMachine = CounterStateMachine.logging()
        let increment = Counter.Event(id: "1", eventType: .increment)
        await testMachine.send(increment)
        let state = await testMachine.currentState
        XCTAssertEqual(state.value, 1)
    }

    /// Given:
    /// - A state machine
    /// When:
    /// - The StateMachine receives multiple events concurrently
    /// Then:
    /// - It applies the events in order of receipt
    func testConcurrentReceive() async  {
        // Logging will significantly impact performance on these tight loops, so adjust expectation
        // timeout accordingly if you need to log
        let testMachine = CounterStateMachine.default()
        let increment = Counter.Event(id: "increment", eventType: .increment)
        let decrement = Counter.Event(id: "decrement", eventType: .decrement)

        Task {
            for i in 1...1_000 {
                if i.isMultiple(of: 2) {
                    await testMachine.send(increment)
                } else {
                    await testMachine.send(decrement)
                }
            }
        }
        let state = await testMachine.currentState
        XCTAssertEqual(state.value, 0)
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
    func testConcurrentReceiveAndRead() async  {
        // Logging will significantly impact performance on these tight loops, so adjust expectation
        // timeout accordingly if you need to log
        let testMachine = CounterStateMachine.default()
        let increment = Counter.Event(id: "1", eventType: .increment)
        for iteration in 1 ... 10 {
            await testMachine.send(increment)

            let state = await testMachine.currentState
            XCTAssertEqual(state.value, iteration)
        }

    }

    /// Given:
    /// - A state machine
    /// When:
    /// - The state machine receives a resolution that includes actions
    /// Then:
    /// - It executes the action
    func testExecutesEffects() async  {
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

        await testMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    /// Given:
    /// - A State machine
    /// When:
    /// - The state machine receives a resolution that includes an effect
    /// - The effect `dispatches` a new event
    /// Then:
    /// - The StateMachine processes the new event
    func testDispatchesFromAction() async  {
        let action1WasExecuted = expectation(description: "action1WasExecuted")
        let action2WasExecuted = expectation(description: "action2WasExecuted")

        let executionCount = AtomicValue(initialValue: 0)
        let action1 = BasicAction(identifier: "basic") { dispatcher, _ in

            action1WasExecuted.fulfill()
            XCTAssertEqual(executionCount.getAndSet(1), 0)

            let action2 = BasicAction(identifier: "basic") { _, _ in
                XCTAssertEqual(executionCount.getAndSet(2), 1)
                action2WasExecuted.fulfill()
            }

            let event = Counter.Event(
                id: "2",
                eventType: .incrementAndDoActions([action2])
            )
            Task {
                await dispatcher.send(event)
            }
        }

        let testMachine = CounterStateMachine.logging()

        let event = Counter.Event(
            id: "1",
            eventType: .incrementAndDoActions([action1])
        )

        await testMachine.send(event)
        await waitForExpectations(timeout: 0.1)
        XCTAssertEqual(executionCount.get(), 2)
    }

}
