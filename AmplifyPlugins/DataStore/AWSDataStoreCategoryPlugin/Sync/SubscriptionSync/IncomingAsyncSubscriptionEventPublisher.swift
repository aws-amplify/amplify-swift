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

/// Collects all subscription types for a given model into a single subscribable publisher.
///
/// The queue "Element" is AnyModel to allow for queues to be collected into an aggregate structure upstream, but each
/// individual EventQueue operates on a single, specific Model type.
///
/// At initialization, the Queue sets up subscriptions, via the provided `APICategoryGraphQLBehavior`, for each type
/// `GraphQLSubscriptionType` and holds a reference to the returned operation. The operations' listeners enqueue
/// incoming successful events onto a `Publisher`, that queue processors can subscribe to.
final class IncomingAsyncSubscriptionEventPublisher: AmplifyCancellable {
    typealias Payload = MutationSync<AnyModel>
    typealias Event = SubscriptionEvent<GraphQLResponse<Payload>>

    private var onCreateOperation: RetryableGraphQLSubscriptionOperation<Payload>?
    private var onCreateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onCreateConnected: Bool

    private var onUpdateOperation: RetryableGraphQLSubscriptionOperation<Payload>?
    private var onUpdateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onUpdateConnected: Bool

    private var onDeleteOperation: RetryableGraphQLSubscriptionOperation<Payload>?
    private var onDeleteValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onDeleteConnected: Bool

    private let connectionStatusQueue: OperationQueue
    private var combinedConnectionStatusIsConnected: Bool {
        return onCreateConnected && onUpdateConnected && onDeleteConnected
    }

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>
    private let awsAuthService: AWSAuthServiceBehavior

    private let consistencyQueue: DispatchQueue

