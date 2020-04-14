//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

@available(iOS 13.0, *)
final class InitialSyncOperation: AsynchronousOperation {
    typealias SyncQueryResult = PaginatedList<AnyModel>

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?
    private let dataStoreConfiguration: DataStoreConfiguration

    private let modelType: Model.Type
    private let completion: AWSInitialSyncOrchestrator.SyncOperationResultHandler

    private var lastSyncTime: Int?

    init(modelType: Model.Type,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?,
         dataStoreConfiguration: DataStoreConfiguration,
         completion: @escaping AWSInitialSyncOrchestrator.SyncOperationResultHandler) {
        self.modelType = modelType
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        self.completion = completion
    }

    override func main() {
        guard !isCancelled else {
            super.finish()
            return
        }

        log.info("Beginning sync for \(modelType.modelName)")
        setUpLastSyncTime()
        query()
    }

    private func setUpLastSyncTime() {
        guard !isCancelled else {
            super.finish()
            return
        }

        let lastSyncMetadata = getLastSyncMetadata()
        guard let lastSync = lastSyncMetadata?.lastSync else {
            return
        }

        //TODO: Update to use TimeInterval.milliseconds when it is pushed to master branch
        // https://github.com/aws-amplify/amplify-ios/issues/398
        let lastSyncDate = Date(timeIntervalSince1970: TimeInterval(lastSync) / 1_000)
        let secondsSinceLastSync = (lastSyncDate.timeIntervalSinceNow * -1)
        if secondsSinceLastSync < 0 {
            log.info("lastSyncTime was in the future, assuming base query")
            lastSyncTime = nil
            return
        }

        let shouldDoDeltaQuery = secondsSinceLastSync < dataStoreConfiguration.syncInterval
        if shouldDoDeltaQuery {
            lastSyncTime = lastSync
        }
    }

    private func getLastSyncMetadata() -> ModelSyncMetadata? {
        guard !isCancelled else {
            super.finish()
            return nil
        }

        guard let storageAdapter = storageAdapter else {
            log.error(error: DataStoreError.nilStorageAdapter())
            return nil
        }

        do {
            let modelSyncMetadata = try storageAdapter.queryModelSyncMetadata(for: modelType)
            return modelSyncMetadata
        } catch {
            log.error(error: error)
            return nil
        }

    }

    private func query(nextToken: String? = nil) {
        guard !isCancelled else {
            super.finish()
            return
        }

        guard let api = api else {
            finish(result: .failure(DataStoreError.nilAPIHandle()))
            return
        }

        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: modelType,
                                                                nextToken: nextToken,
                                                                lastSync: lastSyncTime)

        _ = api.query(request: request) { asyncEvent in
            switch asyncEvent {
            case .failed(let apiError):
                // TODO: Retry query on error
                self.finish(result: .failure(DataStoreError.api(apiError)))
            case .completed(let graphQLResult):
                self.handleQueryResults(graphQLResult: graphQLResult)
            default:
                break
            }
        }
    }

    /// Disposes of the query results: Stops if error, reconciles results if success, and kick off a new query if there
    /// is a next token
    private func handleQueryResults(graphQLResult: Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>>) {
        guard !isCancelled else {
            super.finish()
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
        lastSyncTime = syncQueryResult.startedAt

        for item in items {
            reconciliationQueue.offer(item)
        }

        if let nextToken = syncQueryResult.nextToken {
            DispatchQueue.global().async {
                self.query(nextToken: nextToken)
            }
        } else {
            updateModelSyncMetadata()
        }

    }

    private func updateModelSyncMetadata() {
        guard !isCancelled else {
            super.finish()
            return
        }

        guard let storageAdapter = storageAdapter else {
            finish(result: .failure(DataStoreError.nilStorageAdapter()))
            return
        }

        let syncMetadata = ModelSyncMetadata(id: modelType.modelName, lastSync: lastSyncTime)
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
        completion(result)
        super.finish()
    }

}

@available(iOS 13.0, *)
extension InitialSyncOperation: DefaultLogger { }
