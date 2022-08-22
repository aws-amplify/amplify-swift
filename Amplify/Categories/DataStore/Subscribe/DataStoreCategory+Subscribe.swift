//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

extension DataStoreCategory: DataStoreSubscribeBehavior {
    
    
    public func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError> {
        return plugin.publisher(for: modelType)
    }
    
    public func observe<M:Model>(for modelType: M.Type) async -> AmplifyAsyncThrowingSequence<MutationEvent> {
        await plugin.observe(for: modelType)
    }

    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: QuerySortInput? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return plugin.observeQuery(for: modelType, where: predicate, sort: sortInput)
    }
    
    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate?,
                                       sort sortInput: QuerySortInput?) async -> AmplifyAsyncThrowingSequence<DataStoreQuerySnapshot<M>> {
        await plugin.observeQuery(for: modelType, where: predicate, sort: sortInput)
    }
}
