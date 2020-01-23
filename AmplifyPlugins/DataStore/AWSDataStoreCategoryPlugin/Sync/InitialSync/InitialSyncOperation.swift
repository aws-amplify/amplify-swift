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

    private let modelType: Model.Type
    private let completion: AWSInitialSyncOrchestrator.SyncOperationResultHandler

    private var lastSyncTime: Int?

    init(modelType: Model.Type,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?,
         completion: @escaping AWSInitialSyncOrchestrator.SyncOperationResultHandler) {
        self.modelType = modelType
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter
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
        lastSyncTime = lastSyncMetadata?.lastSync
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

        let document = GraphQLSyncQuery(from: modelType,
                                        nextToken: nextToken,
                                        lastSync: lastSyncTime)

        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: SyncQueryResult.self,
                                     decodePath: document.decodePath)

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
        storageAdapter.save(syncMetadata) { result in
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
