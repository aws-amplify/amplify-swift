//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public typealias DataStorePublisher<Output> = AnyPublisher<Output, DataStoreError>

public extension DataStoreBaseBehavior {

    /// Clears the local data store
    ///
    /// - Note: If sync is enabled, this method does **not** clear the remote store
    /// - Returns: A DataStorePublisher with the results of the operation
    func clear() -> DataStorePublisher<Void> {
        Future { promise in
            self.clear(completion: { promise($0) })
        }.eraseToAnyPublisher()
    }

    /// Deletes the model with the specified ID from the DataStore. If sync is enabled, this will delete the
    /// model from the remote store as well.
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to delete
    ///   - id: The ID of the model to delete
    /// - Returns: A DataStorePublisher with the results of the operation
    func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String
    ) -> DataStorePublisher<Void> {
        Future { promise in
            self.delete(modelType, withId: id, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    /// Deletes the specified model instance from the DataStore. If sync is enabled, this will delete the
    /// model from the remote store as well.
    ///
    /// - Parameters:
    ///   - model: The model instance to delete
    ///   - predicate: The predicate used to filter whether the delete will be executed or not
    /// - Returns: A DataStorePublisher with the results of the operation
    func delete<M: Model>(
        _ model: M,
        where predicate: QueryPredicate? = nil
    ) -> DataStorePublisher<Void> {
        Future { promise in
            self.delete(model, where: predicate, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    /// Queries for a specific model instance by id
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to query
    ///   - id: The ID of the model to query
    /// - Returns: A DataStorePublisher with the results of the operation
    func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) -> DataStorePublisher<M?> {
        Future { promise in
            self.query(modelType, byId: id, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    /// Queries for any model instances that match the specified predicate
    ///
    /// - Parameters:
    ///   - modelType: The type of the model to query
    ///   - predicate: The predicate for filtering results
    ///   - paginationInput: Describes how to paginate the query results
    /// - Returns: A DataStorePublisher with the results of the operation
    func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate? = nil,
        paginate paginationInput: QueryPaginationInput? = nil
    ) -> DataStorePublisher<[M]> {
        Future { promise in
            self.query(
                modelType,
                where: predicate,
                paginate: paginationInput,
                completion: { result in
                    promise(result)
            })
        }.eraseToAnyPublisher()
    }

    /// Saves the model to storage. If sync is enabled, also initiates a sync of the mutation to the remote
    /// API.
    ///
    /// - Parameters:
    ///   - model: The model instance to save. The model can be new or existing, and the DataStore will
    ///     either create or update as appropriate
    ///   - condition: The condition under which to perform the save
    /// - Returns: A DataStorePublisher with the results of the operation
    func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil
    ) -> DataStorePublisher<M> {
        Future { promise in
            self.save(model, where: condition, completion: { result in
                promise(result)
            })
        }.eraseToAnyPublisher()
    }

}
