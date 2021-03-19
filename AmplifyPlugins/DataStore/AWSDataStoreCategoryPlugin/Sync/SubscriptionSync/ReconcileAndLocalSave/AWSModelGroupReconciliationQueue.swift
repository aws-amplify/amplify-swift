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

@available(iOS 13.0, *)
typealias ModelGroupReconciliationQueueFactory = (
    [ModelSchema],
    StorageEngineAdapter,
    [DataStoreSyncExpression],
    APICategoryGraphQLBehavior,
    AuthCategoryBehavior?,
    [IncomingSubscriptionEventPublisher]?
) -> ModelReconciliationQueue

/// A queue of reconciliation operations, merged from incoming subscription events and responses to locally-sourced
/// mutations for a single model type.
///
/// Although subscriptions are listened to and enqueued at initialization, you must call `start` on a
/// AWSModelReconciliationQueue to write events to the DataStore.
///
/// Internally, a AWSModelReconciliationQueue manages different operation queues:
/// - A queue to buffer incoming remote events (e.g., subscriptions, mutation results)
/// - A queue to reconcile & save mutation sync events to local storage
/// These queues are required because each of these actions have different points in the sync lifecycle at which they
/// may be activated.
///
/// Flow:
/// - `AWSModelReconciliationQueue` init()
///   - `reconcileAndSaveQueue` created and activated
///   - `incomingSubscriptionEventQueue` created, but suspended
///   - `incomingEventsSink` listener set up for incoming remote events
///     - when `incomingEventsSink` listener receives an event, it adds an operation to `incomingSubscriptionEventQueue`
/// - Elsewhere in the system, the initial sync queries begin, and submit events via `enqueue`. That method creates a
///  `ReconcileAndLocalSaveOperation` for the event, and enqueues it on `reconcileAndSaveQueue`. `reconcileAndSaveQueue`
///   serially processes the events
/// - Once initial sync is done, the `ReconciliationQueue` is `start`ed, which activates the
///   `incomingSubscriptionEventQueue`.
/// - `incomingRemoteEventQueue` processes its operations, which are simply to call `enqueue` for each received remote
///   event.
@available(iOS 13.0, *)
final class AWSModelGroupReconciliationQueue: ModelReconciliationQueue {
    /// Exposes a publisher for incoming subscription events
    private var incomingSubscriptionEvents: [IncomingSubscriptionEventPublisher]?

    private var modelSchemasMap: [String: ModelSchema] = [:]
    weak var storageAdapter: StorageEngineAdapter?
    private let syncExpressions: [DataStoreSyncExpression]
    private var modelPredicates: [String: QueryPredicate]?

    /// A buffer queue for incoming subsscription events, waiting for this ReconciliationQueue to be `start`ed. Once
    /// the ReconciliationQueue is started, each event in the `incomingRemoveEventQueue` will be submitted to the
    /// `reconcileAndSaveQueue`.
    private var incomingSubscriptionEventQueues: [String: OperationQueue] = [:]

    /// Applies incoming mutation or subscription events serially to local data store for this model type. This queue
    /// is always active.
    private let reconcileAndSaveQueue: OperationQueue

    private var incomingEventsSinks: AtomicValue<Set<AnyCancellable?>>
    private var reconcileAndLocalSaveOperationSinks: AtomicValue<Set<AnyCancellable?>>

    private let modelReconciliationQueueSubject: PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> {
        return modelReconciliationQueueSubject.eraseToAnyPublisher()
    }

