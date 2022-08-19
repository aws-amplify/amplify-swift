//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import HSM

class StateMachineListenerTests: XCTestCase {

    var stateMachine: CounterStateMachine!
    var tokens = Set<CounterStateMachine.StateChangeListenerToken>()

    override func setUpWithError() throws {
        stateMachine = CounterStateMachine.logging()
    }

    func testNotifiesOnListen() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let notified = expectation(description: "notified")
        await stateMachine.listen { state in
            notified.fulfill()
            XCTAssertEqual(state.value, 1)
        }
        .store(in: &tokens)
        await waitForExpectations(timeout: 0.1)
    }

    func testNotifiesOnStateChange() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))
        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 2
        await stateMachine.listen { _ in
            notified.fulfill()
        }
        .store(in: &tokens)

        let event = Counter.Event(id: "test", eventType: .increment)
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyOnNoStateChange() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        await stateMachine.listen { _ in
            notified.fulfill()
        }
        .store(in: &tokens)

        let event = Counter.Event(id: "test", eventType: .adjustBy(0))
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyAfterUnsubscribe() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let token = await stateMachine.listen { _ in
            notified.fulfill()
        }

        stateMachine.cancel(listenerToken: token)
        let event = Counter.Event(id: "test", eventType: .increment)
        await stateMachine.send(event)
        await waitForExpectations(timeout: 0.1)
    }

    func testDoesNotNotifyIfCancelledImmediately() async {
        await stateMachine.send(Counter.Event(id: "test", eventType: .increment))

        let notified = expectation(description: "notified")
        notified.expectedFulfillmentCount = 1
        let token = await stateMachine.listen({ state in
            notified.fulfill()
        }
        )

        stateMachine.cancel(listenerToken: token)
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

            Task.detached {
                // Send a new event with a delay so that the send happens after subscription is set.
                try await Task.sleep(nanoseconds: 1_000)
                await self.stateMachine.send(Counter.Event(id: "set2", eventType: .set(11)))
            }
            var count = 0
            let token = await self.stateMachine.listen { state in
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
            Task.detached {
                try await Task.sleep(nanoseconds: 1_000_000)
                await self.stateMachine.send(Counter.Event(id: "set2", eventType: .set(12)))
            }
            await waitForExpectations(timeout: 2)
            stateMachine.cancel(listenerToken: token)
        }
    }

}
