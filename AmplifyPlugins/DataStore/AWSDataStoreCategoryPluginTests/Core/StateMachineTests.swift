//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

// Testable import b/c StateMachine is an internal type
@testable import AWSDataStorePlugin

class StateMachineTests: XCTestCase {

    /// - Given: A simple state machine
    /// - When:
    ///    - I `notify` the state machine
    /// - Then:
    ///    - My reducer is executed
    func testExecutesResolver() {
        let resolverInvoked = expectation(description: "Resolver was invoked")
        let resolver = makeResolver { resolverInvoked.fulfill() }
        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)

        stateMachine.notify(action: .increment)

        waitForExpectations(timeout: 1.0)
    }

    /// - Given: A state machine
    /// - When:
    ///    - A caller connects a subscriber to the $state publisher
    /// - Then:
    ///    - The caller receives the current state
    func testNotifiesListenerOnSubscribe() {
        let listenerInvoked = expectation(description: "Listener invoked")
        let resolver = makeResolver()
        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)
        stateMachine.notify(action: .increment)
        let listener = stateMachine.$state.sink { currentState in
            listenerInvoked.fulfill()
            XCTAssertEqual(currentState, .two)
        }

        waitForExpectations(timeout: 1.0)
        listener.cancel()
    }

    /// - Given: A subscriber to a state machine publisher
    /// - When:
    ///    - A caller invokes `notify` on the state machine
    /// - Then:
    ///    - The subscriber receives the new state
    func testNotifiesListenerOnChange() {
        let listenerInvoked = expectation(description: "Listener invoked")
        listenerInvoked.expectedFulfillmentCount = 2
        let resolver = makeResolver()
        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)
        let listener = stateMachine.$state.sink { _ in
            listenerInvoked.fulfill()
        }

        stateMachine.notify(action: .increment)

        waitForExpectations(timeout: 1.0)
        listener.cancel()
    }

    /// - Given: A state machine with subscriber
    /// - When:
    ///    - A caller notifies the state machine multiple times
    /// - Then:
    ///    - The subscribe receives the new state in order
    func testNotifiesListenerInOrder() {
        let receivedOneOnSubscribe = expectation(description: "Received .one on subscribe")
        let receivedTwoAfterSubscribe = expectation(description: "Received .two after subscribe")
        let receivedThreeAfterSubscribe = expectation(description: "Received .three after subscribe")
        let receivedOneAfterSubscribe = expectation(description: "Received .one after subscribe")
        let resolver = makeResolver()
        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)

        var hasReceivedInitialState = false
        let listener = stateMachine.$state.sink { newState in
            if !hasReceivedInitialState {
                hasReceivedInitialState = true
                if newState == .one {
                    receivedOneOnSubscribe.fulfill()
                }
                return
            }
            switch newState {
            case .one:
                receivedOneAfterSubscribe.fulfill()
            case .two:
                receivedTwoAfterSubscribe.fulfill()
            case .three:
                receivedThreeAfterSubscribe.fulfill()
            }
        }

        let testQueue = DispatchQueue(label: "testQueue")
        testQueue.async {
            for _ in 1 ... 3 {
                stateMachine.notify(action: .increment)
            }
        }

        wait(for: [
            receivedOneOnSubscribe,
            receivedTwoAfterSubscribe,
            receivedThreeAfterSubscribe,
            receivedOneAfterSubscribe
            ],
             timeout: 1.0,
             enforceOrder: true)

        listener.cancel()
    }

    /// - Given: A state machine
    /// - When:
    ///    - I `notify` the state machine
    /// - Then:
    ///    - The reducer is invoked on a queue other than the main thread
    func testResolverNotInvokedOnMainThread() {
        let resolverInvoked = expectation(description: "Resolver was invoked")
        let testQueue = DispatchQueue(label: "testQueue")

        let resolver = makeResolver {
            XCTAssertFalse(Thread.isMainThread, "Should not be invoked on main thread")
            resolverInvoked.fulfill()
        }

        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)

        testQueue.async {
            stateMachine.notify(action: .increment)
        }

        waitForExpectations(timeout: 1.0)
    }

    /// - Given: A state machine
    /// - When:
    ///    - I `notify` the state machine
    /// - Then:
    ///    - The reducer is invoked on a queue other than the one I am running on
    func testResolverInvokedOnDifferentQueue() {
        let resolverInvoked = expectation(description: "Resolver was invoked")
        let key = DispatchSpecificKey<Bool>()
        let testQueue = DispatchQueue(label: "testQueue")
        testQueue.setSpecific(key: key, value: true)

        let resolver = makeResolver {
            XCTAssertNil(DispatchQueue.getSpecific(key: key))
            resolverInvoked.fulfill()
        }

        let stateMachine = StateMachine<State, Action>(initialState: .one, resolver: resolver)

        testQueue.async {
            stateMachine.notify(action: .increment)
        }

        waitForExpectations(timeout: 1.0)
    }

    /// Returns a state reducer that executes `block` before resolving the state
    func makeResolver(block: (() -> Void)? = nil) -> StateMachine<State, Action>.Reducer {
        let resolver: StateMachine<State, Action>.Reducer = { currentState, action in
            block?()
            switch (currentState, action) {
            case (.one, .increment):
                return .two
            case (.one, .decrement):
                return .three

            case (.two, .increment):
                return .three
            case (.two, .decrement):
                return .one

            case (.three, .increment):
                return .one
            case (.three, .decrement):
                return .two
            }
        }
        return resolver
    }
}

extension StateMachineTests {
    enum State {
        case one
        case two
        case three
    }

    enum Action {
        case increment
        case decrement
    }
}
