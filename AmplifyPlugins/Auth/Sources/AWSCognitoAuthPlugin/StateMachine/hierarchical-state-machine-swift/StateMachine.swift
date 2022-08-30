//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Captures a weak reference to the value
class WeakWrapper<T> where T: AnyObject {
    private(set) weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

/// Models, evolves, and processes effects for a system.
///
/// A StateMachine consists of:
/// - State, which represents the current state of the system that the StateMachine
/// is modeling
/// - Resolver, a mechanism for evolving the state in response to events and
/// returning side effects
/// - Listener, which accepts and enqueues incoming events
/// - StateChangedListeners, which are notified whenever the state changes
/// - EffectExecutor, which resolves and executes Effects returned from event
/// processing
actor StateMachine<
    StateType,
    EnvironmentType: Environment
> where StateType: State {

    /// AsyncSequences are invoked a minimum of one time: Each sequence receives the current
    /// state as soon as `listen()` is invoked, and will receive each subsequent state change.
    typealias StateChangeSequence = StateAsyncSequence<StateType>

    private let environment: EnvironmentType
    private let resolver: AnyResolver<StateType>

    private(set) var currentState: StateType
    private var subscribers: [WeakWrapper<StateAsyncSequence<StateType>>]

    init<ResolverType>(
        resolver: ResolverType,
        environment: EnvironmentType,
        initialState: StateType? = nil
    ) where ResolverType: StateMachineResolver, ResolverType.StateType == StateType {
        self.resolver = resolver.eraseToAnyResolver()
        self.environment = environment
        self.currentState = initialState ?? resolver.defaultState

        self.subscribers = []
    }

    /// Start listening to state change updates. The current state and all subsequent state changes will be sent to the sequence.
    ///
    /// - Returns: An async sequence that get states asynchronously
    func listen() -> StateChangeSequence {
        let sequence = StateAsyncSequence<StateType>()
        let currentState = self.currentState
        let wrappedToken = WeakWrapper(sequence)
        subscribers.append(wrappedToken)
        sequence.send(currentState)
        return sequence
    }
}

extension StateMachine: EventDispatcher {

    /// Sends `event` to the StateMachine for resolution, and applies any effects and
    /// new states returned from the resolution. If the state machine's state after
    /// resolving is not equal to the state before the event, updates the state
    /// machine's state and invokes listeners with the new state. Regardless of whether
    /// the state is new or not, the state machine will execute any effects from the
    /// event resolution process.
    func send(_ event: StateMachineEvent) async {
        if Task.isCancelled {
            return
        }
        process(event: event)
    }


    private func process(event: StateMachineEvent) {
        let resolution = resolver.resolve(
            oldState: currentState,
            byApplying: event
        )

        if currentState != resolution.newState {
            currentState = resolution.newState
            subscribers.removeAll { item in
                !notify(subscriberElement: item, about: resolution.newState)
            }
        }
        execute(resolution.actions)
    }

    /// Must be invoked on operationQueue
    /// - Parameters:
    ///   - subscriberElement: a dictionary element containing the subscriber token and listener
    ///   - newState: The new state to be sent
    /// - Returns: true if the subscriber was notified, false if the wrapper reference was nil or a cancellation was pending
    private func notify(
        subscriberElement: WeakWrapper<StateChangeSequence>,
        about newState: StateType
    ) -> Bool {


        // If weak reference has become nil, do not process, and return false so caller can remove
        // the subscription from the subscribers list
        guard let sequence = subscriberElement.value else {
            return false
        }

        sequence.send(newState)
        return true
    }

    private func execute(_ actions: [Action]) {
        guard !actions.isEmpty else {
            return
        }
        ConcurrentEffectExecutor.execute(actions, dispatchingTo: self, environment: environment)
    }
}
