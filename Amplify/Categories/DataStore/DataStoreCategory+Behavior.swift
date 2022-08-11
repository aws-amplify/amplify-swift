//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension DataStoreCategory: DataStoreBaseBehavior {
    public func save<M: Model>(_ model: M,
                               where condition: QueryPredicate? = nil,
                               completion: @escaping DataStoreCallback<M>) {
        plugin.save(model, where: condition, completion: completion)
    }

    public func save<M: Model>(_ model: M,
                               where condition: QueryPredicate? = nil) async throws -> M {
        try await plugin.save(model, where: condition)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        plugin.query(modelType, byId: id, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String) async throws -> M? {
        try await plugin.query(modelType, byId: id)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier id: String,
                                completion: (DataStoreResult<M?>) -> Void) where M: ModelIdentifiable,
                                                                                 M.IdentifierFormat == ModelIdentifierFormat.Default {
        plugin.query(modelType, byIdentifier: id, completion: completion)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier id: String) async throws -> M?
        where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
            try await plugin.query(modelType, byIdentifier: id)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                completion: (DataStoreResult<M?>) -> Void) where M: ModelIdentifiable {
        plugin.query(modelType, byIdentifier: identifier, completion: completion)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>)
        async throws -> M? where M: ModelIdentifiable {
            try await plugin.query(modelType, byIdentifier: identifier)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: QuerySortInput? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil,
                                completion: DataStoreCallback<[M]>) {
        plugin.query(modelType, where: predicate, sort: sortInput, paginate: paginationInput, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: QuerySortInput? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil) async throws -> [M] {
        try await plugin.query(modelType, where: predicate, sort: sortInput, paginate: paginationInput)
    }

    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        plugin.delete(model, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil) async throws {
        try await plugin.delete(model, where: predicate)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        plugin.delete(modelType, withId: id, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 where predicate: QueryPredicate? = nil) async throws {
        try await plugin.delete(modelType, withId: id, where: predicate)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier id: String,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable,
                                                                                      M.IdentifierFormat == ModelIdentifierFormat.Default {

        plugin.delete(modelType, withIdentifier: id, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier id: String,
                                 where predicate: QueryPredicate? = nil) async throws
        where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
            try await plugin.delete(modelType, withIdentifier: id, where: predicate)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable {
        plugin.delete(modelType, withIdentifier: id, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
                                 where predicate: QueryPredicate? = nil) async throws where M: ModelIdentifiable {
        try await plugin.delete(modelType, withIdentifier: id, where: predicate)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 where predicate: QueryPredicate,
                                 completion: @escaping DataStoreCallback<Void>) {
        plugin.delete(modelType, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ modelType: M.Type,
                                 where predicate: QueryPredicate) async throws {
        try await plugin.delete(modelType, where: predicate)
    }

    public func start(completion: @escaping DataStoreCallback<Void>) {
        plugin.start(completion: completion)
    }
    
    public func start() async throws {
        try await plugin.start()
    }

    public func stop(completion: @escaping DataStoreCallback<Void>) {
        plugin.stop(completion: completion)
    }
    
    public func stop() async throws {
        try await plugin.stop()
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        plugin.clear(completion: completion)
    }
    
    public func clear() async throws {
        try await plugin.clear()
    }
}
