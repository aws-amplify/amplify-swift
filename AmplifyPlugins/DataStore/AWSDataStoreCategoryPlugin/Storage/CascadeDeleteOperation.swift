//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import Combine

/// CascadeDeleteOperation has the following logic:
/// 1. Query models from local store based on the following use cases:
///    1a. If the use case is Delete with id, then query by `id`
///    1b. or Delete with id and condition, then query by `id` and `condition`.
///        If the model given the condition does not exist, check if the model exists.
///        if the model exists, then fail with `DataStoreError.invalidCondition`.
///    1c. or Delete with filter, then query by `filter`.
/// 2. If there are at least one item to delete, query for all its associated models recursively.
/// 3. Delete the original queried items from local store. This performs a cascade delete by default (See
///   **CreateTableStatement** for more details, `on delete cascade` when creating the SQL table enables this behavior).
/// 4. If sync is enabled, then submit the delete mutations to the sync engine,
///   in the order of children to parent models.
public class CascadeDeleteOperation<M: Model>: AsynchronousOperation { // swiftlint:disable:this type_body_length
    let storageAdapter: StorageEngineAdapter
    var syncEngine: RemoteSyncEngineBehavior?
    let modelType: M.Type
    let modelSchema: ModelSchema
    let deleteInput: DeleteInput
    let completionForWithId: ((DataStoreResult<M?>) -> Void)?
    let completionForWithFilter: ((DataStoreResult<[M]>) -> Void)?

    private let serialQueueSyncDeletions: DispatchQueue

    init(storageAdapter: StorageEngineAdapter,
         syncEngine: RemoteSyncEngineBehavior?,
         modelType: M.Type,
         modelSchema: ModelSchema,
         withIdentifier identifier: ModelIdentifierProtocol,
         condition: QueryPredicate? = nil,
         completion: @escaping (DataStoreResult<M?>) -> Void) {
        self.storageAdapter = storageAdapter
        self.syncEngine = syncEngine
        self.modelType = modelType
        self.modelSchema = modelSchema
        var deleteInput = DeleteInput.withIdentifier(id: identifier)
        if let condition = condition {
            deleteInput = .withIdentifierAndCondition(id: identifier,
                                                      condition: condition)
        }
        self.deleteInput = deleteInput
        self.completionForWithId = completion
        self.completionForWithFilter = nil
        self.serialQueueSyncDeletions = DispatchQueue(label: "com.amazoncom.Storage.CascadeDeleteOperation.concurrency")
        super.init()
    }

    init(storageAdapter: StorageEngineAdapter,
         syncEngine: RemoteSyncEngineBehavior?,
         modelType: M.Type,
         modelSchema: ModelSchema,
         filter: QueryPredicate,
         completion: @escaping (DataStoreResult<[M]>) -> Void) {
        self.storageAdapter = storageAdapter
        self.syncEngine = syncEngine
        self.modelType = modelType
        self.modelSchema = modelSchema
        self.deleteInput = .withFilter(filter)
        self.completionForWithId = nil
        self.completionForWithFilter = completion
        self.serialQueueSyncDeletions = DispatchQueue(label: "com.amazoncom.Storage.CascadeDeleteOperation.concurrency")
        super.init()
    }

    override public func main() {
        let transactionResult = queryAndDeleteTransaction()
        syncIfNeededAndFinish(transactionResult)
    }

    struct QueryAndDeleteResult<M: Model> {
        let deletedModels: [M]
        let associatedModels: [(ModelName, Model)]
    }

