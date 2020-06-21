//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

public typealias DataStoreCategoryBehavior = DataStoreBaseBehavior & DataStoreSubscribeBehavior

public protocol DataStoreBaseBehavior {

    /// Saves the model to storage. If sync is enabled, also initiates a sync of the mutation to the remote
    /// API.
    ///
    /// - Parameters:
    ///   - model: The model instance to save. The model can be new or existing, and the DataStore will
    ///     either create or update as appropriate
    ///   - condition: The condition under which to perform the save
    ///   - completion: Invoked when the operation is complete
    func save<M: Model>(_ model: M,
                        where condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

    /// Queries for a specific model instance by id
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to query
    ///   - id: The ID of the model to query
    ///   - completion: Invoked when the operation is complete
    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: DataStoreCallback<M?>)

    /// Queries for any model instances that match the specified predicate
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to query
    ///   - predicate: The predicate for filtering results
    ///   - paginationInput: Describes how to paginate the query results
    ///   - completion: Invoked when the operation is complete
    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

    /// Deletes the specified model instance from the DataStore. If sync is enabled, this will delete the
    /// model from the remote store as well.
    ///
    /// - Parameters:
    ///   - model: The model instance to delete
    ///   - predicate: The predicate used to filter whether the delete will be executed or not
    ///   - completion: Invoked when the operation is complete
    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<Void>)

    /// Deletes the model with the specified ID from the DataStore. If sync is enabled, this will delete the
    /// model from the remote store as well.
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to delete
    ///   - id: The ID of the model to delete
    ///   - completion: Invoked when the operation is complete
    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: @escaping DataStoreCallback<Void>)

    /// Clears the local data store
    ///
    /// - Note: If sync is enabled, this method does **not** clear the remote store
    /// - Parameter completion: Invoked when the operation is complete
    func clear(completion: @escaping DataStoreCallback<Void>)
}

public protocol DataStoreSubscribeBehavior {

    /// Returns a Publisher for model changes (create, updates, delete)
    ///
    /// - Parameter modelType: The model type to observe
    /// - Returns: A Combine Publisher that delivers mutation events for the model type
    @available(iOS 13.0, *)
    func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError>
}
