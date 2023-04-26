//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Dispatch

extension MutationEvent {
    static func pendingMutationEvents(
        forModel model: Model,
        storageAdapter: StorageEngineAdapter
    ) -> Swift.Result<[MutationEvent], DataStoreError> {
        pendingMutationEvents(
            forModels: [model],
            storageAdapter: storageAdapter
        )
    }

    static func pendingMutationEvents(
        forMutationEvent mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) -> Swift.Result<[MutationEvent], DataStoreError> {
        pendingMutationEvents(
            forMutationEvents: [mutationEvent],
            storageAdapter: storageAdapter
        )
    }

    static func pendingMutationEvents(
        forMutationEvents mutationEvents: [MutationEvent],
        storageAdapter: StorageEngineAdapter
    ) -> Swift.Result<[MutationEvent], DataStoreError> {
        pendingMutationEvents(
            for: mutationEvents.map { ($0.modelId, $0.modelName) },
            storageAdapter: storageAdapter
        )
    }

    static func pendingMutationEvents(
        forModels models: [Model],
        storageAdapter: StorageEngineAdapter
    ) -> Swift.Result<[MutationEvent], DataStoreError> {
        pendingMutationEvents(
            for: models.map { ($0.identifier, $0.modelName) },
            storageAdapter: storageAdapter
        )
    }

    private static func pendingMutationEvents(
        for modelIds: [(String, String)],
        storageAdapter: StorageEngineAdapter
    ) -> Swift.Result<[MutationEvent], DataStoreError> {
        let chunkedArrays = modelIds.chunked(into: SQLiteStorageEngineAdapter.maxNumberOfPredicates)
        return chunkedArrays.reduce(.success([])) { partialResult, chunedArray in
            partialResult.flatMap { queriedMutationEvents in
                getMutationEvents(of: chunedArray, storageAdapter: storageAdapter).map { mutationEvents in
                    queriedMutationEvents + mutationEvents
                }
            }
        }
    }

    private static func getMutationEvents(
        of identifiers: [(String, String)],
        storageAdapter: StorageEngineAdapter
    ) -> Result<[MutationEvent], DataStoreError> {
        let fields = MutationEvent.keys
        let predicate = (fields.inProcess == false || fields.inProcess == nil)
        let queryPredicates = identifiers.reduce([]) { partialResult, identifier in
            partialResult + [fields.modelId == identifier.0 && fields.modelName == identifier.1]
        }
        let groupedQueryPredicates =  QueryPredicateGroup(type: .or, predicates: queryPredicates)
        let final = QueryPredicateGroup(type: .and, predicates: [groupedQueryPredicates, predicate])
        let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)

        return storageAdapter.query(
            MutationEvent.self,
            modelSchema: MutationEvent.schema,
            condition: final,
            sort: [sort],
            paginationInput: nil,
            eagerLoad: true
        )
    }
}