    init(modelSchemas: [ModelSchema],
         storageAdapter: StorageEngineAdapter?,
         syncExpressions: [DataStoreSyncExpression],
         api: APICategoryGraphQLBehavior,
         auth: AuthCategoryBehavior?,
         incomingSubscriptionEvents: [IncomingSubscriptionEventPublisher]? = nil) {

        self.storageAdapter = storageAdapter
        self.syncExpressions = syncExpressions

        self.modelReconciliationQueueSubject = PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>()

        self.reconcileAndSaveQueue = OperationQueue()
        reconcileAndSaveQueue.name = "com.amazonaws.DataStore.\(modelSchemas.forEach { $0.name }).reconcile"
        reconcileAndSaveQueue.maxConcurrentOperationCount = 1
        reconcileAndSaveQueue.underlyingQueue = DispatchQueue.global()
        reconcileAndSaveQueue.isSuspended = false

        self.reconcileAndLocalSaveOperationSinks = AtomicValue(initialValue: Set<AnyCancellable?>())
        self.incomingEventsSinks = AtomicValue(initialValue: Set<AnyCancellable?>())
        self.incomingSubscriptionEventQueues = [:]
        self.modelPredicates = [:]

        for index in 0 ..< modelSchemas.count {
            modelSchemasMap[modelSchemas[index].name] = modelSchemas[index]
            let incomingSubscriptionEventQueue = OperationQueue()
            incomingSubscriptionEventQueue.name = "com.amazonaws.DataStore.\(modelSchemas[index].name).remoteEvent"
            incomingSubscriptionEventQueue.maxConcurrentOperationCount = 1
            incomingSubscriptionEventQueue.underlyingQueue = DispatchQueue.global()
            incomingSubscriptionEventQueue.isSuspended = true

            let modelName = modelSchemas[index].name
            let syncExpression = syncExpressions.first(where: {
                $0.modelSchema.name == modelName
            })
            let modelPredicate = syncExpression?.modelPredicate() ?? nil
            if let modelPredicate = modelPredicate {
                modelPredicates?.updateValue(modelPredicate, forKey: modelSchemas[index].name)
            }

            let resolvedIncomingSubscriptionEvents = incomingSubscriptionEvents?[index] ??
                AWSIncomingSubscriptionEventPublisher(modelSchema: modelSchemas[index],
                                                      api: api,
                                                      modelPredicate: modelPredicate,
                                                      auth: auth)
            self.incomingSubscriptionEvents?.append(resolvedIncomingSubscriptionEvents)
            self.reconcileAndLocalSaveOperationSinks = AtomicValue(initialValue: Set<AnyCancellable?>())
            let incomingEventsSink = resolvedIncomingSubscriptionEvents
                .publisher
                .sink(receiveCompletion: { [weak self] completion in
                    self?.receiveCompletion(completion)
                    }, receiveValue: { [weak self] receiveValue in
                        self?.receive(receiveValue, modelName: modelName)
                })

            incomingEventsSinks.with { $0.insert(incomingEventsSink) }
        }
    }

    /// (Re)starts the incoming subscription event queue.
    func start() {
        incomingSubscriptionEventQueues.forEach { $0.value.isSuspended = false }
        modelReconciliationQueueSubject.send(.started)
    }

    /// Pauses only the incoming subscription event queue. Events submitted via `enqueue` will still be processed
    func pause() {
        incomingSubscriptionEventQueues.forEach { $0.value.isSuspended = true }
        modelReconciliationQueueSubject.send(.paused)
    }

    /// Cancels all outstanding operations on both the incoming subscription event queue and the reconcile queue, and
    /// unsubscribes from the incoming events publisher. The queue may not be restarted after cancelling.
    func cancel() {
        incomingEventsSinks.with { $0.forEach { $0?.cancel() } }
        incomingEventsSinks.with { $0.removeAll() }
        incomingSubscriptionEvents?.forEach { $0.cancel() }
        reconcileAndSaveQueue.cancelAllOperations()
        incomingSubscriptionEventQueues.forEach { $0.value.cancelAllOperations() }
    }

