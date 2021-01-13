//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

extension StorageEngine {
    func queryAndDeleteTransaction<M: Model>(_ modelType: M.Type,
                                             modelSchema: ModelSchema,
                                             predicate: QueryPredicate) -> DataStoreResult<[M]> {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            if case .success = queryResult {
                let deleteCompletionWrapper: DataStoreCallback<[M]> = { deleteResult in
                    deletedResult = deleteResult
                }
                self.storageAdapter.delete(modelType,
                                           modelSchema: modelSchema,
                                           predicate: predicate,
                                           completion: deleteCompletionWrapper)
            }
        }

        do {
            try storageAdapter.transaction {
                storageAdapter.query(modelType,
                                     modelSchema: modelSchema,
                                     predicate: predicate,
                                     sort: nil,
                                     paginationInput: nil,
                                     completion: queryCompletionBlock)
            }
        } catch {
            return .failure(causedBy: error)
        }

        return collapseResults(queryResult: queriedResult, deleteResult: deletedResult)
    }

    func collapseResults<M: Model>(queryResult: DataStoreResult<[M]>?,
                                   deleteResult: DataStoreResult<[M]>?) -> DataStoreResult<[M]> {
        if let queryResult = queryResult {
            switch queryResult {
            case .success(let models):
                if let deleteResult = deleteResult {
                    switch deleteResult {
                    case .success:
                        return .success(models)
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    return .failure(.unknown("deleteResult not set during transaction", "coding error", nil))
                }
            case .failure(let error):
                return .failure(error)
            }
        } else {
            return .failure(.unknown("queryResult not set during transaction", "coding error", nil))
        }
    }
}
