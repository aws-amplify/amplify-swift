//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Facade to hide the AsyncEventQueue/ModelMapper structures from the ModelReconciliationQueue.
/// Provides a publisher for all incoming subscription types (onCreate, onUpdate, onDelete) for a single Model type.
@available(iOS 13.0, *)
final class AWSIncomingSubscriptionEventPublisher: IncomingSubscriptionEventPublisher {

    private let asyncEvents: IncomingAsyncSubscriptionEventPublisher
    private var mapper: IncomingAsyncSubscriptionEventToAnyModelMapper?
    private let subscriptionEventSubject: PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>
    private var mapperSink: AnyCancellable?
    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> {
        return subscriptionEventSubject.eraseToAnyPublisher()
    }

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior, auth: AuthCategoryBehavior?) {
        self.subscriptionEventSubject = PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>()
        self.asyncEvents = IncomingAsyncSubscriptionEventPublisher(modelType: modelType,
                                                                   api: api,
                                                                   auth: auth)

        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        self.mapper = mapper

        asyncEvents.subscribe(subscriber: mapper)
        self.mapperSink = mapper.publisher.sink(receiveCompletion: onReceiveCompletion(receiveCompletion:),
                                                receiveValue: onReceive(receiveValue:))
    }

    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        subscriptionEventSubject.send(completion: receiveCompletion)
    }

    private func onReceive(receiveValue: IncomingAsyncSubscriptionEvent) {
        if case .connectionConnected = receiveValue {
            subscriptionEventSubject.send(.connectionConnected)
        } else if case .payload(let mutationSyncAnyModel) = receiveValue {
            subscriptionEventSubject.send(.mutationEvent(mutationSyncAnyModel))
        }
    }

    func cancel() {
        mapperSink?.cancel()
        mapperSink = nil

        asyncEvents.cancel()
        mapper?.cancel()
        mapper = nil
    }
}

// MARK: Resettable
@available(iOS 13.0, *)
extension AWSIncomingSubscriptionEventPublisher: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            self.asyncEvents.reset { group.leave() }
        }

        group.enter()
        DispatchQueue.global().async {
            self.mapper?.reset { group.leave() }
        }

        group.wait()
        onComplete()
    }

}
