//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// Note: This publisher accepts only a single subscriber. It retains a weak reference to
/// its MutationEventSource even after downstream subscribers have issued a `cancel()`,
/// so that subsequent subscribers will still receive event notifications.
/// - Note: `@unchecked Sendable` to satisfy `MutationEventPublisher`'s `Sendable` requirement.
///   `subscription` is an `AtomicValue` replaced on every start; results go only to the subscription that requested them.
final class AWSMutationEventPublisher: Publisher, @unchecked Sendable {
    typealias Output = MutationEvent
    typealias Failure = DataStoreError

    private let subscription = AtomicValue<MutationEventSubscription?>(initialValue: nil)
    /// Bumped for each new subscriber, so a result requested by a replaced one is dropped
    private let subscriptionGeneration = AtomicValue(initialValue: 0)
    weak var eventSource: MutationEventSource?

    init(eventSource: MutationEventSource) {
        log.verbose(#function)
        self.eventSource = eventSource
    }

    /// Receives a new subscriber, completing and dropping the old one if present
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        log.verbose(#function)
        // Bumped first, so no late result reaches the subscriber being finished
        _ = subscriptionGeneration.increment()
        subscription.get()?.subscriber.receive(completion: .finished)

        let newSubscription = MutationEventSubscription(subscriber: subscriber, publisher: self)
        subscription.set(newSubscription)
        subscriber.receive(subscription: newSubscription)
    }

    func cancel() {
        subscription.set(nil)
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand != .none else {
            return
        }

        if let max = demand.max, max < 1 {
            return
        }

        requestNextEvent()
    }

    func requestNextEvent() {
        log.verbose(#function)
        let requestGeneration = subscriptionGeneration.get()
        let promise: DataStoreCallback<MutationEvent> = { [weak self] result in
            guard let self else {
                return
            }
            guard subscriptionGeneration.get() == requestGeneration,
                  let subscriber = subscription.get()?.subscriber else {
                log.verbose("Dropping a mutation event result requested by a replaced or cancelled subscription")
                return
            }

            switch result {
            case .failure(let dataStoreError):
                subscriber.receive(completion: .failure(dataStoreError))
            case .success(let mutationEvent):
                let demand = subscriber.receive(mutationEvent)
                DispatchQueue.global().async {
                    self.request(demand)
                }
            }
        }

        DispatchQueue.global().async {
            guard let eventSource = self.eventSource else {
                self.log.verbose("AWSMutationPublisher.eventSource is unexpectedly nil")
                return
            }

            // A stale request would replace the new subscriber's parked one at the source
            guard self.subscriptionGeneration.get() == requestGeneration, self.subscription.get() != nil else {
                self.log.debug("Subscription is nil or replaced, not getting next mutation event")
                return
            }

            eventSource.getNextMutationEvent(completion: promise)
        }
    }

}

extension AWSMutationEventPublisher: MutationEventPublisher {
    var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        eraseToAnyPublisher()
    }
}

extension AWSMutationEventPublisher: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName, forNamespace: String(describing: self))
    }
    var log: Logger {
        Self.log
    }
}

extension AWSMutationEventPublisher: Resettable {
    func reset() async {
        eventSource = nil
    }
}
