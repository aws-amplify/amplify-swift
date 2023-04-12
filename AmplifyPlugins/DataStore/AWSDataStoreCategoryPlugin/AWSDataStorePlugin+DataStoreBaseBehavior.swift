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
                               modelSchema: ModelSchema,
                               where condition: QueryPredicate? = nil,
                               completion: @escaping DataStoreCallback<M>) {
        log.verbose("Saving: \(model) with condition: \(String(describing: condition))")
        initStorageEngineAndStartSync()

        // swiftlint:disable:next todo
        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            guard let engine = storageEngine as? StorageEngine else {
                throw DataStoreError.configuration("Unable to get storage adapter",
                                                   "")
            }
            modelExists = try engine.storageAdapter.exists(modelSchema,
                                                           withIdentifier: model.identifier(schema: modelSchema),
                                                           predicate: nil)
        } catch {
            if let dataStoreError = error as? DataStoreError {
                completion(.failure(dataStoreError))
                return
            }

            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            completion(.failure(dataStoreError))
            return
        }

        let mutationType = modelExists ? MutationEvent.MutationType.update : .create

        let publishingCompletion: DataStoreCallback<M> = { result in
            switch result {
            case .success(let model):
                // swiftlint:disable:next todo
                // TODO: Differentiate between save & update
                // swiftlint:disable:next todo
                // TODO: Handle errors from mutation event creation
                self.publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: mutationType)
            case .failure:
                break
            }

            completion(result)
        }
        storageEngine.save(model, modelSchema: modelSchema, condition: condition, completion: publishingCompletion)
    }

    // MARK: - Query

    @available(*, deprecated, message: "Use query(:byIdentifier:completion)")
    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        initStorageEngineAndStartSync()
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
                                completion: DataStoreCallback<M?>) where M: ModelIdentifiable,
                                                                         M.IdentifierFormat == ModelIdentifierFormat.Default {
        // swiftlint:disable:previous line_length
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: DefaultModelIdentifier<M>.makeDefault(id: identifier),
                          completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byIdentifier identifier: ModelIdentifier<M, M.IdentifierFormat>,
                                completion: DataStoreCallback<M?>) where M: ModelIdentifiable {
        queryByIdentifier(modelType,
                          modelSchema: modelType.schema,
                          identifier: identifier,
                          completion: completion)
    }

    private func queryByIdentifier<M: Model>(_ modelType: M.Type,
                                             modelSchema: ModelSchema,
                                             identifier: ModelIdentifierProtocol,
                                             completion: DataStoreCallback<M?>) {
        initStorageEngineAndStartSync()
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
                                modelSchema: ModelSchema,
                                where predicate: QueryPredicate? = nil,
                                sort sortInput: [QuerySortDescriptor]? = nil,
                                paginate paginationInput: QueryPaginationInput? = nil,
                                completion: DataStoreCallback<[M]>) {
        initStorageEngineAndStartSync()
        storageEngine.query(modelType,
                            modelSchema: modelSchema,
                            predicate: predicate,
                            sort: sortInput,
                            paginationInput: paginationInput,
                            completion: completion)
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
        initStorageEngineAndStartSync()
        storageEngine.delete(modelType, modelSchema: modelSchema, withId: id, condition: predicate) { result in
            self.onDeleteCompletion(result: result, modelSchema: modelSchema, completion: completion)
        }
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
          initStorageEngineAndStartSync()
          storageEngine.delete(modelType,
                               modelSchema: modelSchema,
                               withIdentifier: identifier,
                               condition: predicate) { result in
              self.onDeleteCompletion(result: result,
                                      modelSchema: modelSchema,
                                      completion: completion)
          }
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
        initStorageEngineAndStartSync()
        storageEngine.delete(type(of: model),
                             modelSchema: modelSchema,
                             withIdentifier: model.identifier(schema: modelSchema),
                             condition: predicate) { result in
            self.onDeleteCompletion(result: result, modelSchema: modelSchema, completion: completion)
        }
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
        initStorageEngineAndStartSync()
        let onCompletion: DataStoreCallback<[M]> = { result in
            switch result {
            case .success(let models):
                for model in models {
                    self.publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
                }
                completion(.emptyResult)
            case .failure(let error):
                completion(.failure(error))
            }
        }
        storageEngine.delete(modelType,
                             modelSchema: modelSchema,
                             filter: predicate,
                             completion: onCompletion)
    }

    public func start(completion: @escaping DataStoreCallback<Void>) {
        initStorageEngineAndStartSync { result in
            self.queue.async { completion(result) }
        }
    }

    public func stop(completion: @escaping DataStoreCallback<Void>) {
        storageEngineInitQueue.sync {
            operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
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
                self.queue.async {
                    completion(result)
                }
            }
        }
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        if case let .failure(error) = initStorageEngine() {
            completion(.failure(causedBy: error))
            return
        }

        storageEngineInitQueue.sync {
            operationQueue.operations.forEach { operation in
                if let operation = operation as? DataStoreObserveQueryOperation {
                    operation.resetState()
                }
            }
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

    // MARK: Private

    private func onDeleteCompletion<M: Model>(result: DataStoreResult<M?>,
                                              modelSchema: ModelSchema,
                                              completion: @escaping DataStoreCallback<Void>) {
        switch result {
        case .success(let modelOptional):
            if let model = modelOptional {
                publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: .delete)
            }
            completion(.emptyResult)
        case .failure(let error):
            completion(.failure(error))
        }
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
        deleteByIdentifier(modelType,
                           modelSchema: modelSchema,
                           identifier: identifier,
                           where: predicate,
                           completion: completion)
    }
} // swiftlint:disable:this file_length
