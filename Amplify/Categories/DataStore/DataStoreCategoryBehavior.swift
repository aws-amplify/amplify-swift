//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias QueryPredicateFactory = () -> QueryPredicate

public protocol DataStoreCategoryBehavior {

    func save<M: Model>(_ model: M, completion: DataStoreCallback<M>)

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: DataStoreCallback<M?>)

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicateFactory?,
                         completion: DataStoreCallback<[M]>)

    func delete<M: Model>(_ model: M,
                          completion: DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: DataStoreCallback<Void>)

}
