//
// Copyright 2018-2020 Amazon.com,
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
final class IncomingAsyncSubscriptionEventPublisher: Cancellable {
    typealias Payload = MutationSync<AnyModel>
    typealias Event = AsyncEvent<SubscriptionEvent<GraphQLResponse<Payload>>, Void, APIError>

    private var onCreateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onCreateListener: GraphQLSubscriptionOperation<Payload>.EventListener?
    private var onCreateConnected: Bool

    private var onUpdateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onUpdateListener: GraphQLSubscriptionOperation<Payload>.EventListener?
    private var onUpdateConnected: Bool

    private var onDeleteOperation: GraphQLSubscriptionOperation<Payload>?
    private var onDeleteListener: GraphQLSubscriptionOperation<Payload>.EventListener?
    private var onDeleteConnected: Bool

    private let connectionStatusMutex: DispatchSemaphore
    private var combinedConnectionStatus: Bool {
        return onCreateConnected && onUpdateConnected && onDeleteConnected
    }

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        let log = Amplify.Logging.logger(forCategory: "IncomingAsyncSubscriptionEventPublisher")
        self.onCreateConnected = false
        self.onUpdateConnected = false
        self.onDeleteConnected = false
        self.connectionStatusMutex = DispatchSemaphore(value: 1)

        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        let onCreateListener: GraphQLSubscriptionOperation<Payload>.EventListener = onCreateListenerHandler(event:)
        self.onCreateListener =  onCreateListener
        self.onCreateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onCreate,
            api: api,
            listener: onCreateListener)

        let onUpdateListener: GraphQLSubscriptionOperation<Payload>.EventListener = onUpdateListenerHandler(event:)
        self.onUpdateListener = onUpdateListener
        self.onUpdateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onUpdate,
            api: api,
            listener: onUpdateListener)

        let onDeleteListener: GraphQLSubscriptionOperation<Payload>.EventListener = onDeleteListenerHandler(event:)
        self.onDeleteListener = onDeleteListener
        self.onDeleteOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onDelete,
            api: api,
            listener: onDeleteListener)
    }

    func onCreateListenerHandler(event: Event) {
        log.verbose("onCreateListener: \(event)")
        if case .inProcess(.connection) = event {
            connectionStatusMutex.wait()
            if case .inProcess(.connection(.connected)) = event {
                self.onCreateConnected = true
            } else if case .inProcess(.connection(.disconnected)) = event {
                self.onCreateConnected = false
            }
            if combinedConnectionStatus {
                incomingSubscriptionEvents.send(event)
            }
            connectionStatusMutex.signal()
            return
        }
        incomingSubscriptionEvents.send(event)
    }

    func onUpdateListenerHandler(event: Event) {
        log.verbose("onUpdateListener: \(event)")
        if case .inProcess(.connection) = event {
            connectionStatusMutex.wait()
            if case .inProcess(.connection(.connected)) = event {
                self.onUpdateConnected = true
            } else if case .inProcess(.connection(.disconnected)) = event {
                self.onUpdateConnected = false
            }
            if combinedConnectionStatus {
                incomingSubscriptionEvents.send(event)
            }
            connectionStatusMutex.signal()
            return
        }
        incomingSubscriptionEvents.send(event)
    }

    func onDeleteListenerHandler(event: Event) {
        log.verbose("onDeleteListener: \(event)")
        if case .inProcess(.connection) = event {
            connectionStatusMutex.wait()
            if case .inProcess(.connection(.connected)) = event {
                self.onDeleteConnected = true
            } else if case .inProcess(.connection(.disconnected)) = event {
                self.onDeleteConnected = false
            }
            if combinedConnectionStatus {
                incomingSubscriptionEvents.send(event)
            }
            connectionStatusMutex.signal()
            return
        }
        incomingSubscriptionEvents.send(event)
    }

    static func apiSubscription(for modelType: Model.Type,
                                subscriptionType: GraphQLSubscriptionType,
                                api: APICategoryGraphQLBehavior,
                                listener: @escaping GraphQLSubscriptionOperation<Payload>.EventListener)
        -> GraphQLSubscriptionOperation<Payload> {

            let request = GraphQLRequest<Payload>.subscription(to: modelType,
                                                               subscriptionType: subscriptionType)
            let operation = api.subscribe(request: request, listener: listener)
            return operation
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }

    func cancel() {
        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateListener = nil

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateListener = nil


        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteListener = nil

    }

    func reset(onComplete: () -> Void) {
        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateListener?(.completed(()))

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateListener?(.completed(()))

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteListener?(.completed(()))

        onComplete()
    }

}

@available(iOS 13.0, *)
extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
