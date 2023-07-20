//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
#if canImport(Combine)
import Combine

extension AnyCancellable: StateMachineSubscriberToken {}
#endif

class StateMachine<State, Event> {
    typealias Reducer = (State, Event) -> State
    private let queue = DispatchQueue(label: "com.amazonaws.Amplify.StateMachine<\(State.self), \(Event.self)>",
                                      target: DispatchQueue.global())
    private var reducer: Reducer

#if canImport(Combine)
    @Published private var state: State
#else
    private var subscribers: [Weak<SubscriberToken>: (State) -> Void] = [:]
    private var state: State {
        didSet {
            notifySubscribers()
        }
    }
#endif

    init(initialState: State, resolver: @escaping Reducer) {
        self.state = initialState
        self.reducer = resolver
    }

    func process(_ event: Event) {
        queue.sync {
            log.verbose("Processing event \(event) for current state \(self.state)")
            let newState = self.reducer(self.state, event)
            log.verbose("New state: \(newState)")
            self.state = newState
        }
    }

#if canImport(Combine)
    func subscribe(_ callback: @escaping (State) -> Void) -> StateMachineSubscriberToken {
        return $state.sink(receiveValue: callback)
    }

    func unsubscribe(token: StateMachineSubscriberToken) {
        guard let cancellable = token as? AnyCancellable else {
            return
        }
        cancellable.cancel()
    }
#else
    func subscribe(_ callback: @escaping (State) -> Void) -> StateMachineSubscriberToken {
        let token = SubscriberToken()
        subscribers[Weak(token)] = callback
        return token
    }

    func unsubscribe(token: StateMachineSubscriberToken) {
        guard let subscriberToken = token as? SubscriberToken else {
            return
        }
        subscribers[Weak(subscriberToken)] = nil
    }

    private func notifySubscribers() {
        subscribers = subscribers.filter { $0.key.value != nil }
        for callback in subscribers.values {
            callback(state)
        }
    }

    private class Weak<T>: Hashable where T: AnyObject, T: Hashable {
        private(set) weak var value: T?
        init(_ value: T) {
            self.value = value
        }

        static func == (lhs: Weak<T>, rhs: Weak<T>) -> Bool {
            lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            value?.hash(into: &hasher)
        }
    }

    private class SubscriberToken: StateMachineSubscriberToken, Hashable {
        private let value = UUID().uuidString

        static func == (lhs: SubscriberToken, rhs: SubscriberToken) -> Bool {
            lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            value.hash(into: &hasher)
        }
    }
#endif
}

protocol StateMachineSubscriberToken: AnyObject {}

extension StateMachine: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.analytics.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}
