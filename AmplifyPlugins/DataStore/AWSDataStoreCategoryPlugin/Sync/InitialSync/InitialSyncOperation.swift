//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

@available(iOS 13.0, *)
final class InitialSyncOperation: Operation {
    typealias SyncQueryResult = PaginatedList<AnyModel>

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?

    private let modelType: Model.Type
    private let completion: AWSInitialSyncOrchestrator.SyncOperationResultHandler

    private var lastSyncTime: Int?

    private var isCompleted: DispatchSemaphore

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

        self.isCompleted = DispatchSemaphore(value: 1)
    }

    override func main() {
        log.info("Beginning sync for \(modelType.modelName)")

        let lastSyncMetadata = getLastSyncMetadata()
        lastSyncTime = lastSyncMetadata?.lastSync

        DispatchQueue.global().async {
            self.query()
        }
        isCompleted.wait()
    }

    private func getLastSyncMetadata() -> ModelSyncMetadata? {
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

    // MARK: - Async processes

    // This section marks the asynchronous processing part of the operation. Each exit condition of this proces must
    // call `finish` when exiting, to signal the semaphore and allow the overally operation to complete

    private func query(nextToken: String? = nil) {
        guard let api = api else {
            finish(result: .failure(DataStoreError.nilAPIHandle()))
            return
        }

        let document = GraphQLSyncQuery(from: modelType,
                                        nextToken: nextToken,
                                        lastSync: lastSyncTime)

        let request = GraphQLRequest(document: document.stringValue,
                                     responseType: SyncQueryResult.self)

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
        guard let reconciliationQueue = reconciliationQueue else {
            finish(result: .failure(DataStoreError.nilReconciliationQueues()))
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
        for item in items {
            reconciliationQueue.offer(item)
        }

        if let nextToken = syncQueryResult.nextToken {
            DispatchQueue.global().async {
                self.query(nextToken: nextToken)
            }
        } else {
            finish(result: Result.successful)
        }

    }

    private func finish(result: AWSInitialSyncOrchestrator.SyncOperationResult) {
        completion(result)
        isCompleted.signal()
    }

}

extension Result where Success == Void {
    static var successful: Result<Void, Failure> { .success(()) }
}

@available(iOS 13.0, *)
extension InitialSyncOperation: DefaultLogger { }
