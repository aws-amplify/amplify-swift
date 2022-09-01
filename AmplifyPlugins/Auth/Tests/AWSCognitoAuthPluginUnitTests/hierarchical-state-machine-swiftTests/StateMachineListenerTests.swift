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

    override func setUpWithError() throws {
        stateMachine = CounterStateMachine.logging()
    }

    func testNotifiesOnListen() async {

        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let seq = await stateMachine.listen()
        for await state in seq {
            XCTAssertEqual(state.value, 1)
            if state.value == 1 {
                break
            }
        }
    }

    func testNotifiesOnStateChange() async {

        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let seq = await stateMachine.listen()
        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 2
        Task {
            for await _ in seq {
                notified.fulfill()
            }
        }
        let event = Counter.Event(id: "test", eventType: .increment)
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyOnNoStateChange() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let seq = await stateMachine.listen()
        Task {
            for await _ in seq {
                notified.fulfill()
            }
        }

        let event = Counter.Event(id: "test", eventType: .adjustBy(0))
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyAfterUnsubscribe() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let seq = await stateMachine.listen()
        Task {
            for await _ in seq {
                notified.fulfill()

            }
        }

        seq.cancel()
        let event = Counter.Event(id: "test", eventType: .increment)
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testOrderOfSubsription() async {
        let loop = 1_000
        for _ in 1...loop {

            let notified = expectation(description: "notified")
            notified.expectedFulfillmentCount = 3
            await stateMachine.send(Counter.Event(id: "set1", eventType: .set(10)))
            let seq = await stateMachine.listen()
            Task.detached {
                // Send a new event with a delay so that the send happens after subscription is set.
                try await Task.sleep(nanoseconds: 1_000)
                await self.stateMachine.send(Counter.Event(id: "set2", eventType: .set(11)))
            }
            Task {
                var count = 0
                for await state in seq {
                    if count == 0 {
                        count += 1
                        XCTAssertEqual(state.value, 10)
                    } else if count == 1 {
                        count += 1
                        XCTAssertEqual(state.value, 11)
                    } else {
                        XCTAssertEqual(state.value, 12)
                    }
                    notified.fulfill()
                }
            }

            Task.detached {
                try await Task.sleep(nanoseconds: 1_000_000)
                await self.stateMachine.send(Counter.Event(id: "set3", eventType: .set(12)))
            }
            await waitForExpectations(timeout: 2)
            seq.cancel()
        }
    }

    func testCancelListen() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let seq = await stateMachine.listen()
        let task = Task {
            for try await _ in seq {
                if Task.isCancelled {
                    notified.fulfill()
                    break
                }
            }

        }

        let event = Counter.Event(id: "test", eventType: .adjustBy(0))
        await stateMachine.send(event)
        task.cancel()
        await waitForExpectations(timeout: 0.1)
    }

}
