//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension AWSDataStorePlugin: DataStoreBaseBehavior {

    // MARK: - Save
    public func save<M: Model>(_ model: M,
                               where condition: QueryPredicate? = nil,
                               completion: @escaping DataStoreCallback<M>) {
        save(model, modelSchema: model.schema, where: condition, completion: completion)
    }
    
    public func save<M: Model>(_ model: M,
                               where condition: QueryPredicate? = nil) async throws -> M {
        try await save(model, modelSchema: model.schema, where: condition)
    }

    public func save<M: Model>(_ model: M,
                               modelSchema: ModelSchema,
                               where condition: QueryPredicate? = nil,
                               completion: @escaping DataStoreCallback<M>) {
        log.verbose("Saving: \(model) with condition: \(String(describing: condition))")
        initStorageEngineAndStartSync()

        Task {
            let result = await storageEngine.save(
                model,
                modelSchema: modelSchema,
                condition: condition,
                eagerLoad: configuration.isEagerLoad
            ).ifSuccess {
                let (savedModel, mutationType) = $0
                publishMutationEvent(from: savedModel, modelSchema: modelSchema, mutationType: mutationType)
            }.map { $0.0 }

            completion(result)
        }

    }
    
    public func save<M: Model>(_ model: M,
                               modelSchema: ModelSchema,
                               where condition: QueryPredicate? = nil) async throws -> M {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<M, Error>) in
            save(model, modelSchema: modelSchema, where: condition) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Query

    @available(*, deprecated, renamed: "query(byIdentifier:completion:)")
    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        queryByIdentifier(
            modelType,
            modelSchema: modelType.schema,
            identifier: DefaultModelIdentifier<M>.makeDefault(id: id),
            completion: completion
        )
    }

    @available(*, deprecated, renamed: "query(byIdentifier:)")
    public func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) async throws -> M? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<M?, Error>)  in
            query(modelType, byId: id) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier identifier: String,
        completion: DataStoreCallback<M?>
    ) where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
                          completion: completion)
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier identifier: String
    ) async throws -> M? where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
        try await queryByIdentifier(modelType,
                                    modelSchema: modelType.schema,
                                    identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier))
    }

    public func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
        completion: DataStoreCallback<M?>
    ) where M: ModelIdentifiable {
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: identifier,
                          completion: completion)
    }
    
    public func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>
    ) async throws -> M?
        where M: ModelIdentifiable {
            try await queryByIdentifier(modelType,
                                        modelSchema: modelType.schema,
                                        identifier: identifier)
    }

    private func queryByIdentifier<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        identifier: ModelIdentifierProtocol,
        completion: DataStoreCallback<M?>
    ) {
        query(modelType,
              modelSchema: modelSchema,
              where: identifier.predicate,
              paginate: .firstResult) {
            switch $0 {
            case .success(let models):
                 do {
                     let first = try models.unique()
                     completion(.success(first))
                 } catch {
                     completion(.failure(causedBy: error))
                 }
            case .failure(let error):
                 completion(.failure(causedBy: error))
             }
         }
    }
    
    private func queryByIdentifier<M: Model>(_ modelType: M.Type,
                                             modelSchema: ModelSchema,
                                             identifier: ModelIdentifierProtocol) async throws -> M? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<M?, Error>)  in
            queryByIdentifier(modelType, modelSchema: modelSchema, identifier: identifier) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: QuerySortInput? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil,
                                completion: DataStoreCallback<[M]>) {
        query(modelType,
              modelSchema: modelType.schema,
              where: predicate,
              sort: sortInput?.asSortDescriptors(),
              paginate: paginationInput,
              completion: completion)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: QuerySortInput? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil) async throws -> [M] {
        try await query(modelType,
                        modelSchema: modelType.schema,
                        where: predicate,
                        sort: sortInput?.asSortDescriptors(),
                        paginate: paginationInput)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                modelSchema: ModelSchema,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: [QuerySortDescriptor]? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil,
                                completion: DataStoreCallback<[M]>) {
        initStorageEngineAndStartSync()
        let result = storageEngine.query(modelType,
                            modelSchema: modelSchema,
                            condition: predicate,
                            sort: sortInput,
                            paginationInput: paginationInput,
                            eagerLoad: configuration.isEagerLoad)
        completion(result)
    }
    
    public func query<M: Model>(_ modelType: M.Type,
                                modelSchema: ModelSchema,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: [QuerySortDescriptor]? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil) async throws -> [M] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[M], Error>)  in
            query(modelType, modelSchema: modelSchema, where: predicate, sort: sortInput, paginate: paginationInput) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Delete
    @available(*, deprecated, renamed: "delete(withIdentifier:)")
    public func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate?
    ) async throws {
        try await delete(modelType, modelSchema: modelType.schema, withId: id, where: predicate)
    }
    
    @available(*, deprecated, renamed: "delete(withIdentifier:)")
    public func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async throws {
        initStorageEngineAndStartSync()
        let result = await storageEngine.delete(
            modelType,
            modelSchema: modelSchema,
            withIdentifier: DefaultModelIdentifier<M>.makeDefault(id: id),
            condition: predicate
        ).ifSuccess({ model in
            if let model = model {
                publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
            }
        })

        if case .failure(let error) = result {
            throw error
        }

    }
    public func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier identifier: String,
        where predicate: QueryPredicate? = nil,
        completion: @escaping DataStoreCallback<Void>
    ) where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
        Task {
            let result = await deleteByIdentifier(
                modelType,
                modelSchema: modelType.schema,
                identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
                where: predicate
            )
            completion(result)
        }
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier identifier: String,
        where predicate: QueryPredicate? = nil
    ) async throws where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
        let result = await deleteByIdentifier(
            modelType,
            modelSchema: modelType.schema,
            identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
            where: predicate
        )

        if case .failure(let error) = result {
            throw error
        }
    }

    public func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
        where predicate: QueryPredicate? = nil,
        completion: @escaping DataStoreCallback<Void>
    ) where M: ModelIdentifiable {
        Task {
            let result = await deleteByIdentifier(
                modelType,
                modelSchema: modelType.schema,
                identifier: identifier,
                where: predicate
            )
            completion(result)
        }
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
        where predicate: QueryPredicate? = nil
    ) async throws where M: ModelIdentifiable {
        let result = await deleteByIdentifier(
            modelType,
            modelSchema: modelType.schema,
            identifier: identifier,
            where: predicate
        )

        if case .failure(let error) = result {
            throw error
        }
    }

    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        delete(model, modelSchema: model.schema, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil) async throws {
        try await delete(model, modelSchema: model.schema, where: predicate)
    }

    public func delete<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate? = nil,
        completion: @escaping DataStoreCallback<Void>
    ) {
        initStorageEngineAndStartSync()
        Task {
            let result = await storageEngine.delete(
                type(of: model),
                modelSchema: modelSchema,
                withIdentifier: model.identifier(schema: modelSchema),
                condition: predicate
            ).ifSuccess { model in
                if let model = model {
                    publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
                }
            }.dropSuccessValue()
            completion(result)
        }

    }
    
    public func delete<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete(model, modelSchema: modelSchema, where: predicate) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func delete<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate,
        completion: @escaping DataStoreCallback<Void>
    ) {
        delete(modelType, modelSchema: modelType.schema, where: predicate, completion: completion)
    }
    
    public func delete<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate
    ) async throws {
        try await delete(modelType, modelSchema: modelType.schema, where: predicate)
    }

    public func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate,
        completion: @escaping DataStoreCallback<Void>
    ) {
        initStorageEngineAndStartSync()

        Task {
            let result = await storageEngine.delete(
                modelType,
                modelSchema: modelSchema,
                condition: predicate
            ).ifSuccess { models in
                for model in models {
                    publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
                }
            }.dropSuccessValue()

            completion(result)
        }
    }
    
    public func delete<M: Model>(_ modelType: M.Type,
                                 modelSchema: ModelSchema,
                                 where predicate: QueryPredicate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete(modelType, modelSchema: modelSchema, where: predicate) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func start(completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSync { result in
            completion(result)
        }
    }
    
    public func start() async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataStoreResult<Void>, Error>) in
            start { result in
                continuation.resume(returning: result)
            }
        }
    }

    public func stop(completion: @escaping DataStoreCallback<Void>) {
        storageEngineInitQueue.sync {
            self.dataStoreStateSubject.send(.stop)
            dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }
            if storageEngine == nil {
                queue.async {
                    completion(.successfulVoid)
                }
                return
            }

            storageEngine.stopSync { result in
                self.storageEngine = nil
                self.queue.async {
                    completion(result)
                }
            }
        }
    }
    
    public func stop() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stop { result in
                continuation.resume(with: result)
            }
        }
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        if case let .failure(error) = initStorageEngine() {
            completion(.failure(causedBy: error))
            return
        }

        storageEngineInitQueue.sync {
            self.dataStoreStateSubject.send(.clear)
            dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }
            if storageEngine == nil {
                queue.async {
                    completion(.successfulVoid)
                }
                return
            }
            storageEngine.clear { result in
                self.storageEngine = nil
                self.queue.async {
                    completion(result)
                }
            }
        }
    }
    
    public func clear() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            clear { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: Private

    private func deleteByIdentifier<M: Model & ModelIdentifiable>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        identifier: ModelIdentifierProtocol,
        where predicate: QueryPredicate?
    ) async -> Result<Void, DataStoreError>  {
        initStorageEngineAndStartSync()
        return await storageEngine.delete(
            modelType,
            modelSchema: modelSchema,
            withIdentifier: identifier,
            condition: predicate
        ).ifSuccess({ model in
            if let model = model {
                publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
            }
        }).dropSuccessValue()
    }
    
    private func publishMutationEvent<M: Model>(
        from model: M,
        modelSchema: ModelSchema,
        mutationType: MutationEvent.MutationType
    ) {
        guard let storageEngine = storageEngine else {
            log.warn("Skipping mutation event publishing; StorageEngine is not initialzied yet!")
            return
        }

        let metadata = MutationSyncMetadata.keys
        let metadataId = MutationSyncMetadata.identifier(
            modelName: modelSchema.name,
            modelId: model.identifier(schema: modelSchema).stringValue
        )

        let result = storageEngine.query(
            MutationSyncMetadata.self,
            modelSchema: MutationSyncMetadata.schema,
            condition: metadata.id == metadataId,
            sort: nil,
            paginationInput: .firstResult,
            eagerLoad: true
        ).flatMap {
            publishMutationEvent(model: model, modelSchema: modelSchema, mutationType: mutationType, mutationMetadata: $0)
        }

        if case let .failure(error) = result {
            log.error(error: error)
        }
    }

    private func publishMutationEvent(
        model: Model,
        modelSchema: ModelSchema,
        mutationType: MutationEvent.MutationType,
        mutationMetadata: [MutationSyncMetadata]
    ) -> Result<Void, DataStoreError> {
        do {
            let syncMetadata = try mutationMetadata.unique()
            let mutationEvent = try MutationEvent(model: model,
                                                  modelSchema: modelSchema,
                                                  mutationType: mutationType,
                                                  version: syncMetadata?.version)
            self.dataStorePublisher?.send(input: mutationEvent)
            return .success(())
        } catch {
            return .failure(DataStoreError(error: error))
        }
    }

}

/// Overrides needed by platforms using a serialized version of models (i.e. Flutter)
extension AWSDataStorePlugin {
    public func query<M: Model>(_ modelType: M.Type,
                                modelSchema: ModelSchema,
                                byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                completion: DataStoreCallback<M?>) where M: ModelIdentifiable {
        queryByIdentifier(modelType,
                          modelSchema: modelSchema,
                          identifier: identifier,
                          completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 modelSchema: ModelSchema,
                                 withIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                 where predicate: QueryPredicate?,
                                 completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable {
        Task {
            let result = await deleteByIdentifier(
                modelType,
                modelSchema: modelSchema,
                identifier: identifier,
                where: predicate
            )

            completion(result)
        }
    }
}
