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
        case withIdentifier(id: ModelIdentifierProtocol)
        case withIdentifierAndPredicate(id: ModelIdentifierProtocol, predicate: QueryPredicate)
        case withPredicate(predicate: QueryPredicate)

        /// Returns a computed predicate based on the type of delete scenario it is.
        var predicate: QueryPredicate {
            switch self {
            case .withIdentifier(let identifier):
                return identifier.predicate
            case .withIdentifierAndPredicate(let identifier, let predicate):
                return QueryPredicateGroup(type: .and,
                                           predicates: [identifier.predicate,
                                                        predicate])
            case .withPredicate(let predicate):
                return predicate
            }
        }
    }

    func queryAndDeleteTransaction<M: Model>(_ modelType: M.Type,
                                             modelSchema: ModelSchema,
                                             deleteInput: DeleteInput) -> DataStoreResult<([M], [ModelName: [Model]])> {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?
        var associatedModels: [(ModelName, Model)] = []

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            guard case .success(let queriedModels) = queryResult else {
                return
            }

            guard !queriedModels.isEmpty else {
                guard case .withIdentifierAndPredicate(let identifier, _) = deleteInput else {
                    // Query did not return any results, treat this as a successful no-op delete.
                    deletedResult = .success([M]())
                    return
                }

                // Query using the computed predicate did not return any results, check if model actually exists.
                do {
                    if try self.storageAdapter.exists(modelSchema, withIdentifier: identifier, predicate: nil) {
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

            // TODO CPK: verify that is correct
            let modelIds = queriedModels.map { $0.identifier(schema: modelSchema).stringValue }
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
                               associatedModelsMap: getAssociatedModelsMap(associatedModels: associatedModels))
    }

    func recurseQueryAssociatedModels(modelSchema: ModelSchema, ids: [Model.Identifier]) -> [(ModelName, Model)] {
        var associatedModels: [(ModelName, Model)] = []
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
            let associatedModelIds = queriedModels.map { $0.1.identifier(schema: modelSchema).stringValue }
            associatedModels.append(contentsOf: queriedModels)
            associatedModels.append(contentsOf: recurseQueryAssociatedModels(modelSchema: associatedModelSchema,
                                                                            ids: associatedModelIds))
        }
        return associatedModels
    }

    func queryAssociatedModels(modelName: ModelName,
                               associatedField: ModelField,
                               ids: [Model.Identifier]) -> [(ModelName, Model)] {
        guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
            log.error("Failed to lookup \(modelName)")
            return []
        }

        var queriedModels: [(ModelName, Model)] = []
        let chunkedArrays = ids.chunked(into: SQLiteStorageEngineAdapter.maxNumberOfPredicates)
        for chunkedArray in chunkedArrays {
            // TODO: Add conveinence to queryPredicate where we have a list of items, to be all or'ed
            var queryPredicates: [QueryPredicateOperation] = []
            for id in chunkedArray {
                queryPredicates.append(QueryPredicateOperation(field: associatedField.name, operator: .equals(id)))
            }
            let groupedQueryPredicates = QueryPredicateGroup(type: .or, predicates: queryPredicates)

            let sempahore = DispatchSemaphore(value: 0)
            storageAdapter.query(modelSchema: modelSchema, predicate: groupedQueryPredicates) { result in
                defer {
                    sempahore.signal()
                }
                switch result {
                case .success(let models):
                    queriedModels.append(contentsOf: models.map { model in
                        (modelName, model)
                    })
                case .failure(let error):
                    log.error("Failed to query \(modelSchema) on mutation event generation: \(error)")
                }
            }
            sempahore.wait()
        }
        return queriedModels
    }

    private func getAssociatedModelsMap(associatedModels: [(ModelName, Model)]) -> [ModelName: [Model]] {
        var associatedModelsMap = [ModelName: [Model]]()
        for (modelName, model) in associatedModels {
            associatedModelsMap[modelName, default: []].append(model)
        }
        return associatedModelsMap
    }

    private func collapseResults<M: Model>(queryResult: DataStoreResult<[M]>?,
                                           deleteResult: DataStoreResult<[M]>?,
                                           associatedModelsMap: [ModelName: [Model]]) -> DataStoreResult<([M], [ModelName: [Model]])> {
        if let queryResult = queryResult {
            switch queryResult {
            case .success(let models):
                if let deleteResult = deleteResult {
                    switch deleteResult {
                    case .success:
                        return .success((models, associatedModelsMap))
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

    func collapseMResult<M: Model>(_ result: DataStoreResult<([M], [ModelName: [Model]])>) -> DataStoreResult<[M]> {
        switch result {
        case .success(let results):
            return .success(results.0)
        case .failure(let error):
            return .failure(error)
        }
    }

    func resolveAssociatedModels<M: Model>(
        _ result: DataStoreResult<([M], [ModelName: [Model]])>) -> [ModelName: [Model]] {
        switch result {
        case .success(let results):
            return results.1
        case .failure:
            return [:]
        }
    }
}
