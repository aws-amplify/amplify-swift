//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

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

    private let environment: EnvironmentType
    private let resolver: AnyResolver<StateType>

    public var currentState: StateType {
        currentStateSubject.value
    }

    private let currentStateSubject: CurrentValueSubject<StateType, Never>

    deinit {
        currentStateSubject.send(completion: .finished)
    }

    init<ResolverType>(
        resolver: ResolverType,
        environment: EnvironmentType,
        initialState: StateType? = nil
    ) where ResolverType: StateMachineResolver, ResolverType.StateType == StateType {
        self.resolver = resolver.eraseToAnyResolver()
        self.environment = environment
        self.currentStateSubject = CurrentValueSubject(initialState ?? resolver.defaultState)
    }

    /// Start listening to state change updates. The current state and all subsequent state changes will be sent to the sequence.
    ///
    /// - Returns: An async sequence that get states asynchronously
    func listen() -> CancellableAsyncStream<StateType> {
        CancellableAsyncStream(with: currentStateSubject.eraseToAnyPublisher())
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
            currentStateSubject.send(resolution.newState)
        }
        execute(resolution.actions)
    }

    private func execute(_ actions: [Action]) {
        guard !actions.isEmpty else {
            return
        }
        ConcurrentEffectExecutor.execute(actions, dispatchingTo: self, environment: environment)
    }
}
