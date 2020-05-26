//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

//Used for testing:
@available(iOS 13.0, *)
typealias ModelReconciliationQueueFactory = (
    Model.Type,
    StorageEngineAdapter,
    APICategoryGraphQLBehavior,
    AuthCategoryBehavior?,
    IncomingSubscriptionEventPublisher?
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
final class AWSModelReconciliationQueue: ModelReconciliationQueue {
    /// Exposes a publisher for incoming subscription events
    private let incomingSubscriptionEvents: IncomingSubscriptionEventPublisher

    weak var storageAdapter: StorageEngineAdapter?

    /// A buffer queue for incoming subsscription events, waiting for this ReconciliationQueue to be `start`ed. Once
    /// the ReconciliationQueue is started, each event in the `incomingRemoveEventQueue` will be submitted to the
    /// `reconcileAndSaveQueue`.
    private let incomingSubscriptionEventQueue: OperationQueue

    /// Applies incoming mutation or subscription events serially to local data store for this model type. This queue
    /// is always active.
    private let reconcileAndSaveQueue: OperationQueue

    private let modelName: String

    private var incomingEventsSink: AnyCancellable?
    private var reconcileAndLocalSaveOperationSink: AnyCancellable?

    private let modelReconciliationQueueSubject: PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> {
        return modelReconciliationQueueSubject.eraseToAnyPublisher()
    }

    init(modelType: Model.Type,
         storageAdapter: StorageEngineAdapter?,
         api: APICategoryGraphQLBehavior,
         auth: AuthCategoryBehavior?,
         incomingSubscriptionEvents: IncomingSubscriptionEventPublisher? = nil) {

        self.modelName = modelType.modelName

        self.storageAdapter = storageAdapter

        self.modelReconciliationQueueSubject = PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>()

        self.reconcileAndSaveQueue = OperationQueue()
        reconcileAndSaveQueue.name = "com.amazonaws.DataStore.\(modelType).reconcile"
        reconcileAndSaveQueue.maxConcurrentOperationCount = 1
        reconcileAndSaveQueue.underlyingQueue = DispatchQueue.global()
        reconcileAndSaveQueue.isSuspended = false

        self.incomingSubscriptionEventQueue = OperationQueue()
        incomingSubscriptionEventQueue.name = "com.amazonaws.DataStore.\(modelType).remoteEvent"
        incomingSubscriptionEventQueue.maxConcurrentOperationCount = 1
        incomingSubscriptionEventQueue.underlyingQueue = DispatchQueue.global()
        incomingSubscriptionEventQueue.isSuspended = true

        let resolvedIncomingSubscriptionEvents = incomingSubscriptionEvents ??
            AWSIncomingSubscriptionEventPublisher(modelType: modelType, api: api, auth: auth)
        self.incomingSubscriptionEvents = resolvedIncomingSubscriptionEvents

        self.incomingEventsSink = resolvedIncomingSubscriptionEvents
            .publisher
            .sink(receiveCompletion: { [weak self] completion in
                self?.receiveCompletion(completion)
                }, receiveValue: { [weak self] receiveValue in
                    self?.receive(receiveValue)
                })
    }

    /// (Re)starts the incoming subscription event queue.
    func start() {
        incomingSubscriptionEventQueue.isSuspended = false
        modelReconciliationQueueSubject.send(.started)
    }

    /// Pauses only the incoming subscription event queue. Events submitted via `enqueue` will still be processed
    func pause() {
        incomingSubscriptionEventQueue.isSuspended = true
        modelReconciliationQueueSubject.send(.paused)
    }

    /// Cancels all outstanding operations on both the incoming subscription event queue and the reconcile queue, and
    /// unsubscribes from the incoming events publisher. The queue may not be restarted after cancelling.
    func cancel() {
        incomingEventsSink?.cancel()
        incomingEventsSink = nil
        incomingSubscriptionEvents.cancel()
        reconcileAndSaveQueue.cancelAllOperations()
        incomingSubscriptionEventQueue.cancelAllOperations()
    }

    func enqueue(_ remoteModel: MutationSync<AnyModel>) {
        let reconcileOp = ReconcileAndLocalSaveOperation(remoteModel: remoteModel,
                                                         storageAdapter: storageAdapter)
        reconcileAndLocalSaveOperationSink = reconcileOp.publisher.sink(receiveCompletion: { error in
            self.modelReconciliationQueueSubject.send(completion: error)
        }, receiveValue: { mutationEvent in
            self.modelReconciliationQueueSubject.send(.mutationEvent(mutationEvent))
        })
        reconcileAndSaveQueue.addOperation(reconcileOp)
    }

    private func receive(_ receive: IncomingSubscriptionEventPublisherEvent) {
        switch receive {
        case .mutationEvent(let remoteModel):
            incomingSubscriptionEventQueue.addOperation(CancelAwareBlockOperation {
                self.enqueue(remoteModel)
            })
        case .connectionConnected:
            modelReconciliationQueueSubject.send(.connected(modelName))
        }
    }
    private func receiveCompletion(_ completion: Subscribers.Completion<DataStoreError>) {
        switch completion {
        case .finished:
            log.info("receivedCompletion: finished")
            modelReconciliationQueueSubject.send(completion: .finished)
        case .failure(let dataStoreError):
            log.error("receiveCompletion: error: \(dataStoreError)")
            modelReconciliationQueueSubject.send(completion: .failure(dataStoreError))
        }
    }
}

@available(iOS 13.0, *)
extension AWSModelReconciliationQueue: DefaultLogger { }

@available(iOS 13.0, *)
extension AWSModelReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()

        incomingEventsSink?.cancel()

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
            self.incomingSubscriptionEventQueue.cancelAllOperations()
            self.incomingSubscriptionEventQueue.waitUntilAllOperationsAreFinished()
            group.leave()
        }

        group.wait()

        onComplete()
    }

}
