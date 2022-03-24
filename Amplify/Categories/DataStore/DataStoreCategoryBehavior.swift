//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

public typealias DataStoreCategoryBehavior = DataStoreBaseBehavior & DataStoreSubscribeBehavior

public protocol DataStoreBaseBehavior {

    /// Saves the model to storage. If sync is enabled, also initiates a sync of the mutation to the remote API
    func save<M: Model>(_ model: M,
                        where condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: DataStoreCallback<M?>)

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         sort sortInput: QuerySortInput?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>)
    /**
     Synchronization starts automatically whenever you run any DataStore operation (query(), save(), delete())
     however, you can explicitly begin the process with DatasStore.start()

     - parameter completion: callback to be invoked on success or failure
     */
    func start(completion: @escaping DataStoreCallback<Void>)

    /**
     To stop the DataStore sync process, you can use DataStore.stop(). This ensures the real time subscription
     connection is closed when your app is no longer interested in updates, such as when you application is closed.
     This can also be used to modify DataStore sync expressions at runtime by calling stop(), then start()
     to force your sync expressions to be re-evaluated.

     - parameter completion: callback to be invoked on success or failure
     */
    func stop(completion: @escaping DataStoreCallback<Void>)

    /**
     To clear local data from DataStore, use the clear method.

     - parameter completion: callback to be invoked on success or failure
     */
    func clear(completion: @escaping DataStoreCallback<Void>)
}

public protocol DataStoreSubscribeBehavior {
    /// Returns a Publisher for model changes (create, updates, delete)
    /// - Parameter modelType: The model type to observe
    func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError>

    /// Returns a Publisher for query snapshots.
    ///
    /// - Parameters:
    ///   - modelType: The model type to observe
    ///   - predicate: The predicate to match for filtered results
    ///   - sortInput: The field and order of data to be returned
    func observeQuery<M: Model>(for modelType: M.Type,
                                where predicate: QueryPredicate?,
                                sort sortInput: QuerySortInput?)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError>
}
