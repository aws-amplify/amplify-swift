//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

extension DataStoreCategory: DataStoreSubscribeBehavior {
    @available(iOS 13.0, *)
    public func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError> {
        return plugin.publisher(for: modelType)
    }

    @available(iOS 13.0, *)
    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: QuerySortInput? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return plugin.observeQuery(for: modelType, where: predicate, sort: sortInput)
    }
}
