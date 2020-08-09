//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {
    func setUp(schemas: [ModelSchema]) throws

    func save<M: Model>(_ model: M,
                        schema: ModelSchema,
                        where condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

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
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

    func query<M: Model>(_ modelType: M.Type,
                         schema: ModelSchema,
                         predicate: QueryPredicate?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

}
