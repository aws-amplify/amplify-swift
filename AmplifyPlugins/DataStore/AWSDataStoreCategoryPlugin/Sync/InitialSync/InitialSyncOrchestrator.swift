//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
protocol InitialSyncOrchestrator {
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> { get }
    func sync(completion: @escaping (Result<Void, DataStoreError>) -> Void)
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
    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private var initialSyncOperationSinks: [String: AnyCancellable]

    private let dataStoreConfiguration: DataStoreConfiguration
    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?

    private var completion: SyncOperationResultHandler?

    private var syncErrors: [DataStoreError]

    // Future optimization: can perform sync on each root in parallel, since we know they won't have any
    // interdependencies
    private let syncOperationQueue: OperationQueue
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.InitialSyncOrchestrator.concurrencyQueue",
                                                 target: DispatchQueue.global())

    private let initialSyncOrchestratorTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOrchestratorTopic.eraseToAnyPublisher()
    }

    init(dataStoreConfiguration: DataStoreConfiguration,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?) {
        self.initialSyncOperationSinks = [:]
        self.dataStoreConfiguration = dataStoreConfiguration
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter

        let syncOperationQueue = OperationQueue()
        syncOperationQueue.name = "com.amazon.InitialSyncOrchestrator.syncOperationQueue"
        syncOperationQueue.maxConcurrentOperationCount = 1
        syncOperationQueue.isSuspended = true
        self.syncOperationQueue = syncOperationQueue

        self.syncErrors = []
        self.initialSyncOrchestratorTopic = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
    }

    /// Performs an initial sync on all models. This should only be called by the
    /// RemoteSyncEngine during startup. Calling this multiple times will result in
    /// undefined behavior.
    func sync(completion: @escaping SyncOperationResultHandler) {
        concurrencyQueue.async {
            self.completion = completion

            self.log.info("Beginning initial sync")

            let syncableModelSchemas = ModelRegistry.modelSchemas.filter { $0.isSyncable }
            self.enqueueSyncableModels(syncableModelSchemas)

            let modelNames = syncableModelSchemas.map { $0.name }
            self.dispatchSyncQueriesStarted(for: modelNames)
            self.syncOperationQueue.isSuspended = false
        }
    }

    private func enqueueSyncableModels(_ syncableModelSchemas: [ModelSchema]) {
        let sortedModelSchemas = syncableModelSchemas.sortByDependencyOrder()
        for modelSchema in sortedModelSchemas {
            enqueueSyncOperation(for: modelSchema)
        }
    }

    /// Enqueues sync operations for models and downstream dependencies
    private func enqueueSyncOperation(for modelSchema: ModelSchema) {
        let initialSyncForModel = InitialSyncOperation(modelSchema: modelSchema,
                                                       api: api,
                                                       reconciliationQueue: reconciliationQueue,
                                                       storageAdapter: storageAdapter,
                                                       dataStoreConfiguration: dataStoreConfiguration)

        initialSyncOperationSinks[modelSchema.name] = initialSyncForModel
            .publisher
            .receive(on: concurrencyQueue)
            .sink(receiveCompletion: { result in
                if case .failure(let dataStoreError) = result {
                    let syncError = DataStoreError.sync(
                        "An error occurred syncing \(modelSchema.name)",
                        "",
                        dataStoreError)
                    self.syncErrors.append(syncError)
                }
                self.initialSyncOperationSinks.removeValue(forKey: modelSchema.name)
                self.onReceiveCompletion()
            }, receiveValue: onReceiveValue(_:))

        syncOperationQueue.addOperation(initialSyncForModel)
    }

    private func onReceiveValue(_ value: InitialSyncOperationEvent) {
        initialSyncOrchestratorTopic.send(value)
    }

    private func onReceiveCompletion() {
        guard initialSyncOperationSinks.isEmpty else {
            return
        }

        let completionResult = makeCompletionResult()
        switch completionResult {
        case .success:
            initialSyncOrchestratorTopic.send(completion: .finished)
        case .failure(let error):
            initialSyncOrchestratorTopic.send(completion: .failure(error))
        }
        completion?(completionResult)
    }

    private func makeCompletionResult() -> Result<Void, DataStoreError> {
        guard syncErrors.isEmpty else {
            let allMessages = syncErrors.map { String(describing: $0) }
            let syncError = DataStoreError.sync(
                "One or more errors occurred syncing models. See below for detailed error description.",
                allMessages.joined(separator: "\n")
            )
            return .failure(syncError)
        }
        return .successfulVoid
    }

    private func dispatchSyncQueriesStarted(for modelNames: [String]) {
        let syncQueriesStartedEvent = SyncQueriesStartedEvent(models: modelNames)
        let syncQueriesStartedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesStarted,
                                                        data: syncQueriesStartedEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesStartedEventPayload)
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
