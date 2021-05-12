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
         dataStoreConfiguration: DataStoreConfiguration) {
        self.modelSchema = modelSchema
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
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

        //TODO: Update to use TimeInterval.milliseconds when it is pushed to main branch
        // https://github.com/aws-amplify/amplify-ios/issues/398
        let lastSyncDate = Date(timeIntervalSince1970: TimeInterval(lastSync) / 1_000)
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
            log.error("\(#function): API unexpectedly nil")
            finish(result: .failure(DataStoreError.nilAPIHandle()))
            return
        }
        let minSyncPageSize = Int(min(syncMaxRecords - recordsReceived, syncPageSize))
        let limit = minSyncPageSize < 0 ? Int(syncPageSize) : minSyncPageSize
        let syncExpression = dataStoreConfiguration.syncExpressions.first {
            $0.modelSchema.name == modelSchema.name
        }
        let queryPredicate = syncExpression?.modelPredicate()
        var authTypes = dataStoreConfiguration.authModeStrategy.authTypesFor(
            schema: modelSchema,
            operation: .read)

        makeAPIRequest(lastSyncTime: lastSyncTime,
                                       limit: limit,
                                       queryPredicate: queryPredicate,
                                       nextToken: nextToken,
                                       authType: authTypes.next(),
                                       authTypeFactory: { authTypes.next() })
    }

    /// Performs given API request, retries if error is retriable
    private func makeAPIRequest(lastSyncTime: Int?,
                                limit: Int,
                                queryPredicate: QueryPredicate?,
                                nextToken: String? = nil,
                                authType: AWSAuthorizationType?,
                                authTypeFactory: @escaping () -> AWSAuthorizationType?) {
        let request = createAPIRequest(lastSyncTime: lastSyncTime,
                                       limit: limit,
                                       queryPredicate: queryPredicate,
                                       nextToken: nextToken,
                                       authType: authTypeFactory())

        _ = api?.query(request: request) { result in
            switch result {
            case .failure(let apiError):
                if self.isNotAuthorizedError(apiError: apiError), let nextAuthType = authTypeFactory() {
                    self.log.debug("Received Unauthorized API error: \(apiError), retrying with auth type \(nextAuthType)")
                    self.makeAPIRequest(lastSyncTime: lastSyncTime,
                                   limit: limit,
                                   queryPredicate: queryPredicate,
                                   authType: nextAuthType,
                                   authTypeFactory: authTypeFactory)
                    return
                }

                if self.isAuthSignedOutError(apiError: apiError) {
                    self.dataStoreConfiguration.errorHandler(DataStoreError.api(apiError))
                }
                // TODO: Retry query on error
                self.finish(result: .failure(DataStoreError.api(apiError)))
            case .success(let graphQLResult):
                self.handleQueryResults(lastSyncTime: lastSyncTime, graphQLResult: graphQLResult)
            }
        }
    }

    private func createAPIRequest(lastSyncTime: Int?,
                                  limit: Int,
                                  queryPredicate: QueryPredicate?,
                                  nextToken: String? = nil,
                                  authType: AWSAuthorizationType? = nil) -> GraphQLRequest<SyncQueryResult> {
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: modelSchema,
                                                                where: queryPredicate,
                                                                limit: limit,
                                                                nextToken: nextToken,
                                                                lastSync: lastSyncTime,
                                                                authType: authType)
        return request
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

        reconciliationQueue.offer(items, modelSchema: modelSchema)
        for item in items {
            initialSyncOperationTopic.send(.enqueued(item))
        }

        if let nextToken = syncQueryResult.nextToken, recordsReceived < syncMaxRecords {
            DispatchQueue.global().async {
                self.query(lastSyncTime: lastSyncTime, nextToken: nextToken)
            }
        } else {
            initialSyncOperationTopic.send(.finished(modelName: modelSchema.name))
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

    private func finish(result: AWSInitialSyncOrchestrator.SyncOperationResult) {
        switch result {
        case .failure(let error):
            initialSyncOperationTopic.send(completion: .failure(error))
        case .success:
            initialSyncOperationTopic.send(completion: .finished)
        }
        super.finish()
    }

}


// MARK: - Error handling
@available(iOS 13.0, *)
extension InitialSyncOperation {
    private func isAuthSignedOutError(apiError: APIError) -> Bool {
        if case let .operationError(_, _, underlyingError) = apiError,
            let authError = underlyingError as? AuthError,
            case .signedOut = authError {
            return true
        }

        return false
    }

    private func isNotAuthorizedError(apiError: APIError) -> Bool {
        if case let .operationError(_, _, underlyingError) = apiError,
            let authError = underlyingError as? AuthError,
            case .notAuthorized = authError {
            return true
        }

        return false
    }
}

// MARK: - Logger
@available(iOS 13.0, *)
extension InitialSyncOperation: DefaultLogger { }