    private let modelName: ModelName

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehavior,
         modelPredicate: QueryPredicate?,
         auth: AuthCategoryBehavior?,
         authModeStrategy: AuthModeStrategy,
         awsAuthService: AWSAuthServiceBehavior? = nil) {
        self.onCreateConnected = false
        self.onUpdateConnected = false
        self.onDeleteConnected = false
        self.consistencyQueue = DispatchQueue(
            label: "com.amazonaws.Amplify.RemoteSyncEngine.\(modelSchema.name)"
        )
        self.modelName = modelSchema.name

        self.connectionStatusQueue = OperationQueue()
        connectionStatusQueue.name
            = "com.amazonaws.Amplify.RemoteSyncEngine.\(modelSchema.name).IncomingAsyncSubscriptionEventPublisher"
        connectionStatusQueue.maxConcurrentOperationCount = 1
        connectionStatusQueue.isSuspended = false

        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents
        self.awsAuthService = awsAuthService ?? AWSAuthService()

        // onCreate operation
        let onCreateValueListener = onCreateValueListenerHandler(event:)
        let onCreateAuthTypeProvider = authModeStrategy.authTypesFor(schema: modelSchema,
                                                                     operation: .create)
        self.onCreateValueListener = onCreateValueListener
        self.onCreateOperation = RetryableGraphQLSubscriptionOperation(
            requestFactory: IncomingAsyncSubscriptionEventPublisher.apiRequestFactoryFor(
                for: modelSchema,
                subscriptionType: .onCreate,
                api: api,
                auth: auth,
                awsAuthService: self.awsAuthService,
                authTypeProvider: onCreateAuthTypeProvider),
            maxRetries: onCreateAuthTypeProvider.count,
            resultListener: genericCompletionListenerHandler) { nextRequest, wrappedCompletion in
            api.subscribe(request: nextRequest,
                          valueListener: onCreateValueListener,
                          completionListener: wrappedCompletion)
        }
        onCreateOperation?.main()

        // onUpdate operation
        let onUpdateValueListener = onUpdateValueListenerHandler(event:)
        let onUpdateAuthTypeProvider = authModeStrategy.authTypesFor(schema: modelSchema,
                                                                     operation: .update)
        self.onUpdateValueListener = onUpdateValueListener
        self.onUpdateOperation = RetryableGraphQLSubscriptionOperation(
            requestFactory: IncomingAsyncSubscriptionEventPublisher.apiRequestFactoryFor(
                for: modelSchema,
                subscriptionType: .onUpdate,
                api: api,
                auth: auth,
                awsAuthService: self.awsAuthService,
                authTypeProvider: onUpdateAuthTypeProvider),
            maxRetries: onUpdateAuthTypeProvider.count,
            resultListener: genericCompletionListenerHandler) { nextRequest, wrappedCompletion in
            api.subscribe(request: nextRequest,
                          valueListener: onUpdateValueListener,
                          completionListener: wrappedCompletion)
        }
        onUpdateOperation?.main()

        // onDelete operation
        let onDeleteValueListener = onDeleteValueListenerHandler(event:)
        let onDeleteAuthTypeProvider = authModeStrategy.authTypesFor(schema: modelSchema,
                                                                     operation: .delete)
        self.onDeleteValueListener = onDeleteValueListener
        self.onDeleteOperation = RetryableGraphQLSubscriptionOperation(
            requestFactory: IncomingAsyncSubscriptionEventPublisher.apiRequestFactoryFor(
                for: modelSchema,
                subscriptionType: .onDelete,
                api: api,
                auth: auth,
                awsAuthService: self.awsAuthService,
                authTypeProvider: onDeleteAuthTypeProvider),
            maxRetries: onUpdateAuthTypeProvider.count,
            resultListener: genericCompletionListenerHandler) { nextRequest, wrappedCompletion in
            api.subscribe(request: nextRequest,
                          valueListener: onDeleteValueListener,
                          completionListener: wrappedCompletion)
        }
        onDeleteOperation?.main()
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
            log.verbose("API Subscription failed for model `\(modelName)` with error: \(apiError.errorDescription)")
            let dataStoreError = DataStoreError(error: apiError)
            incomingSubscriptionEvents.send(completion: .failure(dataStoreError))
        }
    }

    static func makeAPIRequest(for modelSchema: ModelSchema,
                               subscriptionType: GraphQLSubscriptionType,
                               api: APICategoryGraphQLBehavior,
                               auth: AuthCategoryBehavior?,
                               authType: AWSAuthorizationType?,
                               awsAuthService: AWSAuthServiceBehavior) -> GraphQLRequest<Payload> {
        let request: GraphQLRequest<Payload>
        if modelSchema.hasAuthenticationRules,
            let _ = auth,
            case .success(let tokenString) = awsAuthService.getToken(),
            case .success(let claims) = awsAuthService.getTokenClaims(tokenString: tokenString) {
            request = GraphQLRequest<Payload>.subscription(to: modelSchema,
                                                           subscriptionType: subscriptionType,
                                                           claims: claims,
                                                           authType: authType)
        } else if modelSchema.hasAuthenticationRules,
            let oidcAuthProvider = hasOIDCAuthProviderAvailable(api: api),
            case .success(let tokenString) = oidcAuthProvider.getLatestAuthToken(),
            case .success(let claims) = awsAuthService.getTokenClaims(tokenString: tokenString) {
            request = GraphQLRequest<Payload>.subscription(to: modelSchema,
                                                           subscriptionType: subscriptionType,
                                                           claims: claims,
                                                           authType: authType)
        } else {
            request = GraphQLRequest<Payload>.subscription(to: modelSchema,
                                                           subscriptionType: subscriptionType,
                                                           authType: authType)
        }

        return request
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
        consistencyQueue.sync {
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
            connectionStatusQueue.waitUntilAllOperationsAreFinished()
        }
    }

    func reset(onComplete: () -> Void) {
        consistencyQueue.sync {
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
        }

        onComplete()
    }

}

// MARK: - IncomingAsyncSubscriptionEventPublisher + API request factory
extension IncomingAsyncSubscriptionEventPublisher {
    static func apiRequestFactoryFor(for modelSchema: ModelSchema,
                                     subscriptionType: GraphQLSubscriptionType,
                                     api: APICategoryGraphQLBehavior,
                                     auth: AuthCategoryBehavior?,
                                     awsAuthService: AWSAuthServiceBehavior,
                                     authTypeProvider: AWSAuthorizationTypeIterator) -> RetryableGraphQLOperation<Payload>.RequestFactory {
        var authTypes = authTypeProvider
        return {
            return IncomingAsyncSubscriptionEventPublisher.makeAPIRequest(for: modelSchema,
                                                                          subscriptionType: subscriptionType,
                                                                          api: api,
                                                                          auth: auth,
                                                                          authType: authTypes.next(),
                                                                          awsAuthService: awsAuthService)
        }
    }
}

extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