    func queryAndDeleteTransaction() -> DataStoreResult<QueryAndDeleteResult<M>> {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?
        var associatedModels: [(ModelName, Model)] = []

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            guard case .success(let queriedModels) = queryResult else {
                return
            }

            guard !queriedModels.isEmpty else {
                guard case .withIdentifierAndCondition(let identifier, _) = self.deleteInput else {
                    // Query did not return any results, treat this as a successful no-op delete.
                    deletedResult = .success([M]())
                    return
                }

                // Query using the computed predicate did not return any results, check if model actually exists.
                do {
                    if try self.storageAdapter.exists(self.modelSchema, withIdentifier: identifier, predicate: nil) {
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

            let modelIds = queriedModels.map { $0.identifier(schema: self.modelSchema).stringValue }
            associatedModels = self.recurseQueryAssociatedModels(modelSchema: self.modelSchema, ids: modelIds)
            let deleteCompletionWrapper: DataStoreCallback<[M]> = { deleteResult in
                deletedResult = deleteResult
            }
            self.storageAdapter.delete(self.modelType,
                                       modelSchema: self.modelSchema,
                                       filter: self.deleteInput.predicate,
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

    func recurseQueryAssociatedModels(modelSchema: ModelSchema, ids: [String]) -> [(ModelName, Model)] {
        var associatedModels: [(ModelName, Model)] = []
        for (_, modelField) in modelSchema.fields {
            guard modelField.hasAssociation,
                modelField.isOneToOne || modelField.isOneToMany,
                let associatedModelName = modelField.associatedModelName,
                let associatedField = modelField.associatedField,
                let associatedModelSchema = ModelRegistry.modelSchema(from: associatedModelName) else {
                    continue
            }

            guard let modelSchema = ModelRegistry.modelSchema(from: associatedModelName) else {
                log.error("Failed to lookup associate model \(associatedModelName)")
                return []
            }

            let queriedModels = queryAssociatedModels(associatedModelSchema: modelSchema,
                                                      associatedField: associatedField,
                                                      ids: ids)
            let associatedModelIds = queriedModels.map { $0.1.identifier(schema: modelSchema).stringValue }
            associatedModels.append(contentsOf: queriedModels)
            associatedModels.append(contentsOf: recurseQueryAssociatedModels(modelSchema: associatedModelSchema,
                                                                            ids: associatedModelIds))
        }
        return associatedModels
    }

    func queryAssociatedModels(associatedModelSchema modelSchema: ModelSchema,
                               associatedField: ModelField,
                               ids: [String]) -> [(ModelName, Model)] {
        var queriedModels: [(ModelName, Model)] = []
        let chunkedArrays = ids.chunked(into: SQLiteStorageEngineAdapter.maxNumberOfPredicates)
        for chunkedArray in chunkedArrays {
            // swiftlint:disable:next todo
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
                        (modelSchema.name, model)
                    })
                case .failure(let error):
                    log.error("Failed to query \(modelSchema) on mutation event generation: \(error)")
                }
            }
            sempahore.wait()
        }
        return queriedModels
    }

    private func collapseResults<M: Model>(queryResult: DataStoreResult<[M]>?,
                                           deleteResult: DataStoreResult<[M]>?,
                                           associatedModels: [(ModelName, Model)]) -> DataStoreResult<QueryAndDeleteResult<M>> {
        // swiftlint:disable:previous line_length
        if let queryResult = queryResult {
            switch queryResult {
            case .success(let models):
                if let deleteResult = deleteResult {
                    switch deleteResult {
                    case .success:
                        return .success(QueryAndDeleteResult(deletedModels: models,
                                                             associatedModels: associatedModels))
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

    // swiftlint:disable:next cyclomatic_complexity
    func syncIfNeededAndFinish(_ transactionResult: DataStoreResult<QueryAndDeleteResult<M>>) {
        switch transactionResult {
        case .success(let queryAndDeleteResult):
            switch deleteInput {
            case .withIdentifier, .withIdentifierAndCondition:
                guard queryAndDeleteResult.deletedModels.count <= 1 else {
                    completionForWithId?(.failure(.unknown("delete with id returned more than one result", "", nil)))
                    finish()
                    return
                }

                guard queryAndDeleteResult.deletedModels.first != nil else {
                    completionForWithId?(.success(nil))
                    finish()
                    return
                }
            case .withFilter:
                guard !queryAndDeleteResult.deletedModels.isEmpty else {
                    completionForWithFilter?(.success(queryAndDeleteResult.deletedModels))
                    finish()
                    return
                }
            }

            guard modelSchema.isSyncable, let syncEngine = self.syncEngine else {
                if !modelSchema.isSystem {
                    log.error("Unable to sync model (\(modelSchema.name)) where isSyncable is false")
                }
                if self.syncEngine == nil {
                    log.error("Unable to sync because syncEngine is nil")
                }
                completionForWithId?(.success(queryAndDeleteResult.deletedModels.first))
                completionForWithFilter?(.success(queryAndDeleteResult.deletedModels))
                finish()
                return
            }

            guard #available(iOS 13.0, *) else {
                completionForWithId?(.success(queryAndDeleteResult.deletedModels.first))
                completionForWithFilter?(.success(queryAndDeleteResult.deletedModels))
                finish()
                return
            }

            // swiftlint:disable:next todo
            // TODO: This requires follow up.
            // In the current code, when deleting a single model instance conditionally, the `condition` predicate is
            // first applied locally to determine whether the item should be deleted or not. If met, the local item is
            // deleted. When syncing this deleted model with the delete mutation event, the `condition` is not passed
            // to the delete mutation. Should it be passed to the delete mutation as well?
            //
            // When deleting all models that match the `filter` predicate, the `filter` is passed to the
            // delete mutation event. Since the item was originally retrieved using the filter as a way to narrow
            // down which items should be deleted, then does it still need to be passed as the "condition" for the
            // delete mutation if it will always be met? (Perhaps, this is needed as a way to guard against updates
            // that move the model out of the filtered results). Should we stop passing the `filter` to the delete
            // mutation?
            switch deleteInput {
            case .withIdentifier, .withIdentifierAndCondition:
                syncDeletions(withModels: queryAndDeleteResult.deletedModels,
                              associatedModels: queryAndDeleteResult.associatedModels,
                              syncEngine: syncEngine) {
                    switch $0 {
                    case .success:
                        self.completionForWithId?(.success(queryAndDeleteResult.deletedModels.first))
                    case .failure(let error):
                        self.completionForWithId?(.failure(error))
                    }
                    self.finish()
                }
            case .withFilter(let filter):
                syncDeletions(withModels: queryAndDeleteResult.deletedModels,
                              predicate: filter,
                              associatedModels: queryAndDeleteResult.associatedModels,
                              syncEngine: syncEngine) {
                    switch $0 {
                    case .success:
                        self.completionForWithFilter?(.success(queryAndDeleteResult.deletedModels))
                    case .failure(let error):
                        self.completionForWithFilter?(.failure(error))
                    }
                    self.finish()
                }
            }

        case .failure(let error):
            completionForWithId?(.failure(error))
            completionForWithFilter?(.failure(error))
            finish()
        }
    }

    // `syncDeletions` will first sync all associated models in reversed order so the lowest level of children models
    // are synced first, before the its parent models. See `recurseQueryAssociatedModels()` for more details on the
    // ordering of the results in `associatedModels`. Once all the associated models are synced, sync the `models`,
    // finishing the sequence of deletions from children to parent.
    //
    // For example, A has-many B and C, B has-many D, D has-many E. The query will result in associatedModels with
    // the order [B, D, E, C]. Sync deletions will be performed the back to the front from C, E, D, B, then finally the
    // parent models A.
    //
    // `.reversed()` will not allocate new space for its elements (what we want) by wrapping the underlying
    // collection and provide access in reverse order.
    // For more details: https://developer.apple.com/documentation/swift/array/1690025-reversed
    @available(iOS 13.0, *)
    private func syncDeletions(withModels models: [M],
                               predicate: QueryPredicate? = nil,
                               associatedModels: [(ModelName, Model)],
                               syncEngine: RemoteSyncEngineBehavior,
                               completion: @escaping DataStoreCallback<Void>) {
        var savedDataStoreError: DataStoreError?

        guard !associatedModels.isEmpty else {
            syncDeletions(withModels: models,
                          predicate: predicate,
                          syncEngine: syncEngine,
                          dataStoreError: savedDataStoreError,
                          completion: completion)
            return
        }

        var mutationEventsSubmitCompleted = 0
        for (modelName, associatedModel) in associatedModels.reversed() {
            let mutationEvent: MutationEvent
            do {
                mutationEvent = try MutationEvent(untypedModel: associatedModel,
                                                  modelName: modelName,
                                                  mutationType: .delete)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }

            let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
                self.serialQueueSyncDeletions.async {
                    mutationEventsSubmitCompleted += 1
                    switch result {
                    case .failure(let dataStoreError):
                        self.log.error("\(#function) failed to submit to sync engine \(mutationEvent)")
                        if savedDataStoreError == nil {
                            savedDataStoreError = dataStoreError
                        }
                    case .success(let mutationEvent):
                        self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                    }

                    if mutationEventsSubmitCompleted == associatedModels.count {
                        self.syncDeletions(withModels: models,
                                           predicate: predicate,
                                           syncEngine: syncEngine,
                                           dataStoreError: savedDataStoreError,
                                           completion: completion)
                    }
                }
            }
            submitToSyncEngine(mutationEvent: mutationEvent,
                               syncEngine: syncEngine,
                               completion: mutationEventCallback)

        }
    }
    @available(iOS 13.0, *)
    private func syncDeletions(withModels models: [M],
                               predicate: QueryPredicate? = nil,
                               syncEngine: RemoteSyncEngineBehavior,
                               dataStoreError: DataStoreError?,
                               completion: @escaping DataStoreCallback<Void>) {
        var graphQLFilterJSON: String?
        if let predicate = predicate {
            do {
                graphQLFilterJSON = try GraphQLFilterConverter.toJSON(predicate,
                                                                      modelSchema: modelSchema)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }
        }
        var mutationEventsSubmitCompleted = 0
        var savedDataStoreError = dataStoreError
        for model in models {
            let mutationEvent: MutationEvent
            do {
                mutationEvent = try MutationEvent(model: model,
                                                  modelSchema: modelSchema,
                                                  mutationType: .delete,
                                                  graphQLFilterJSON: graphQLFilterJSON)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }

            let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
                self.serialQueueSyncDeletions.async {
                    mutationEventsSubmitCompleted += 1
                    switch result {
                    case .failure(let dataStoreError):
                        self.log.error("\(#function) failed to submit to sync engine \(mutationEvent)")
                        if savedDataStoreError == nil {
                            savedDataStoreError = dataStoreError
                        }
                    case .success:
                        self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                    }
                    if mutationEventsSubmitCompleted == models.count {
                        if let lastEmittedDataStoreError = savedDataStoreError {
                            completion(.failure(lastEmittedDataStoreError))
                        } else {
                            completion(.successfulVoid)
                        }
                    }
                }
            }

            submitToSyncEngine(mutationEvent: mutationEvent,
                               syncEngine: syncEngine,
                               completion: mutationEventCallback)
        }
    }

    @available(iOS 13.0, *)
    private func submitToSyncEngine(mutationEvent: MutationEvent,
                                    syncEngine: RemoteSyncEngineBehavior,
                                    completion: @escaping DataStoreCallback<MutationEvent>) {
        var mutationQueueSink: AnyCancellable?
        mutationQueueSink = syncEngine
            .submit(mutationEvent)
            .sink(
                receiveCompletion: { futureCompletion in
                    switch futureCompletion {
                    case .failure(let error):
                        completion(.failure(causedBy: error))
                    case .finished:
                        self.log.verbose("\(#function) Received successful completion")
                    }
                    mutationQueueSink?.cancel()
                    mutationQueueSink = nil
                }, receiveValue: { mutationEvent in
                    self.log.verbose("\(#function) saved mutation event: \(mutationEvent)")
                    completion(.success(mutationEvent))
                })
    }
}

// MARK: - CascadeDeleteOperation.DeleteInput
extension CascadeDeleteOperation {
    enum DeleteInput {
        case withIdentifier(id: ModelIdentifierProtocol)
        case withIdentifierAndCondition(id: ModelIdentifierProtocol, condition: QueryPredicate)
        case withFilter(_ filter: QueryPredicate)

        /// Returns a computed predicate based on the type of delete scenario it is.
        var predicate: QueryPredicate {
            switch self {
            case .withIdentifier(let identifier):
                return identifier.predicate
            case .withIdentifierAndCondition(let identifier, let predicate):
                return QueryPredicateGroup(type: .and,
                                           predicates: [identifier.predicate,
                                                        predicate])
            case .withFilter(let predicate):
                return predicate
            }
        }
    }
}

extension CascadeDeleteOperation: DefaultLogger { } // swiftlint:disable:this file_length