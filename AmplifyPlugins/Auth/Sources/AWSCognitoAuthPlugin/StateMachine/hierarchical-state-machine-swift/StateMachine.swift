//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Captures a weak reference to the value
class WeakWrapper<T>: Hashable where T: AnyObject, T: Hashable {
    private(set) weak var value: T?
    init(_ value: T) {
        self.value = value
    }

    static func == (lhs: WeakWrapper<T>, rhs: WeakWrapper<T>) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        value?.hash(into: &hasher)
    }
}

/// Wrap any type in a reference
class Box<BoxedValue>: Hashable where BoxedValue: Hashable {
    let value: BoxedValue
    init(_ value: BoxedValue) {
        self.value = value
    }

    static func == (lhs: Box<BoxedValue>, rhs: Box<BoxedValue>) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }
}

extension Box where BoxedValue == UUID {
    func store(in tokens: inout Set<Box<BoxedValue>>) {
        tokens.insert(self)
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
    /// Listeners are invoked a minimum of one time: Each listener receives the current
    /// state as soon as it subscribes, and will be invoked on each subsequent state change.
    typealias StateChangedListener = (StateType) -> Void
    typealias StateChangeListenerToken = Box<UUID>
    typealias OnSubscribedCallback = () -> Void

    private let environment: EnvironmentType
    private let resolver: AnyResolver<StateType>

    var currentState: StateType

    private var subscribers: [WeakWrapper<StateChangeListenerToken>: StateChangedListener]
    private let pendingCancellations: AtomicValue<Set<StateChangeListenerToken>>

    init<ResolverType>(
        resolver: ResolverType,
        environment: EnvironmentType,
        initialState: StateType? = nil
    ) where ResolverType: StateMachineResolver, ResolverType.StateType == StateType {
        self.resolver = resolver.eraseToAnyResolver()
        self.environment = environment
        self.currentState = initialState ?? resolver.defaultState

        self.subscribers = [:]
        self.pendingCancellations = AtomicValue<Set<StateChangeListenerToken>>(initialValue: [])
    }

    /// Start listening to state changes updates. Asynchronously invokes listener on a background with the current state
    ///
    /// `listener` with be invoked in a separate unstructured `Task`
    ///
    /// - Parameters:
    ///   - listener: Listener to be invoked on state changes
    /// - Returns: A token that can be used to unsubscribe the listener
    func listen(
        _ listener: @escaping StateChangedListener
    ) -> StateChangeListenerToken {
        let token = StateChangeListenerToken(UUID())
        self.addSubscription(
            token: token,
            listener: listener
        )
        return token
    }

    /// Stop listening to state changes updates.
    ///
    /// Internally, this method registers a pending cancellation. If a new event comes in between the time `cancel` is called
    /// and the time the pending cancellation is processed, the event will not be dispatched to the listener.
    ///
    /// - Parameter listenerToken: Identifies the listener to be removed
    nonisolated func cancel(listenerToken: StateChangeListenerToken) {
        pendingCancellations.with { $0.insert(listenerToken) }
        Task {
           await self.removeSubscription(listenerToken: listenerToken)
        }

    }

    // MARK: - Isolated methods

    ///  Add the token in a weakly retained map
    /// - Parameters:
    ///   - token: the token, which will be retained weakly in the subscribers map
    ///   - listener: the listener to invoke when the state has changed
    private func addSubscription(
        token: Box<UUID>,
        listener: @escaping StateChangedListener
    ) {
        guard !pendingCancellations.get().contains(token) else {
            return
        }

        let currentState = self.currentState
        let wrappedToken = WeakWrapper(token)

        subscribers[wrappedToken] = listener

        Task {
            listener(currentState)
        }
    }

    /// Removes the listener token
    ///
    /// - Parameter listenerToken: the token of the listener to remove
    private func removeSubscription(listenerToken: StateChangeListenerToken) {
        pendingCancellations.with { $0.remove(listenerToken) }
        guard let itemToRemove = subscribers.first(where: { $0.key.value == listenerToken }) else {
            return
        }
        subscribers[itemToRemove.key] = nil
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
        process(event: event)
    }


    private func process(event: StateMachineEvent) {
        let resolution = resolver.resolve(
            oldState: currentState,
            byApplying: event
        )

        if currentState != resolution.newState {
            currentState = resolution.newState
            let subscribersToRemove = subscribers
                .filter { !notify(subscriberElement: $0, about: resolution.newState) }
            subscribersToRemove.forEach {
                subscribers.removeValue(forKey: $0.key)
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
        subscriberElement: Dictionary<WeakWrapper<Box<UUID>>, (StateType) -> Void>.Element,
        about newState: StateType
    ) -> Bool {
        let weakWrapper = subscriberElement.key

        // If weak reference has become nil, do not process, and return false so caller can remove
        // the subscription from the subscribers list
        guard let token = weakWrapper.value else {
            return false
        }

        // If there is a pending cancellation for this subscriber, do not process, and return
        //  false so caller can remove the subscription from the subscribers list
        guard !pendingCancellations.get().contains(token) else {
            return false
        }

        subscriberElement.value(newState)
        return true
    }

    private func execute(_ actions: [Action]) {
        guard !actions.isEmpty else {
            return
        }
        ConcurrentEffectExecutor.execute(actions, dispatchingTo: self, environment: environment)
    }
}
