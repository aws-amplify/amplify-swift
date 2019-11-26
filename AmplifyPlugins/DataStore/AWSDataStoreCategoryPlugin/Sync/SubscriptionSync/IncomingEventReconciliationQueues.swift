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

/// A collection of queues, one per syncable model type, that reconcile all incoming events for a model: responses
/// from locally-sourced mutations, and subscription events for create, update, and delete events initiated by remote
/// systems.
final class IncomingEventReconciliationQueues {

    private var reconciliationQueues = [String: ReconciliationQueue]()

    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter) {
        for modelType in modelTypes {
            let modelName = modelType.modelName
            let queue = ReconciliationQueue(modelType: modelType, storageAdapter: storageAdapter, api: api)
            guard reconciliationQueues[modelName] == nil else {
                Amplify.DataStore.log
                    .warn("Duplicate model name found: \(modelName), not subscribint to skipping \(modelType)")
                continue
            }
            reconciliationQueues[modelName] = queue
        }
    }

    func start() {
        reconciliationQueues.values.forEach { $0.start() }
    }

}

/// A queue of reconciliation operations, merged from incoming subscription events and responses to locally-sourced
/// mutations for a single model type.
///
/// Although subscriptions are listened to and enqueued at initialization, you must call `start` on a
/// ReconciliationQueue to write events to the DataStore.
final class ReconciliationQueue {

    private let operationQueue: OperationQueue
    private weak var storageAdapter: StorageEngineAdapter?

    private let modelName: String

    private let incomingSubscriptionEvents: IncomingMutationEventFacade

    private var allModels: AnyCancellable?

    init(modelType: Model.Type,
         storageAdapter: StorageEngineAdapter,
         api: APICategoryGraphQLBehavior) {
        self.storageAdapter = storageAdapter

        self.modelName = modelType.modelName

        self.operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.DataStore.ReconciliationQueue.\(modelType)"
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.underlyingQueue = DispatchQueue.global()
        operationQueue.isSuspended = true

        let incomingSubscriptionEvents = IncomingMutationEventFacade(modelType: modelType, api: api)
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        self.allModels = incomingSubscriptionEvents
            .publisher
            .sink(receiveCompletion: { [weak self] completion in
                self?.receiveCompletion(completion)
                }, receiveValue: { [weak self] anyModel in
                    self?.receiveValue(anyModel)
            })

    }

    func start() {
        operationQueue.isSuspended = false
    }

    func cancel() {
        operationQueue.cancelAllOperations()
        allModels?.cancel()
    }

    private func receiveValue(_ anyModel: AnyModel) {
        guard let storageAdapter = storageAdapter else {
            log.error("No storage adapter, cannot save received value")
            return
        }

        let reconcileOp = ReconcileAndLocalSaveOperation(anyModel: anyModel,
                                                         storageAdapter: storageAdapter)
        operationQueue.addOperation(reconcileOp)
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

extension ReconciliationQueue: DefaultLogger { }
