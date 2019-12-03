//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

@available(iOS 13.0, *)
final class InitialSyncOrchestrator {
    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconiliationQueues: IncomingEventReconciliationQueues?
    private weak var storageAdapter: StorageEngineAdapter?
    private var completion: (SyncOperationResult) -> Void

    private var syncErrors: AtomicValue<[DataStoreError]>

    // Future optimization: can perform sync on each root in parallel, since we know they won't have any
    // interdependencies
    private let syncOperationQueue: OperationQueue

    init(api: APICategoryGraphQLBehavior,
         reconiliationQueues: IncomingEventReconciliationQueues,
         storageAdapter: StorageEngineAdapter,
         completion: @escaping (Result<Void, DataStoreError>) -> Void) {
        self.api = api
        self.reconiliationQueues = reconiliationQueues
        self.storageAdapter = storageAdapter
        self.completion = completion

        let syncOperationQueue = OperationQueue()
        syncOperationQueue.name = "com.amazon.InitialSyncOrchestrator"
        syncOperationQueue.maxConcurrentOperationCount = 1
        syncOperationQueue.isSuspended = true
        self.syncOperationQueue = syncOperationQueue

        self.syncErrors = AtomicValue(initialValue: [])
    }

    /// Performs an initial sync on all models. This method blocks the current queue until all sync operations have
    /// completed.
    func sync() {
        log.info("Beginning initial sync")
        let roots = getModelRoots()

        for root in roots {
            enqueueSyncOperation(for: root)
        }

        syncOperationQueue.isSuspended = false
        syncOperationQueue.waitUntilAllOperationsAreFinished()

        // TODO: How to usefully report errors from multiple sync operations?
        let errors = syncErrors.get()
        guard errors.isEmpty else {
            let allMessages = errors.map { String(describing: $0) }
            let syncError = DataStoreError.sync(
                "One or more errors occurred syncing models. See below for detailed error description.",
                allMessages.joined(separator: "\n")
            )
            completion(.failure(syncError))
            return
        }

        completion(.success(()))
    }

    /// Creates a graph of registered models and returns the roots.
    private func getModelRoots() -> [DirectedGraphNode<Model.Type>] {
        let syncableModels = ModelRegistry.models.filter { !$0.schema.isSystem }
        let modelGraphs = ModelGraphs(models: syncableModels)
        let roots = modelGraphs.roots
        return roots
    }

    /// Recursively enqueues sync operations for models and downstream dependencies
    private func enqueueSyncOperation(for root: DirectedGraphNode<Model.Type>) {
        guard let api = api else {
            completion(.failure(DataStoreError.nilAPIHandle()))
            return
        }

        guard let storageAdapter = storageAdapter else {
            completion(.failure(DataStoreError.nilStorageAdapter()))
            return
        }

        guard let reconiliationQueues = reconiliationQueues else {
            completion(.failure(DataStoreError.nilStorageAdapter()))
            return
        }

        let completion: SyncOperationResultHandler = { result in
            if case .failure(let dataStoreError) = result {
                let syncError = DataStoreError.sync(
                    "An error occurred syncing \(root.value.modelName)",
                    "",
                    dataStoreError)
                self.syncErrors.append(syncError)
            }
        }

        let initialSyncForModel = InitialSyncOperation(modelType: root.value,
                                                       api: api,
                                                       reconiliationQueues: reconiliationQueues,
                                                       storageAdapter: storageAdapter,
                                                       completion: completion)

        syncOperationQueue.addOperation(initialSyncForModel)

        for downstream in root.downstream {
            enqueueSyncOperation(for: downstream)
        }
    }
}

@available(iOS 13.0, *)
extension InitialSyncOrchestrator: DefaultLogger { }
