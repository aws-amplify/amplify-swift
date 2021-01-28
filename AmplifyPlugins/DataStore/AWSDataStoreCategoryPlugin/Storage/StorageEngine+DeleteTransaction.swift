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

    enum DeleteInput {
        case withId(id: Model.Identifier)
        case withIdAndPredicate(id: Model.Identifier, predicate: QueryPredicate)
        case withPredicate(predicate: QueryPredicate)

        /// Returns a computed predicate based on the type of delete scenario it is.
        var predicate: QueryPredicate {
            switch self {
            case .withId(let id):
                return field("id").eq(id)
            case .withIdAndPredicate(let id, let predicate):
                return field("id").eq(id).and(predicate)
            case .withPredicate(let predicate):
                return predicate
            }
        }
    }

    func queryAndDeleteTransaction<M: Model>(_ modelType: M.Type,
                                             modelSchema: ModelSchema,
                                             deleteInput: DeleteInput) -> DataStoreResult<([M], [Model])> {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?
        var associatedModels: [Model] = []

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            guard case .success(let queriedModels) = queryResult else {
                return
            }

            guard !queriedModels.isEmpty else {
                guard case .withIdAndPredicate(let id, _) = deleteInput else {
                    // Query did not return any results, treat this as a successful no-op delete.
                    deletedResult = .success([M]())
                    return
                }

                // Query using the computed predicate did not return any results, check if model actually exists.
                do {
                    if try self.storageAdapter.exists(modelSchema, withId: id, predicate: nil) {
                        queriedResult = .failure(
                            DataStoreError.invalidCondition(
                                "Delete failed due to condition did not match existing model instance.",
                                "Subsequent deletes will continue to fail until the model instance is updated."))
                    } else {
                        deletedResult = .success([M]())
                    }
                } catch {
                    queriedResult = .failure(DataStoreError.invalidOperation(causedBy: error))
                }

                return
            }

            let modelIds = queriedModels.map {$0.id}
            associatedModels = self.recurseQueryAssociatedModels(modelSchema: modelSchema, ids: modelIds)
            let deleteCompletionWrapper: DataStoreCallback<[M]> = { deleteResult in
                deletedResult = deleteResult
            }
            self.storageAdapter.delete(modelType,
                                       modelSchema: modelSchema,
                                       predicate: deleteInput.predicate,
                                       completion: deleteCompletionWrapper)
        }

        do {
            try storageAdapter.transaction {
                storageAdapter.query(modelType,
                                     modelSchema: modelSchema,
                                     predicate: deleteInput.predicate,
                                     sort: nil,
                                     paginationInput: nil,
                                     completion: queryCompletionBlock)
            }
        } catch {
            return .failure(causedBy: error)
        }

        return collapseResults(queryResult: queriedResult,
                               deleteResult: deletedResult,
                               associatedModels: associatedModels)
    }

    func recurseQueryAssociatedModels(modelSchema: ModelSchema, ids: [Model.Identifier]) -> [Model] {
        var associatedModels: [Model] = []
        for (_, modelField) in modelSchema.fields {
            guard modelField.hasAssociation,
                modelField.isOneToOne || modelField.isOneToMany,
                let associatedModelName = modelField.associatedModelName,
                let associatedField = modelField.associatedField,
                let associatedModelSchema = ModelRegistry.modelSchema(from: associatedModelName) else {
                    continue
            }
            let queriedModels = queryAssociatedModels(modelName: associatedModelName,
                                                      associatedField: associatedField,
                                                      ids: ids)
            let associatedModelIds = queriedModels.map {$0.id}
            associatedModels.append(contentsOf: queriedModels)
            associatedModels.append(contentsOf: recurseQueryAssociatedModels(modelSchema: associatedModelSchema, ids: associatedModelIds))
        }
        return associatedModels
    }

    func queryAssociatedModels(modelName: ModelName, associatedField: ModelField, ids: [Model.Identifier]) -> [Model] {
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            log.error("Failed to lookup \(modelName)")
            return []
        }

        // SQLite supports up to 1000 expressions per SQLStatement. We have chosen to use 50 expressions
        // less (equaling 950) than the maximum because it is possible that our SQLStatement already has
        // some expressions.  If we encounter performance problems in the future, we will want to profile
        // our system and find an optimal value.
        let maxNumberOfPredicates = 950
        var queriedModels: [Model] = []
        let chunkedArrays = ids.chunked(into: maxNumberOfPredicates)
        for chunkedArray in chunkedArrays {
            // TODO: Add conveinence to queryPredicate where we have a list of items, to be all or'ed
            var queryPredicates: [QueryPredicateOperation] = []
            for id in chunkedArray {
                queryPredicates.append(QueryPredicateOperation(field: associatedField.name, operator: .equals(id)))
            }
            let groupedQueryPredicates =  QueryPredicateGroup(type: .or, predicates: queryPredicates)

            let sempahore = DispatchSemaphore(value: 0)
            storageAdapter.query(untypedModel: modelType, predicate: groupedQueryPredicates) { result in
                defer {
                    sempahore.signal()
                }
                switch result {
                case .success(let models):
                    queriedModels.append(contentsOf: models)

                case .failure(let error):
                    log.error("Failed to query \(modelType) on mutation event generation: \(error)")
                }
            }
            sempahore.wait()
        }
        return queriedModels
    }

    private func collapseResults<M: Model>(queryResult: DataStoreResult<[M]>?,
                                           deleteResult: DataStoreResult<[M]>?,
                                           associatedModels: [Model]) -> DataStoreResult<([M], [Model])> {
        if let queryResult = queryResult {
            switch queryResult {
            case .success(let models):
                if let deleteResult = deleteResult {
                    switch deleteResult {
                    case .success:
                        return .success((models, associatedModels))
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

    func collapseMResult<M: Model>(_ result: DataStoreResult<([M], [Model])>) -> DataStoreResult<[M]> {
        switch result {
        case .success(let results):
            return .success(results.0)
        case .failure(let error):
            return .failure(error)
        }
    }

    func resolveAssociatedModels<M: Model>(_ result: DataStoreResult<([M], [Model])>) -> [Model] {
        switch result {
        case .success(let results):
            return results.1
        case .failure:
            return []
        }
    }
}
