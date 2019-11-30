//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Collects all subscription types for a given model into a single subscribable publisher.
///
/// The queue "Element" is AnyModel to allow for queues to be collected into an aggregate structure upstream, but each
/// individual EventQueue operates on a single, specific Model type.
///
/// At initialization, the Queue sets up subscriptions, via the provided `APICategoryGraphQLBehavior`, for each type
/// `GraphQLSubscriptionType` and holds a reference to the returned operation. The operations' listeners enqueue
/// incoming successful events onto a `Publisher`, that queue processors can subscribe to.
final class IncomingAsyncSubscriptionEventPublisher {
    typealias Event = AsyncEvent<SubscriptionEvent<GraphQLResponse<AnyModel>>, Void, APIError>

    private var onCreateOperation: GraphQLSubscriptionOperation<AnyModel>?
    private let onCreateListener: GraphQLSubscriptionOperation<AnyModel>.EventListener

    private var onUpdateOperation: GraphQLSubscriptionOperation<AnyModel>?
    private let onUpdateListener: GraphQLSubscriptionOperation<AnyModel>.EventListener

    private var onDeleteOperation: GraphQLSubscriptionOperation<AnyModel>?
    private let onDeleteListener: GraphQLSubscriptionOperation<AnyModel>.EventListener

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        let log = Amplify.Logging.logger(forCategory: "IncomingAsyncSubscriptionEventPublisher")
        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        let onCreateListener: GraphQLSubscriptionOperation<AnyModel>.EventListener = { event in
            log.verbose("onCreateListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onCreateListener = onCreateListener
        self.onCreateOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onCreate,
                                               listener: onCreateListener)

        let onUpdateListener: GraphQLSubscriptionOperation<AnyModel>.EventListener = { event in
            log.verbose("onUpdateListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onUpdateListener = onUpdateListener
        self.onUpdateOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onUpdate,
                                               listener: onUpdateListener)

        let onDeleteListener: GraphQLSubscriptionOperation<AnyModel>.EventListener = { event in
            log.verbose("onDeleteListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onDeleteListener = onDeleteListener
        self.onDeleteOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onDelete,
                                               listener: onDeleteListener)
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }

    func reset(onComplete: () -> Void) {
        onCreateOperation?.cancel()
        onCreateListener(.completed(()))

        onUpdateOperation?.cancel()
        onUpdateListener(.completed(()))

        onDeleteOperation?.cancel()
        onDeleteListener(.completed(()))

        onComplete()
    }

}

extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
