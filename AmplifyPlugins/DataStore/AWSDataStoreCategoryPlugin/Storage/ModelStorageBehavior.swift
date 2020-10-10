//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {
    func setUp(models: [Model.Type]) throws

    func save<M: Model>(_ model: M,
                        condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: @escaping DataStoreCallback<M?>)

    func delete<M: Model>(_ modelType: M.Type,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>)

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: QuerySortInput?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

}
