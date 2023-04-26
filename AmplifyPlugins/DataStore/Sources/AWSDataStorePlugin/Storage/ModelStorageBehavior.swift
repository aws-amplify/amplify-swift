//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {

    /// Setup the model store with the given schema
    func setUp(modelSchemas: [ModelSchema]) throws

    /// Apply any data migration logic for the given schemas in the underlying data store.
    func applyModelMigrations(modelSchemas: [ModelSchema]) throws

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M?, DataStoreError>

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?,
        eagerLoad: Bool
    ) -> Swift.Result<[M], DataStoreError>

    // createOrUpdate

    func save(_ model: Model, eagerLoad: Bool) -> Swift.Result<Model, DataStoreError>

    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<(M, MutationEvent.MutationType), DataStoreError>

    func create<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M, DataStoreError>

    func update<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M, DataStoreError>

    func delete(
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) -> Swift.Result<Void, DataStoreError>

    // bulk deletion
    func delete(
        modelSchema: ModelSchema,
        condition: QueryPredicate
    ) -> Swift.Result<Void, DataStoreError>
}

protocol ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool
}

extension ModelStorageErrorBehavior {
    func shouldIgnoreError(error: DataStoreError) -> Bool {
        return false
    }
}

extension ModelStorageBehavior {
    func delete(
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) -> Swift.Result<Void, DataStoreError> {
        var predicate: QueryPredicate = field(modelSchema.primaryKey.sqlName).eq(identifier.stringValue)
        if let condition = condition {
            predicate = QueryPredicateGroup(type: .and, predicates: [predicate, condition])
        }
        return delete(modelSchema: modelSchema, condition: predicate)
    }


    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M?, DataStoreError> {
        var predicate: QueryPredicate = field(modelSchema.primaryKey.sqlName).eq(identifier.stringValue)
        if let condition = condition {
            predicate = QueryPredicateGroup(type: .and, predicates: [predicate, condition])
        }
        return query(
            modelType,
            modelSchema: modelSchema,
            condition: predicate,
            sort: nil,
            paginationInput: nil,
            eagerLoad: eagerLoad
        ).map { $0.first }
    }
}
