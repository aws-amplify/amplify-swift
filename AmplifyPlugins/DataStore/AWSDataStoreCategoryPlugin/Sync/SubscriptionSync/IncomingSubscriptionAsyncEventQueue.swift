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
final class IncomingSubscriptionAsyncEventQueue {
    typealias QueueElement = AsyncEvent<SubscriptionEvent<GraphQLResponse<AnyModel>>, Void, APIError>

    private let operationListener: GraphQLSubscriptionOperation<AnyModel>.EventListener
    private var onCreateOperation: GraphQLSubscriptionOperation<AnyModel>?
    private var onUpdateOperation: GraphQLSubscriptionOperation<AnyModel>?
    private var onDeleteOperation: GraphQLSubscriptionOperation<AnyModel>?

    private let incomingSubscriptionEvents: PassthroughSubject<QueueElement, DataStoreError>

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        let incomingSubscriptionEvents = PassthroughSubject<QueueElement, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        let listener: GraphQLSubscriptionOperation<AnyModel>.EventListener = { event in
            incomingSubscriptionEvents.send(event)
        }
        self.operationListener = listener

        self.onCreateOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onCreate,
                                               listener: listener)

        self.onUpdateOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onUpdate,
                                               listener: listener)

        self.onDeleteOperation = api.subscribe(toAnyModelType: modelType,
                                               subscriptionType: .onDelete,
                                               listener: listener)
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == QueueElement, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }
}

extension IncomingSubscriptionAsyncEventQueue: DefaultLogger { }
