//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Note: This publisher accepts only a single subscriber
@available(iOS 13.0, *)
final class AWSMutationEventPublisher: Publisher {
    typealias Output = MutationEvent
    typealias Failure = DataStoreError

    private var subscription: MutationEventSubscription?
    weak var eventSource: MutationEventSource?

    init(eventSource: MutationEventSource) {
        log.verbose(#function)
        self.eventSource = eventSource
    }

    /// Receives a new subscriber, completing and dropping the old one if present
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        log.verbose(#function)
        subscription?.subscriber.receive(completion: .finished)

        let subscription = MutationEventSubscription(subscriber: subscriber, publisher: self)
        self.subscription = subscription
        subscriber.receive(subscription: subscription)
    }

    func cancel() {
        subscription = nil
        eventSource = nil
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
        let promise: DataStoreCallback<MutationEvent> = { [weak self] result in
            guard let self = self, let subscriber = self.subscription?.subscriber else {
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
            self.eventSource?.getNextMutationEvent(completion: promise)
        }
    }

}

@available(iOS 13.0, *)
extension AWSMutationEventPublisher: MutationEventPublisher {
    var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension AWSMutationEventPublisher: DefaultLogger { }

@available(iOS 13.0, *)
extension AWSMutationEventPublisher: Resettable {
    func reset(onComplete: BasicClosure) {
        subscription = nil
        eventSource = nil
        onComplete()
    }
}
