//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
                                             predicate: QueryPredicate) -> DataStoreResult<([M], [Model])> {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?
        var associatedModels: [Model] = []

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            if case .success(let queriedModels) = queryResult {
                let modelIds = queriedModels.map {$0.id}
                associatedModels = self.recurseQueryAssociatedModels(modelSchema: modelSchema, ids: modelIds)

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

        return collapseResults(queryResult: queriedResult, deleteResult: deletedResult, associatedModels: associatedModels)
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
            let queriedModels = queryAssociatedModels(modelName: associatedModelName, associatedField: associatedField, ids: ids)
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

        //TODO: Add conveinence to queryPredicate where we have a list of items, to be all or'ed
        var queryPredicates: [QueryPredicateOperation] = []
        for id in ids {
            queryPredicates.append(QueryPredicateOperation(field: associatedField.name, operator: .equals(id)))
        }
        let groupedQueryPredicates =  QueryPredicateGroup(type: .or, predicates: queryPredicates)

        var queriedModels: [Model] = []
        let sempahore = DispatchSemaphore(value: 0)
        storageAdapter.query(untypedModel: modelType, predicate: groupedQueryPredicates) { result in
            switch result {
            case .success(let models):
                queriedModels.append(contentsOf: models)

            case .failure(let error):
                log.error("Failed to query \(modelType) on mutation event generation: \(error)")
            }
            sempahore.signal()
        }
        sempahore.wait()
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

    func generateMutationsFromModels(models: [Model]) -> [MutationEvent] {
        var mutationEvents: [MutationEvent] = []
        for model in models {
            do {
                let mutationEvent = try MutationEvent(untypedModel: model, mutationType: .delete)
                mutationEvents.append(mutationEvent)
            } catch {
                log.error("Failed to generate mutation event. \(model.modelName), \(model.id)")
            }
        }
        return mutationEvents
    }

}
