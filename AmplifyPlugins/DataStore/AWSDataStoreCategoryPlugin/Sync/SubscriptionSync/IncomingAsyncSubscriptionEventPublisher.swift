//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Collects all subscription types for a given model into a single subscribable publisher.
///
/// The queue "Element" is AnyModel to allow for queues to be collected into an aggregate structure upstream, but each
/// individual EventQueue operates on a single, specific Model type.
///
/// At initialization, the Queue sets up subscriptions, via the provided `APICategoryGraphQLBehavior`, for each type
/// `GraphQLSubscriptionType` and holds a reference to the returned operation. The operations' listeners enqueue
/// incoming successful events onto a `Publisher`, that queue processors can subscribe to.
@available(iOS 13.0, *)
final class IncomingAsyncSubscriptionEventPublisher {
    typealias Payload = MutationSync<AnyModel>
    typealias Event = AsyncEvent<SubscriptionEvent<GraphQLResponse<Payload>>, Void, APIError>

    private var onCreateOperation: GraphQLSubscriptionOperation<Payload>?
    private let onCreateListener: GraphQLSubscriptionOperation<Payload>.EventListener

    private var onUpdateOperation: GraphQLSubscriptionOperation<Payload>?
    private let onUpdateListener: GraphQLSubscriptionOperation<Payload>.EventListener

    private var onDeleteOperation: GraphQLSubscriptionOperation<Payload>?
    private let onDeleteListener: GraphQLSubscriptionOperation<Payload>.EventListener

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        let log = Amplify.Logging.logger(forCategory: "IncomingAsyncSubscriptionEventPublisher")
        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        let onCreateListener: GraphQLSubscriptionOperation<Payload>.EventListener = { event in
            log.verbose("onCreateListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onCreateListener = onCreateListener
        self.onCreateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onCreate,
            api: api,
            listener: onCreateListener)

        let onUpdateListener: GraphQLSubscriptionOperation<Payload>.EventListener = { event in
            log.verbose("onUpdateListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onUpdateListener = onUpdateListener
        self.onUpdateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onUpdate,
            api: api,
            listener: onUpdateListener)

        let onDeleteListener: GraphQLSubscriptionOperation<Payload>.EventListener = { event in
            log.verbose("onDeleteListener: \(event)")
            incomingSubscriptionEvents.send(event)
        }
        self.onDeleteListener = onDeleteListener
        self.onDeleteOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onDelete,
            api: api,
            listener: onDeleteListener)
    }

    static func apiSubscription(for modelType: Model.Type,
                                subscriptionType: GraphQLSubscriptionType,
                                api: APICategoryGraphQLBehavior,
                                listener: @escaping GraphQLSubscriptionOperation<Payload>.EventListener)
        -> GraphQLSubscriptionOperation<Payload> {
            let document = GraphQLSubscription(of: modelType, type: subscriptionType)

            let request = GraphQLRequest(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: Payload.self,
                                         decodePath: document.decodePath)

            let operation = api.subscribe(request: request, listener: listener)
            return operation
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }

    func reset(onComplete: () -> Void) {
        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateListener(.completed(()))

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateListener(.completed(()))

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteListener(.completed(()))

        onComplete()
    }

}

@available(iOS 13.0, *)
extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
