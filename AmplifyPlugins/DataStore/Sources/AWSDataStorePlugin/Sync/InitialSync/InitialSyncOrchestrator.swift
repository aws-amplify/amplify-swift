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

protocol InitialSyncOrchestrator {
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> { get }
    func sync(completion: @escaping (Result<Void, DataStoreError>) -> Void)
}

// For testing
typealias InitialSyncOrchestratorFactory =
    (DataStoreConfiguration,
     AuthModeStrategy,
     APICategoryGraphQLBehaviorExtended?,
    IncomingEventReconciliationQueue?,
    StorageEngineAdapter?) -> InitialSyncOrchestrator

final class AWSInitialSyncOrchestrator: InitialSyncOrchestrator {
    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private var initialSyncOperationSinks: [String: AnyCancellable]

    private let dataStoreConfiguration: DataStoreConfiguration
    private weak var api: APICategoryGraphQLBehaviorExtended?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?
    private let authModeStrategy: AuthModeStrategy

    private var completion: SyncOperationResultHandler?

    private var syncErrors: [DataStoreError]

    // Future optimization: can perform sync on each root in parallel, since we know they won't have any
    // interdependencies
    let syncOperationQueue: OperationQueue
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.InitialSyncOrchestrator.concurrencyQueue",
                                                 target: DispatchQueue.global())

    private let initialSyncOrchestratorTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOrchestratorTopic.eraseToAnyPublisher()
    }

    init(dataStoreConfiguration: DataStoreConfiguration,
         authModeStrategy: AuthModeStrategy,
         api: APICategoryGraphQLBehaviorExtended?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?) {
        self.initialSyncOperationSinks = [:]
        self.dataStoreConfiguration = dataStoreConfiguration
        self.authModeStrategy = authModeStrategy
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
            if !syncableModelSchemas.hasAssociations() {
                self.syncOperationQueue.maxConcurrentOperationCount = syncableModelSchemas.count
            }
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
                                                       dataStoreConfiguration: dataStoreConfiguration,
                                                       authModeStrategy: authModeStrategy)

        initialSyncOperationSinks[modelSchema.name] = initialSyncForModel
            .publisher
            .receive(on: concurrencyQueue)
            .sink(receiveCompletion: { result in self.onReceiveCompletion(modelSchema: modelSchema,
                                                                          result: result) },
                  receiveValue: onReceiveValue(_:))

        syncOperationQueue.addOperation(initialSyncForModel)
    }

    private func onReceiveValue(_ value: InitialSyncOperationEvent) {
        initialSyncOrchestratorTopic.send(value)
    }

    private func onReceiveCompletion(modelSchema: ModelSchema, result: Subscribers.Completion<DataStoreError>) {
        if case .failure(let dataStoreError) = result {
            let syncError = DataStoreError.sync(
                "An error occurred syncing \(modelSchema.name)",
                "",
                dataStoreError)
            self.syncErrors.append(syncError)
        }

        initialSyncOperationSinks.removeValue(forKey: modelSchema.name)

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
        if syncErrors.isEmpty || syncErrors.allSatisfy(isUnauthorizedError) {
            return .successfulVoid
        }

        var underlyingError: Error?
        if let error = syncErrors.first(where: isNetworkError(_:)) {
            underlyingError = getUnderlyingNetworkError(error)
        }

        let allMessages = syncErrors.map { String(describing: $0) }
        let syncError = DataStoreError.sync(
            "One or more errors occurred syncing models. See below for detailed error description.",
            allMessages.joined(separator: "\n"),
            underlyingError
        )
        return .failure(syncError)
    }

    private func dispatchSyncQueriesStarted(for modelNames: [String]) {
        let syncQueriesStartedEvent = SyncQueriesStartedEvent(models: modelNames)
        let syncQueriesStartedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesStarted,
                                                        data: syncQueriesStartedEvent)
        log.verbose("[Lifecycle event 2]: syncQueriesStarted")
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesStartedEventPayload)
    }
}

extension AWSInitialSyncOrchestrator: DefaultLogger { }

extension AWSInitialSyncOrchestrator: Resettable {
    func reset() {
        syncOperationQueue.cancelAllOperations()
        syncOperationQueue.waitUntilAllOperationsAreFinished()
    }
}

extension AWSInitialSyncOrchestrator {
    private typealias ResponseType = PaginatedList<AnyModel>
    private func graphqlErrors(from error: GraphQLResponseError<ResponseType>?) -> [GraphQLError]? {
        if case let .error(errors) = error {
            return errors
        }
        return nil
    }

    private func errorTypeValueFrom(graphQLError: GraphQLError) -> String? {
        guard case let .string(errorTypeValue) = graphQLError.extensions?["errorType"] else {
            return nil
        }
        return errorTypeValue
    }

    private func isUnauthorizedError(_ error: DataStoreError) -> Bool {
        guard case let .sync(_, _, underlyingError) = error,
              let datastoreError = underlyingError as? DataStoreError
              else {
            return false
        }

        if case let .api(apiError, _) = datastoreError,
           let responseError = apiError as? GraphQLResponseError<ResponseType>,
           let graphQLError = graphqlErrors(from: responseError)?.first,
           let errorTypeValue = errorTypeValueFrom(graphQLError: graphQLError),
           case .unauthorized = AppSyncErrorType(errorTypeValue) {
            return true
        }
        return false
    }

    private func isNetworkError(_ error: DataStoreError) -> Bool {
        guard case let .sync(_, _, underlyingError) = error,
              let datastoreError = underlyingError as? DataStoreError
              else {
            return false
        }

        if case let .api(amplifyError, _) = datastoreError,
           let apiError = amplifyError as? APIError,
           case .networkError = apiError {
            return true
        }

        return false
    }

    private func getUnderlyingNetworkError(_ error: DataStoreError) -> Error? {
        guard case let .sync(_, _, underlyingError) = error,
              let datastoreError = underlyingError as? DataStoreError
              else {
            return nil
        }

        if case let .api(amplifyError, _) = datastoreError,
           let apiError = amplifyError as? APIError,
           case let .networkError(_, _, underlyingError) = apiError {
            return underlyingError
        }

        return nil
    }
}
