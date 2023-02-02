//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {
    func setUp(modelSchemas: [ModelSchema]) throws

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws

    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

    func save<M: Model>(_ model: M,
                        condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>)

    @available(*, deprecated, message: "Use delete(:modelSchema:withIdentifier:predicate:completion")
    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          condition: QueryPredicate?,
                          completion: @escaping DataStoreCallback<M?>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withIdentifier identifier: ModelIdentifierProtocol,
                          condition: QueryPredicate?,
                          completion: @escaping DataStoreCallback<M?>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          filter: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>)

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

    // swiftlint:disable:next function_parameter_count
    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

}

protocol ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool
}

extension ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool {
        return false
    }
}
