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

    public func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        where condition: QueryPredicate? = nil,
        completion: @escaping DataStoreCallback<M>
    ) {
        log.verbose("Saving: \(model) with condition: \(String(describing: condition))")
        initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { $0.save(model, modelSchema: modelSchema, condition: condition)}
            .map { modelAndMutationType in
                let (model, mutationType) = modelAndMutationType
                self.publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: mutationType)
                return model
            }
            .execute { completion($0) }
    }

    // MARK: - Query

    @available(*, deprecated, message: "Use query(:byIdentifier:completion)")
    public func query<M: Model>(
        _ modelType: M.Type,
        byId id: String,
        completion: @escaping DataStoreCallback<M?>
    ) {
        let predicate: QueryPredicate = field("id") == id
        query(modelType, where: predicate, paginate: .firstResult) {
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

    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier identifier: String,
                                completion: @escaping DataStoreCallback<M?>
    ) where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
        // swiftlint:disable:previous line_length
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
                          completion: completion)
    }

    public func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
        completion: @escaping DataStoreCallback<M?>
    ) where M: ModelIdentifiable {
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: identifier,
                          completion: completion)
    }

    private func queryByIdentifier<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        identifier: ModelIdentifierProtocol,
        completion: @escaping DataStoreCallback<M?>
    ) {
        query(
            modelType,
            modelSchema: modelSchema,
            where: identifier.predicate,
            paginate: .firstResult
        ) {
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

    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: QuerySortInput? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil,
                                completion: @escaping DataStoreCallback<[M]>) {
        query(modelType,
              modelSchema: modelType.schema,
              where: predicate,
              sort: sortInput?.asSortDescriptors(),
              paginate: paginationInput,
              completion: completion)
    }

    public func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        where predicate: QueryPredicate? = nil,
        sort sortInput: [QuerySortDescriptor]? = nil,
        paginate paginationInput: QueryPaginationInput? = nil,
        completion: @escaping DataStoreCallback<[M]>
    ) {
        initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { storageEngine in
                storageEngine.query(
                    modelType,
                    modelSchema: modelSchema,
                    predicate: predicate,
                    sort: sortInput,
                    paginationInput: paginationInput
                )
            }.execute { completion($0) }
    }

    // MARK: - Delete

    @available(*, deprecated, message: "Use delete(:withIdentifier:where:completion)")
    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        delete(modelType, modelSchema: modelType.schema, withId: id, where: predicate, completion: completion)
    }

    @available(*, deprecated, message: "Use delete(:withIdentifier:where:completion)")
    public func delete<M: Model>(_ modelType: M.Type,
                                 modelSchema: ModelSchema,
                                 withId id: String,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { storageEngine in
                storageEngine.delete(modelType, modelSchema: modelSchema, withId: id, condition: predicate)
            }
            .map { self.onDeleteCompletion(model: $0, modelSchema: modelSchema) }
            .execute { completion($0) }
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier identifier: String,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable,
                                                                                      M.IdentifierFormat == ModelIdentifierFormat.Default {
       // swiftlint:disable:previous line_length
       deleteByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
                          where: predicate,
                          completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable {
        deleteByIdentifier(modelType,
                           modelSchema: modelType.schema,
                           identifier: identifier,
                           where: predicate,
                           completion: completion)
    }

    private func deleteByIdentifier<M: Model>(_ modelType: M.Type,
                                              modelSchema: ModelSchema,
                                              identifier: ModelIdentifierProtocol,
                                              where predicate: QueryPredicate?,
                                              completion: @escaping DataStoreCallback<Void>) where M: ModelIdentifiable {
          // swiftlint:disable:previous line_length
          initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { storageEngine in
                storageEngine.delete(
                    modelType,
                    modelSchema: modelSchema,
                    withIdentifier: identifier,
                    condition: predicate
                )
            }
            .map { self.onDeleteCompletion(model: $0, modelSchema: modelSchema) }
            .execute { completion($0) }
    }

    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        delete(model, modelSchema: model.schema, where: predicate, completion: completion)
    }

    public func delete<M: Model>(_ model: M,
                                 modelSchema: ModelSchema,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { storageEngine in
                storageEngine.delete(
                    type(of: model),
                    modelSchema: modelSchema,
                    withIdentifier: model.identifier(schema: modelSchema),
                    condition: predicate
                )
            }
            .map { self.onDeleteCompletion(model: $0, modelSchema: modelSchema) }
            .execute { completion($0) }
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 where predicate: QueryPredicate,
                                 completion: @escaping DataStoreCallback<Void>) {
        delete(modelType, modelSchema: modelType.schema, where: predicate, completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 modelSchema: ModelSchema,
                                 where predicate: QueryPredicate,
                                 completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSyncing()
            .flatMapOnResult(asStorageEngine(storageEngineBehavior:))
            .flatMap { storageEngine in
                storageEngine.delete(
                    modelType,
                    modelSchema: modelSchema,
                    filter: predicate
                )
            }
            .map { $0.map { model in self.onDeleteCompletion(model: model, modelSchema: modelSchema) } }
            .execute { completion($0.map {_ in () }) }
    }

    public func start(completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSyncing().execute { result in
            completion(result.map { _ in () })
        }
    }

    public func stop(completion: @escaping DataStoreCallback<Void>) {
        stopAsync().execute { completion($0) }
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAsync()
            .flatMap { _ in self.clearAsync() }
            .execute { completion($0) }
    }

    // MARK: Private

    private func clearAsync() -> Promise<Void, DataStoreError> {
        Promise(runOn: storageEngineInitQueue) { completion in
            self.operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
            self.dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }
            if self.storageEngine == nil {
                self.queue.async {
                    completion(.successfulVoid)
                }
                return
            }
            self.storageEngine.clear { result in
                self.storageEngine = nil
                self.queue.async {
                    completion(result)
                }
            }
        }
    }

    private func stopAsync() -> Promise<Void, DataStoreError> {
        Promise(runOn: storageEngineInitQueue) { completion in
            self.operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
            self.dispatchedModelSyncedEvents.forEach { _, dispatchedModelSynced in
                dispatchedModelSynced.set(false)
            }

            if self.storageEngine == nil {
                self.queue.async {
                    completion(.successfulVoid)
                }
                return
            }

            self.storageEngine.stopSync { result in
                self.storageEngine = nil
                self.queue.async {
                    completion(result)
                }
            }
        }
    }

    private func onDeleteCompletion<M: Model>(
        model: M?,
        modelSchema: ModelSchema
    ) -> M? {
        if let model = model {
            publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
        }
        return model
    }

    private func publishMutationEvent<M: Model>(from model: M,
                                                modelSchema: ModelSchema,
                                                mutationType: MutationEvent.MutationType) {

        guard #available(iOS 13.0, *) else {
            return
        }

        guard let storageEngine = storageEngine else {
            return
        }

        let metadata = MutationSyncMetadata.keys
        let metadataId = MutationSyncMetadata.identifier(modelName: modelSchema.name,
                                                         modelId: model.identifier(schema: modelSchema).stringValue)
        storageEngine.query(MutationSyncMetadata.self,
                            predicate: metadata.id == metadataId,
                            sort: nil,
                            paginationInput: .firstResult) {
            do {
                let result = try $0.get()
                let syncMetadata = try result.unique()
                let mutationEvent = try MutationEvent(model: model,
                                                      modelSchema: modelSchema,
                                                      mutationType: mutationType,
                                                      version: syncMetadata?.version)
                self.dataStorePublisher?.send(input: mutationEvent)
            } catch {
                self.log.error(error: error)
            }
        }
    }

    private func asStorageEngine(
        storageEngineBehavior: StorageEngineBehavior
    ) -> Result<StorageEngine, DataStoreError> {
        if let storageEngine = storageEngineBehavior as? StorageEngine {
            return .success(storageEngine)
        }
        return .failure(DataStoreError.configuration("Unable to get storage adapter", ""))
    }

}

/// Overrides needed by platforms using a serialized version of models (i.e. Flutter)
extension AWSDataStorePlugin {
    public func query<M: Model>(_ modelType: M.Type,
                                modelSchema: ModelSchema,
                                byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                completion: @escaping DataStoreCallback<M?>) where M: ModelIdentifiable {
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
        deleteByIdentifier(modelType,
                           modelSchema: modelSchema,
                           identifier: identifier,
                           where: predicate,
                           completion: completion)
    }
} // swiftlint:disable:this file_length
