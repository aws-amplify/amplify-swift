//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

protocol InitialSyncOrchestrator {
    func sync(completion: @escaping (Result<Void, DataStoreError>) -> Void)
}

@available(iOS 13.0, *)
final class AWSInitialSyncOrchestrator: InitialSyncOrchestrator {
    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?

    private var completion: SyncOperationResultHandler?

    private var syncErrors: [DataStoreError]

    // Future optimization: can perform sync on each root in parallel, since we know they won't have any
    // interdependencies
    private let syncOperationQueue: OperationQueue

    init(api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?) {
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter

        let syncOperationQueue = OperationQueue()
        syncOperationQueue.name = "com.amazon.InitialSyncOrchestrator"
        syncOperationQueue.maxConcurrentOperationCount = 1
        syncOperationQueue.isSuspended = true
        self.syncOperationQueue = syncOperationQueue

        self.syncErrors = []
    }

    /// Performs an initial sync on all models
    func sync(completion: @escaping SyncOperationResultHandler) {
        self.completion = completion

        log.info("Beginning initial sync")
        let roots = getModelRoots()

        for root in roots {
            enqueueSyncOperation(for: root)
        }

        // This operation is intentionally not cancel-aware; we always want resolveCompletion to execute
        // as the last item
        syncOperationQueue.addOperation {
            self.resolveCompletion()
        }

        syncOperationQueue.isSuspended = false
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
        let syncOperationCompletion: SyncOperationResultHandler = { result in
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
                                                       reconciliationQueue: reconciliationQueue,
                                                       storageAdapter: storageAdapter,
                                                       completion: syncOperationCompletion)

        syncOperationQueue.addOperation(initialSyncForModel)

        for downstream in root.downstream {
            enqueueSyncOperation(for: downstream)
        }
    }

    private func resolveCompletion() {
        // TODO: Invoke error callback for sync errors
        guard syncErrors.isEmpty else {
            let allMessages = syncErrors.map { String(describing: $0) }
            let syncError = DataStoreError.sync(
                "One or more errors occurred syncing models. See below for detailed error description.",
                allMessages.joined(separator: "\n")
            )
            completion?(.failure(syncError))
            return
        }

        completion?(.successfulVoid)
    }

}

@available(iOS 13.0, *)
extension AWSInitialSyncOrchestrator: DefaultLogger { }
