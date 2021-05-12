//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MutationEvent {
    static func pendingMutationEvents(forModelId modelId: Model.Identifier,
                                      storageAdapter: StorageEngineAdapter,
                                      completion: DataStoreCallback<[MutationEvent]>) {
        let fields = MutationEvent.keys
        let predicate = fields.modelId == modelId && (fields.inProcess == false || fields.inProcess == nil)
        let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             sort: [sort],
                             paginationInput: nil) { completion($0) }
    }

    static func pendingMutationEvents(forModelIds modelIds: [Model.Identifier],
                                      storageAdapter: StorageEngineAdapter,
                                      completion: DataStoreCallback<[MutationEvent]>) {
        let fields = MutationEvent.keys
        let predicate = (fields.inProcess == false || fields.inProcess == nil)
        let maxNumberOfPredicates = 950
        var queriedMutationEvents: [MutationEvent] = []
        var queryError: DataStoreError?
        let chunkedArrays = modelIds.chunked(into: maxNumberOfPredicates)
        for chunkedArray in chunkedArrays {
            var queryPredicates: [QueryPredicateOperation] = []
            for id in chunkedArray {
                queryPredicates.append(QueryPredicateOperation(field: fields.modelId.stringValue, operator: .equals(id)))
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
                    // TODO log?
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
