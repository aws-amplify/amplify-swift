//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension AWSDataStorePlugin: DataStoreBaseBehavior {

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
        reinitStorageEngineIfNeeded()

        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            guard let engine = storageEngine as? StorageEngine else {
                throw DataStoreError.configuration("Unable to get storage adapter",
                                                   "")
            }
            modelExists = try engine.storageAdapter.exists(modelSchema, withId: model.id, predicate: nil)
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
                // TODO: Differentiate between save & update
                // TODO: Handle errors from mutation event creation
                self.publishMutationEvent(from: model, modelSchema: modelSchema, mutationType: mutationType)
            case .failure:
                break
            }

            completion(result)
        }
        storageEngine.save(model, modelSchema: modelSchema, condition: condition, completion: publishingCompletion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        reinitStorageEngineIfNeeded()
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
        reinitStorageEngineIfNeeded()
        storageEngine.query(modelType,
                            modelSchema: modelSchema,
                            predicate: predicate,
                            sort: sortInput,
                            paginationInput: paginationInput,
                            completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: @escaping DataStoreCallback<Void>) {
        delete(modelType, modelSchema: modelType.schema, withId: id, completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 modelSchema: ModelSchema,
                                 withId id: String,
                                 completion: @escaping DataStoreCallback<Void>) {
        reinitStorageEngineIfNeeded()
        storageEngine.delete(modelType, modelSchema: modelSchema, withId: id) { result in
            self.onDeleteCompletion(result: result, modelSchema: modelSchema, completion: completion)
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
        reinitStorageEngineIfNeeded()
        // TODO: handle query predicate like in the update flow
        storageEngine.delete(type(of: model), modelSchema: modelSchema, withId: model.id) { result in
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
        reinitStorageEngineIfNeeded()
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
                             predicate: predicate,
                             completion: onCompletion)
    }

    public func start(completion: @escaping DataStoreCallback<Void>) {
        reinitStorageEngineIfNeeded(completion: completion)
    }

    public func stop(completion: @escaping DataStoreCallback<Void>) {
        storageEngineInitSemaphore.wait()
        if storageEngine == nil {
            storageEngineInitSemaphore.signal()
            completion(.successfulVoid)
            return
        }
        storageEngineInitSemaphore.signal()
        storageEngine.stopSync { result in
            self.storageEngine = nil
            if #available(iOS 13.0, *) {
                self.dataStorePublisher?.sendFinished()
            }
            self.dataStorePublisher = nil
            completion(result)
        }
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        storageEngineInitSemaphore.wait()
        if storageEngine == nil {
            storageEngineInitSemaphore.signal()
            completion(.successfulVoid)
            return
        }
        storageEngineInitSemaphore.signal()
        storageEngine.clear { result in
            self.storageEngine = nil
            if #available(iOS 13.0, *) {
                self.dataStorePublisher?.sendFinished()
            }
            self.dataStorePublisher = nil
            completion(result)
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
        let metadata = MutationSyncMetadata.keys
        storageEngine.query(MutationSyncMetadata.self,
                            predicate: metadata.id == model.id,
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