    func enqueue(_ remoteModel: MutationSync<AnyModel>) {
        let reconcileOp = ReconcileAndLocalSaveOperation(modelSchema: modelSchemasMap[remoteModel.model.modelName]!,
                                                         remoteModel: remoteModel,
                                                         storageAdapter: storageAdapter)
        var reconcileAndLocalSaveOperationSink: AnyCancellable?
        reconcileAndLocalSaveOperationSink = reconcileOp.publisher.sink(receiveCompletion: { completion in
            self.reconcileAndLocalSaveOperationSinks.with { $0.remove(reconcileAndLocalSaveOperationSink) }
            if case .failure = completion {
                self.modelReconciliationQueueSubject.send(completion: completion)
            }
        }, receiveValue: { value in
            switch value {
            case .mutationEventDropped(let modelName):
                self.modelReconciliationQueueSubject.send(.mutationEventDropped(modelName: modelName))
            case .mutationEvent(let event):
                self.modelReconciliationQueueSubject.send(.mutationEvent(event))
            }
        })
        reconcileAndLocalSaveOperationSinks.with { $0.insert(reconcileAndLocalSaveOperationSink) }
        reconcileAndSaveQueue.addOperation(reconcileOp)
    }

    private func receive(_ receive: IncomingSubscriptionEventPublisherEvent, modelName: String) {
        switch receive {
        case .mutationEvent(let remoteModel):
            if let predicate = modelPredicates?[remoteModel.model.modelName] {
                guard predicate.evaluate(target: remoteModel.model.instance) else {
                    return
                }
            }
            incomingSubscriptionEventQueues[remoteModel.model.modelName]?.addOperation(CancelAwareBlockOperation {
                self.enqueue(remoteModel)
            })
        case .connectionConnected:
            modelReconciliationQueueSubject.send(.connected(modelName: modelName))
        }
    }

    private func receiveCompletion(_ completion: Subscribers.Completion<DataStoreError>) {
        switch completion {
        case .finished:
            log.info("receivedCompletion: finished")
            modelReconciliationQueueSubject.send(completion: .finished)
        case .failure(let dataStoreError):
            if case let .api(error, _) = dataStoreError,
               case let APIError.operationError(_, _, underlyingError) = error, isUnauthorizedError(underlyingError) {
                modelReconciliationQueueSubject.send(.disconnected(modelName: modelSchemasMap[""]!.name, reason: .unauthorized))
                return
            }
            log.error("receiveCompletion: error: \(dataStoreError)")
            modelReconciliationQueueSubject.send(completion: .failure(dataStoreError))
        }
    }
}

@available(iOS 13.0, *)
extension AWSModelGroupReconciliationQueue: DefaultLogger { }

// MARK: Resettable
@available(iOS 13.0, *)
extension AWSModelGroupReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        incomingEventsSinks.with { $0.forEach { $0?.cancel() } }

        if let resettable = incomingSubscriptionEvents as? Resettable {
            group.enter()
            DispatchQueue.global().async {
                resettable.reset { group.leave() }
            }
        }

        group.enter()
        DispatchQueue.global().async {
            self.reconcileAndSaveQueue.cancelAllOperations()
            self.reconcileAndSaveQueue.waitUntilAllOperationsAreFinished()
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            self.incomingSubscriptionEventQueues.forEach { $0.value.cancelAllOperations() }
            self.incomingSubscriptionEventQueues.forEach { $0.value.waitUntilAllOperationsAreFinished() }
            group.leave()
        }

        group.wait()

        onComplete()
    }

}

// MARK: Auth errors handling
@available(iOS 13.0, *)
extension AWSModelGroupReconciliationQueue {
    private typealias ResponseType = MutationSync<AnyModel>
    private func graphqlErrors(from error: GraphQLResponseError<ResponseType>?) -> [GraphQLError]? {
        if case let .error(errors) = error {
            return errors
        }
        return nil
    }

    private func isUnauthorizedError(_ error: Error?) -> Bool {
        if let responseError = error as? GraphQLResponseError<ResponseType>,
           let graphQLError = graphqlErrors(from: responseError)?.first,
           let extensions = graphQLError.extensions,
           case let .string(errorTypeValue) = extensions["errorType"],
           case .unauthorized = AppSyncErrorType(errorTypeValue) {
            return true
        }
        return false
    }
}
