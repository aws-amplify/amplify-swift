//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

protocol InitialSyncOrchestrator {
    func sync(completion: @escaping (Result<ModelSyncedPayload?, DataStoreError>) -> Void)
}

// For testing
@available(iOS 13.0, *)
typealias InitialSyncOrchestratorFactory =
    (DataStoreConfiguration,
    APICategoryGraphQLBehavior?,
    IncomingEventReconciliationQueue?,
    StorageEngineAdapter?) -> InitialSyncOrchestrator

@available(iOS 13.0, *)
final class AWSInitialSyncOrchestrator: InitialSyncOrchestrator {
    typealias SyncOperationResult = Result<ModelSyncedPayload?, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private let dataStoreConfiguration: DataStoreConfiguration
    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?

    private var completion: SyncOperationResultHandler?

    private var syncErrors: [DataStoreError]

    // Future optimization: can perform sync on each root in parallel, since we know they won't have any
    // interdependencies
    private let syncOperationQueue: OperationQueue

    init(dataStoreConfiguration: DataStoreConfiguration,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?) {
        self.dataStoreConfiguration = dataStoreConfiguration
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

        let syncableModels = ModelRegistry.models.filter { $0.schema.isSyncable }
        enqueueSyncableModels(syncableModels)

        // This operation is intentionally not cancel-aware; we always want resolveCompletion to execute
        // as the last item
        syncOperationQueue.addOperation {
            self.resolveCompletion()
        }

        syncOperationQueue.isSuspended = false

        dispatchSyncQueriesStarted(syncableModels)
    }

    private func enqueueSyncableModels(_ syncableModels: [Model.Type]) {
        let sortedModels = syncableModels.sortByDependencyOrder()
        for model in sortedModels {
            enqueueSyncOperation(for: model)
        }
    }

    /// Enqueues sync operations for models and downstream dependencies
    private func enqueueSyncOperation(for modelType: Model.Type) {
        let syncOperationCompletion: SyncOperationResultHandler = { result in
            switch result {
            case .failure(let dataStoreError):
                let syncError = DataStoreError.sync(
                    "An error occurred syncing \(modelType.modelName)",
                    "",
                    dataStoreError)
                self.syncErrors.append(syncError)
            case .success(let modelSyncedPayload):
                let payload = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                         data: modelSyncedPayload)
                Amplify.Hub.dispatch(to: .dataStore, payload: payload)
            }
        }

        let initialSyncForModel = InitialSyncOperation(modelType: modelType,
                                                       api: api,
                                                       reconciliationQueue: reconciliationQueue,
                                                       storageAdapter: storageAdapter,
                                                       dataStoreConfiguration: dataStoreConfiguration,
                                                       completion: syncOperationCompletion)

        syncOperationQueue.addOperation(initialSyncForModel)
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

<<<<<<< HEAD
        completion?(.success(nil))
    }

    private func dispatchSyncQueriesStarted(_ syncableModels: [Model.Type]) {
        let modelTask = syncableModels.map { $0.modelName }
        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesStarted,
                                 data: ["models": modelTask])
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)
=======
        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        completion?(.successfulVoid)
>>>>>>> Network Status isn't implemented yet and need to check payload of modelSynced
    }

    private func dispatchSyncQueriesStarted(_ syncableModels: [Model.Type]) {
        let modelTask = syncableModels.map { $0.modelName }
        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesStarted,
                                 data: ["models": modelTask])
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)
    }

}

@available(iOS 13.0, *)
extension AWSInitialSyncOrchestrator: DefaultLogger { }

@available(iOS 13.0, *)
extension AWSInitialSyncOrchestrator: Resettable {
    func reset(onComplete: @escaping BasicClosure) {
        syncOperationQueue.cancelAllOperations()
        syncOperationQueue.waitUntilAllOperationsAreFinished()
        onComplete()
    }
}
