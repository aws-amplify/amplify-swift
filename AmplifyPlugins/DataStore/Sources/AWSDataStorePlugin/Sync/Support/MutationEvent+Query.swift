//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Dispatch

extension MutationEvent {
    static func pendingMutationEvents(for modelId: Model.Identifier,
                                      storageAdapter: StorageEngineAdapter,
                                      completion: @escaping DataStoreCallback<[MutationEvent]>) {
        
        pendingMutationEvents(for: [modelId], storageAdapter: storageAdapter, completion: completion)
    }
    
    static func pendingMutationEvents(for modelIds: [Model.Identifier],
                                      storageAdapter: StorageEngineAdapter,
                                      completion: @escaping DataStoreCallback<[MutationEvent]>) {
        Task {
            let fields = MutationEvent.keys
            let predicate = (fields.inProcess == false || fields.inProcess == nil)
            let chunkedArrays = modelIds.chunked(into: SQLiteStorageEngineAdapter.maxNumberOfPredicates)
            var queriedMutationEvents: [MutationEvent] = []
            for chunkedArray in chunkedArrays {
                var queryPredicates: [QueryPredicateOperation] = []
                for id in chunkedArray {
                    queryPredicates.append(QueryPredicateOperation(field: fields.modelId.stringValue,
                                                                   operator: .equals(id)))
                }
                let groupedQueryPredicates =  QueryPredicateGroup(type: .or, predicates: queryPredicates)
                let final = QueryPredicateGroup(type: .and, predicates: [groupedQueryPredicates, predicate])
                let sort = QuerySortDescriptor(fieldName: fields.createdAt.stringValue, order: .ascending)
                
                do {
                    let mutationEvents = try await withCheckedThrowingContinuation { continuation in
                        storageAdapter.query(MutationEvent.self,
                                             predicate: final,
                                             sort: [sort],
                                             paginationInput: nil) { result in
                            continuation.resume(with: result)
                        }
                    }
                    
                    queriedMutationEvents.append(contentsOf: mutationEvents)
                } catch {
                    completion(.failure(causedBy: error))
                    return
                }
            }
            completion(.success(queriedMutationEvents))
        }
    }
}
