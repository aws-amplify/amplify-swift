//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

public typealias QueryPredicateFactory = () -> QueryPredicate

public typealias DataStoreCategoryBehavior = DataStoreBaseBehavior & DataStoreSubscribeBehavior

public protocol DataStoreBaseBehavior {

    /// Saves the model to storage. If sync is enabled, also initiates a sync of the mutation to the remote API
    func save<M: Model>(_ model: M,
                        completion: @escaping DataStoreCallback<M>)

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: DataStoreCallback<M?>)

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicateFactory?,
                         completion: DataStoreCallback<[M]>)

    func delete<M: Model>(_ model: M,
                          completion: @escaping DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: @escaping DataStoreCallback<Void>)
}

public protocol DataStoreSubscribeBehavior {
    /// Returns a Publisher for model changes (create, updates, delete)
    /// - Parameter modelType: The model type to observe
    @available(iOS 13.0, *)
    func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError>
}
