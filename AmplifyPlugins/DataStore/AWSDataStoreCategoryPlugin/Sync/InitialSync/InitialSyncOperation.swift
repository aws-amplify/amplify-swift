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
final class InitialSyncOperation: AsynchronousOperation {
    typealias SyncQueryResult = PaginatedList<AnyModel>

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?
    private let dataStoreConfiguration: DataStoreConfiguration
    private let authModeStrategy: AuthModeStrategy

    private let modelSchema: ModelSchema

    private var recordsReceived: UInt

    private var syncMaxRecords: UInt {
        return dataStoreConfiguration.syncMaxRecords
    }
    private var syncPageSize: UInt {
        return dataStoreConfiguration.syncPageSize
    }

    private let initialSyncOperationTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOperationTopic.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?,
         dataStoreConfiguration: DataStoreConfiguration,
         authModeStrategy: AuthModeStrategy) {
        self.modelSchema = modelSchema
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        self.authModeStrategy = authModeStrategy

        self.recordsReceived = 0
        self.initialSyncOperationTopic = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
    }

    override func main() {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        log.info("Beginning sync for \(modelSchema.name)")
        let lastSyncTime = getLastSyncTime()
        let syncType: SyncType = lastSyncTime == nil ? .fullSync : .deltaSync
        initialSyncOperationTopic.send(.started(modelName: modelSchema.name, syncType: syncType))
        query(lastSyncTime: lastSyncTime)
    }

    private func getLastSyncTime() -> Int? {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return nil
        }

        let lastSyncMetadata = getLastSyncMetadata()
        guard let lastSync = lastSyncMetadata?.lastSync else {
            return nil
        }

        let lastSyncDate = Date(timeIntervalSince1970: TimeInterval.milliseconds(Double(lastSync)))
        let secondsSinceLastSync = (lastSyncDate.timeIntervalSinceNow * -1)
        if secondsSinceLastSync < 0 {
            log.info("lastSyncTime was in the future, assuming base query")
            return nil
        }

        let shouldDoDeltaQuery = secondsSinceLastSync < dataStoreConfiguration.syncInterval
        return shouldDoDeltaQuery ? lastSync : nil
    }

    private func getLastSyncMetadata() -> ModelSyncMetadata? {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return nil
        }

        guard let storageAdapter = storageAdapter else {
            log.error(error: DataStoreError.nilStorageAdapter())
            return nil
        }

        do {
            let modelSyncMetadata = try storageAdapter.queryModelSyncMetadata(for: modelSchema)
            return modelSyncMetadata
        } catch {
            log.error(error: error)
            return nil
        }
    }

    private func query(lastSyncTime: Int?, nextToken: String? = nil) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let api = api else {
            finish(result: .failure(DataStoreError.nilAPIHandle()))
            return
        }
        let minSyncPageSize = Int(min(syncMaxRecords - recordsReceived, syncPageSize))
        let limit = minSyncPageSize < 0 ? Int(syncPageSize) : minSyncPageSize
        let syncExpression = dataStoreConfiguration.syncExpressions.first {
            $0.modelSchema.name == modelSchema.name
        }
        let queryPredicate = syncExpression?.modelPredicate()

        let completionListener: GraphQLOperation<SyncQueryResult>.ResultListener = { result in
            switch result {
            case .failure(let apiError):
                if self.isAuthSignedOutError(apiError: apiError) {
                    self.dataStoreConfiguration.errorHandler(DataStoreError.api(apiError))
                }
                // TODO: Retry query on error
                self.finish(result: .failure(DataStoreError.api(apiError)))
            case .success(let graphQLResult):
                self.handleQueryResults(lastSyncTime: lastSyncTime, graphQLResult: graphQLResult)
            }
        }

        var authTypes = authModeStrategy.authTypesFor(schema: modelSchema,
                                                                             operation: .read)

        RetryableGraphQLOperation(requestFactory: {
            GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: self.modelSchema,
                                                      where: queryPredicate,
                                                      limit: limit,
                                                      nextToken: nextToken,
                                                      lastSync: lastSyncTime,
                                                      authType: authTypes.next())
        },
                                  maxRetries: authTypes.count,
                                  resultListener: completionListener) { nextRequest, wrappedCompletionListener in
            api.query(request: nextRequest, listener: wrappedCompletionListener)
        }.main()
    }

    /// Disposes of the query results: Stops if error, reconciles results if success, and kick off a new query if there
    /// is a next token
    private func handleQueryResults(lastSyncTime: Int?,
                                    graphQLResult: Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>>) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let reconciliationQueue = reconciliationQueue else {
            finish(result: .failure(DataStoreError.nilReconciliationQueue()))
            return
        }

        let syncQueryResult: SyncQueryResult
        switch graphQLResult {
        case .failure(let graphQLResponseError):
            finish(result: .failure(DataStoreError.api(graphQLResponseError)))
            return
        case .success(let queryResult):
            syncQueryResult = queryResult
        }

        let items = syncQueryResult.items
        recordsReceived += UInt(items.count)

        reconciliationQueue.offer(items, modelName: modelSchema.name)
        for item in items {
            initialSyncOperationTopic.send(.enqueued(item, modelName: modelSchema.name))
        }

        if let nextToken = syncQueryResult.nextToken, recordsReceived < syncMaxRecords {
            DispatchQueue.global().async {
                self.query(lastSyncTime: lastSyncTime, nextToken: nextToken)
            }
        } else {
            updateModelSyncMetadata(lastSyncTime: syncQueryResult.startedAt)
        }
    }

    private func updateModelSyncMetadata(lastSyncTime: Int?) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let storageAdapter = storageAdapter else {
            finish(result: .failure(DataStoreError.nilStorageAdapter()))
            return
        }

        let syncMetadata = ModelSyncMetadata(id: modelSchema.name, lastSync: lastSyncTime)
        storageAdapter.save(syncMetadata, condition: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                self.finish(result: .failure(dataStoreError))
            case .success:
                self.finish(result: .successfulVoid)
            }
        }
    }

    private func isAuthSignedOutError(apiError: APIError) -> Bool {
        if case let .operationError(_, _, underlyingError) = apiError,
            let authError = underlyingError as? AuthError,
            case .signedOut = authError {
            return true
        }

        return false
    }

    private func finish(result: AWSInitialSyncOrchestrator.SyncOperationResult) {
        switch result {
        case .failure(let error):
            initialSyncOperationTopic.send(.finished(modelName: modelSchema.name, error: error))
            initialSyncOperationTopic.send(completion: .failure(error))
        case .success:
            initialSyncOperationTopic.send(.finished(modelName: modelSchema.name))
            initialSyncOperationTopic.send(completion: .finished)
        }
        super.finish()
    }

}

@available(iOS 13.0, *)
extension InitialSyncOperation: DefaultLogger { }
