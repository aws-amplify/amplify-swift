//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

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
    private let incomingSubscriptionEvents: IncomingSubscriptionEventFacade

    /// A buffer queue for incoming subsscription events, waiting for this ReconciliationQueue to be `start`ed. Once
    /// the ReconciliationQueue is started, each event in the `incomingRemoveEventQueue` will be submitted to the
    /// `reconcileAndSaveQueue`.
    private let incomingSubscriptionEventQueue: OperationQueue

    /// Applies incoming mutation or subscription events serially to local data store for this model type. This queue
    /// is always active.
    private let reconcileAndSaveQueue: OperationQueue

    weak var storageAdapter: StorageEngineAdapter?

    private let modelName: String

    private var incomingEventsSink: AnyCancellable?

    init(modelType: Model.Type,
         storageAdapter: StorageEngineAdapter,
         api: APICategoryGraphQLBehavior) {
        self.storageAdapter = storageAdapter

        self.modelName = modelType.modelName

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

        let incomingSubscriptionEvents = IncomingSubscriptionEventFacade(modelType: modelType, api: api)
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        self.incomingEventsSink = incomingSubscriptionEvents
            .publisher
            .sink(receiveCompletion: { [weak self] completion in
                self?.receiveCompletion(completion)
                }, receiveValue: { [weak self] remoteModel in
                    self?.incomingSubscriptionEventQueue.addOperation(CancelAwareBlockOperation {
                        self?.enqueue(remoteModel)
                    })
            })

    }

    /// (Re)starts the incoming subscription event queue.
    func start() {
        incomingSubscriptionEventQueue.isSuspended = false
    }

    /// Pauses only the incoming subscription event queue. Events submitted via `enqueue` will still be processed
    func pause() {
        incomingSubscriptionEventQueue.isSuspended = true
    }

    /// Cancels all outstanding operations on both the incoming subscription event queue and the reconcile queue, and
    /// unsubscribes from the incoming events publisher. The queue may not be restarted after cancelling.
    func cancel() {
        incomingEventsSink?.cancel()
        incomingEventsSink = nil
        reconcileAndSaveQueue.cancelAllOperations()
        incomingSubscriptionEventQueue.cancelAllOperations()
    }

    func enqueue(_ remoteModel: MutationSync<AnyModel>) {
        guard let storageAdapter = storageAdapter else {
            log.error("No storage adapter, cannot save received value")
            return
        }

        let reconcileOp = ReconcileAndLocalSaveOperation(remoteModel: remoteModel,
                                                         storageAdapter: storageAdapter)
        reconcileAndSaveQueue.addOperation(reconcileOp)
    }

    private func receiveCompletion(_ completion: Subscribers.Completion<DataStoreError>) {
        switch completion {
        case .finished:
            log.info("receivedCompletion: finished")
        case .failure(let dataStoreError):
            log.error("receiveCompletion: error: \(dataStoreError)")
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

        group.enter()
        DispatchQueue.global().async {
            self.incomingSubscriptionEvents.reset { group.leave() }
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
