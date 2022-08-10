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
    func save<M: Model>(_ model: M,
                        where condition: QueryPredicate?) async -> DataStoreResult<M>

    @available(*, deprecated, message: "Use query(:byIdentifier:completion)")
    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: DataStoreCallback<M?>)
    @available(*, deprecated, message: "Use query(:byIdentifier)")
    func query<M: Model>(_ modelType: M.Type,
                         byId id: String) async -> DataStoreResult<M?>

    func query<M: Model>(_ modelType: M.Type,
                         byIdentifier id: String,
                         completion: DataStoreCallback<M?>) where M: ModelIdentifiable,
                                                                  M.IdentifierFormat == ModelIdentifierFormat.Default
    func query<M: Model>(_ modelType: M.Type,
                         byIdentifier id: String) async -> DataStoreResult<M?>
        where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default

    func query<M: Model>(_ modelType: M.Type,
                         byIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
                         completion: DataStoreCallback<M?>) where M: ModelIdentifiable
    func query<M: Model>(_ modelType: M.Type,
                         byIdentifier id: ModelIdentifier<M, M.IdentifierFormat>) async -> DataStoreResult<M?>
        where M: ModelIdentifiable

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         sort sortInput: QuerySortInput?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)
    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         sort sortInput: QuerySortInput?,
                         paginate paginationInput: QueryPaginationInput?) async -> DataStoreResult<[M]>

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>)
    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate?) async -> DataStoreResult<Void>

    @available(*, deprecated, message: "Use delete(:withIdentifier:where:completion)")
    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>)
    @available(*, deprecated, message: "Use delete(:withIdentifier:where)")
    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          where predicate: QueryPredicate?) async -> DataStoreResult<Void>

    func delete<M: Model>(_ modelType: M.Type,
                          withIdentifier id: String,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable,
                                                                               M.IdentifierFormat == ModelIdentifierFormat.Default
    func delete<M: Model>(_ modelType: M.Type,
                          withIdentifier id: String,
                          where predicate: QueryPredicate?) async -> DataStoreResult<Void> where M: ModelIdentifiable,
                                                                                                 M.IdentifierFormat == ModelIdentifierFormat.Default

    func delete<M: Model>(_ modelType: M.Type,
                          withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable
    func delete<M: Model>(_ modelType: M.Type,
                          withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
                          where predicate: QueryPredicate?) async -> DataStoreResult<Void> where M: ModelIdentifiable

    func delete<M: Model>(_ modelType: M.Type,
                           where predicate: QueryPredicate,
                           completion: @escaping DataStoreCallback<Void>)
    func delete<M: Model>(_ modelType: M.Type,
                           where predicate: QueryPredicate) async -> DataStoreResult<Void>

    /**
     Synchronization starts automatically whenever you run any DataStore operation (query(), save(), delete())
     however, you can explicitly begin the process with DatasStore.start()

     - parameter completion: callback to be invoked on success or failure
     */
    func start(completion: @escaping DataStoreCallback<Void>)
    func start() async -> DataStoreResult<Void>

    /**
     To stop the DataStore sync process, you can use DataStore.stop(). This ensures the real time subscription
     connection is closed when your app is no longer interested in updates, such as when you application is closed.
     This can also be used to modify DataStore sync expressions at runtime by calling stop(), then start()
     to force your sync expressions to be re-evaluated.

     - parameter completion: callback to be invoked on success or failure
     */
    func stop(completion: @escaping DataStoreCallback<Void>)
    func stop() async -> DataStoreResult<Void>

    /**
     To clear local data from DataStore, use the clear method.

     - parameter completion: callback to be invoked on success or failure
     */
    func clear(completion: @escaping DataStoreCallback<Void>)
    func clear() async -> DataStoreResult<Void>
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
