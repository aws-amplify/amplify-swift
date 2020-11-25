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
    typealias Event = SubscriptionEvent<GraphQLResponse<Payload>>

    private var onCreateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onCreateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onCreateConnected: Bool

    private var onUpdateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onUpdateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onUpdateConnected: Bool

    private var onDeleteOperation: GraphQLSubscriptionOperation<Payload>?
    private var onDeleteValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onDeleteConnected: Bool

    private let connectionStatusQueue: OperationQueue
    private var combinedConnectionStatusIsConnected: Bool {
        return onCreateConnected && onUpdateConnected && onDeleteConnected
    }

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>
    private let awsAuthService: AWSAuthServiceBehavior

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehavior,
         modelPredicate: QueryPredicate?,
         auth: AuthCategoryBehavior?,
         awsAuthService: AWSAuthServiceBehavior? = nil) {
        self.onCreateConnected = false
        self.onUpdateConnected = false
        self.onDeleteConnected = false
        self.connectionStatusQueue = OperationQueue()
        connectionStatusQueue.name
            = "com.amazonaws.Amplify.RemoteSyncEngine.\(modelSchema.name).IncomingAsyncSubscriptionEventPublisher"
        connectionStatusQueue.maxConcurrentOperationCount = 1
        connectionStatusQueue.isSuspended = false

        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents
        self.awsAuthService = awsAuthService ?? AWSAuthService()

        let onCreateValueListener = onCreateValueListenerHandler(event:)
        self.onCreateValueListener = onCreateValueListener
        self.onCreateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelSchema,
            subscriptionType: .onCreate,
            api: api,
            auth: auth,
            awsAuthService: self.awsAuthService,
            valueListener: onCreateValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )

        let onUpdateValueListener = onUpdateValueListenerHandler(event:)
        self.onUpdateValueListener = onUpdateValueListener
        self.onUpdateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelSchema,
            subscriptionType: .onUpdate,
            api: api,
            auth: auth,
            awsAuthService: self.awsAuthService,
            valueListener: onUpdateValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )

        let onDeleteValueListener = onDeleteValueListenerHandler(event:)
        self.onDeleteValueListener = onDeleteValueListener
        self.onDeleteOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelSchema,
            subscriptionType: .onDelete,
            api: api,
            auth: auth,
            awsAuthService: self.awsAuthService,
            valueListener: onDeleteValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )
    }

    func onCreateValueListenerHandler(event: Event) {
        log.verbose("onCreateValueListener: \(event)")
        let onCreateConnectionOp = CancelAwareBlockOperation {
            self.onCreateConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onCreateConnectionOp)
    }

    func onUpdateValueListenerHandler(event: Event) {
        log.verbose("onUpdateValueListener: \(event)")
        let onUpdateConnectionOp = CancelAwareBlockOperation {
            self.onUpdateConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onUpdateConnectionOp)
    }

    func onDeleteValueListenerHandler(event: Event) {
        log.verbose("onDeleteValueListener: \(event)")
        let onDeleteConnectionOp = CancelAwareBlockOperation {
            self.onDeleteConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onDeleteConnectionOp)
    }

    func isConnectionStatusConnected(for event: Event) -> Bool {
        if case .connection(.connected) = event {
            return true
        }
        return false
    }

    func sendConnectionEventIfConnected(event: Event) {
        if combinedConnectionStatusIsConnected {
            incomingSubscriptionEvents.send(event)
        }
    }

    func genericValueListenerHandler(event: Event, cancelAwareBlock: CancelAwareBlockOperation) {
        if case .connection = event {
            connectionStatusQueue.addOperation(cancelAwareBlock)
        } else {
            incomingSubscriptionEvents.send(event)
        }
    }

    func genericCompletionListenerHandler(result: Result<Void, APIError>) {
        switch result {
        case .success:
            incomingSubscriptionEvents.send(completion: .finished)
        case .failure(let apiError):
            let dataStoreError = DataStoreError(error: apiError)
            incomingSubscriptionEvents.send(completion: .failure(dataStoreError))
        }
    }

    static func apiSubscription(
        for modelSchema: ModelSchema,
        subscriptionType: GraphQLSubscriptionType,
        api: APICategoryGraphQLBehavior,
        auth: AuthCategoryBehavior?,
        awsAuthService: AWSAuthServiceBehavior,
        valueListener: @escaping GraphQLSubscriptionOperation<Payload>.InProcessListener,
        completionListener: @escaping GraphQLSubscriptionOperation<Payload>.ResultListener
    ) -> GraphQLSubscriptionOperation<Payload> {

        let request: GraphQLRequest<Payload>
        if modelSchema.hasAuthenticationRules,
            let _ = auth,
            case .success(let tokenString) = awsAuthService.getToken(),
            case .success(let claims) = awsAuthService.getTokenClaims(tokenString: tokenString) {

            request = GraphQLRequest<Payload>.subscription(to: modelSchema,
                                                           subscriptionType: subscriptionType,
                                                           claims: claims)
        } else if modelSchema.hasAuthenticationRules,
            let oidcAuthProvider = hasOIDCAuthProviderAvailable(api: api),
            case .success(let tokenString) = oidcAuthProvider.getLatestAuthToken(),
            case .success(let claims) = awsAuthService.getTokenClaims(tokenString: tokenString) {
            request = GraphQLRequest<Payload>.subscription(to: modelSchema,
                                                           subscriptionType: subscriptionType,
                                                           claims: claims)
        } else {
            request = GraphQLRequest<Payload>.subscription(to: modelSchema, subscriptionType: subscriptionType)
        }

        let operation = api.subscribe(request: request,
                                      valueListener: valueListener,
                                      completionListener: completionListener)
        return operation
    }

    static func hasOIDCAuthProviderAvailable(api: APICategoryGraphQLBehavior) -> AmplifyOIDCAuthProvider? {
        if let apiPlugin = api as? APICategoryAuthProviderFactoryBehavior,
            let oidcAuthProvider = apiPlugin.apiAuthProviderFactory().oidcAuthProvider() {
            return oidcAuthProvider
        }
        return nil
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }

    func cancel() {
        genericCompletionListenerHandler(result: .successfulVoid)

        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateValueListener = nil

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateValueListener = nil

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteValueListener = nil

        connectionStatusQueue.cancelAllOperations()
    }

    func reset(onComplete: () -> Void) {
        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateValueListener?(.connection(.disconnected))

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateValueListener?(.connection(.disconnected))

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteValueListener?(.connection(.disconnected))

        genericCompletionListenerHandler(result: .successfulVoid)

        onComplete()
    }

}

@available(iOS 13.0, *)
extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
