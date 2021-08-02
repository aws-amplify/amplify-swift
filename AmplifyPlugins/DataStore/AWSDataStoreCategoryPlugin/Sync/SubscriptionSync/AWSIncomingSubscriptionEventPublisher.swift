//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

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

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehavior,
         modelPredicate: QueryPredicate?,
         auth: AuthCategoryBehavior?,
         authModeStrategy: AuthModeStrategy) {
        self.subscriptionEventSubject = PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>()
        self.asyncEvents = IncomingAsyncSubscriptionEventPublisher(modelSchema: modelSchema,
                                                                   api: api,
                                                                   modelPredicate: modelPredicate,
                                                                   auth: auth,
                                                                   authModeStrategy: authModeStrategy)

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
        Amplify.log.verbose("Resetting asyncEvents")
        DispatchQueue.global().async {
            self.asyncEvents.reset {
                Amplify.log.verbose("Resetting asyncEvents: finished")
                group.leave()
            }
        }

        if let mapper = mapper {
            Amplify.log.verbose("Resetting mapper")
            group.enter()
            DispatchQueue.global().async {
                mapper.reset {
                    Amplify.log.verbose("Resetting mapper: finished")
                    group.leave()
                }
            }
        }

        group.wait()
        onComplete()
    }

}
