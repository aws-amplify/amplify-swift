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
        storageAdapter: StorageEngineAdapter,
        completion: DataStoreCallback<[MutationEvent]>
    ) {
        pendingMutationEvents(
            forModels: [model],
            storageAdapter: storageAdapter,
            completion: completion
        )
    }

    static func pendingMutationEvents(
        forModels models: [Model],
        storageAdapter: StorageEngineAdapter,
        completion: DataStoreCallback<[MutationEvent]>
    ) {
        pendingMutationEvents(
            for: models.map { ($0.identifier, $0.modelName) },
            storageAdapter: storageAdapter,
            completion: completion
        )
    }

    static func pendingMutationEvents(
        forMutationEvent mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter,
        completion: DataStoreCallback<[MutationEvent]>
    ) {
        pendingMutationEvents(
            forMutationEvents: [mutationEvent],
            storageAdapter: storageAdapter,
            completion: completion
        )
    }

    static func pendingMutationEvents(
        forMutationEvents mutationEvents: [MutationEvent],
        storageAdapter: StorageEngineAdapter,
        completion: DataStoreCallback<[MutationEvent]>
    ) {
        pendingMutationEvents(
            for: mutationEvents.map { ($0.modelId, $0.modelName) },
            storageAdapter: storageAdapter,
            completion: completion
        )
    }

    private static func pendingMutationEvents(
        for modelIds: [(String, String)],
        storageAdapter: StorageEngineAdapter,
        completion: DataStoreCallback<[MutationEvent]>
    ) {
        let fields = MutationEvent.keys
        let predicate = (fields.inProcess == false || fields.inProcess == nil)
        var queriedMutationEvents: [MutationEvent] = []
        var queryError: DataStoreError?
        let chunkedArrays = modelIds.chunked(into: SQLiteStorageEngineAdapter.maxNumberOfPredicates)
        for chunkedArray in chunkedArrays {
            var queryPredicates: [QueryPredicateGroup] = []
            for (id, name) in chunkedArray {
                let opration = fields.modelId == id && fields.modelName == name
                queryPredicates.append(opration)
            }
            let groupedQueryPredicates =  QueryPredicateGroup(type: .or, predicates: queryPredicates)
            let final = QueryPredicateGroup(type: .and, predicates: [groupedQueryPredicates, predicate])
            let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)
            let sempahore = DispatchSemaphore(value: 0)
            storageAdapter.query(MutationEvent.self,
                                 predicate: final,
                                 sort: [sort],
                                 paginationInput: nil) { result in
                defer {
                    sempahore.signal()
                }

                switch result {
                case .success(let mutationEvents):
                    queriedMutationEvents.append(contentsOf: mutationEvents)
                case .failure(let error):
                    queryError = error
                    return
                }
            }
            sempahore.wait()
        }
        if let queryError = queryError {
            completion(.failure(queryError))
        } else {
            completion(.success(queriedMutationEvents))
        }
    }
}
