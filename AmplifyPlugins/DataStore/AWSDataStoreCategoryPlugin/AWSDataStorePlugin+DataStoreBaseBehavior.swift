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
            modelExists = try engine.storageAdapter.exists(M.self, withId: model.id, predicate: nil)
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
                self.publishMutationEvent(from: model, mutationType: mutationType)
            case .failure:
                break
            }

            completion(result)
        }

        storageEngine.save(model,
                           condition: condition,
                           completion: publishingCompletion)

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
        reinitStorageEngineIfNeeded()
        storageEngine.query(modelType,
                            predicate: predicate,
                            sort: sortInput,
                            paginationInput: paginationInput,
                            completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: @escaping DataStoreCallback<Void>) {
        reinitStorageEngineIfNeeded()
        storageEngine.delete(modelType, withId: id) { result in
            self.onDeleteCompletion(result: result, completion: completion)
        }
    }

    public func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil,
                                 completion: @escaping DataStoreCallback<Void>) {
        reinitStorageEngineIfNeeded()
        // TODO: handle query predicate like in the update flow
        storageEngine.delete(type(of: model), withId: model.id) { result in
            self.onDeleteCompletion(result: result, completion: completion)
        }
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 where predicate: QueryPredicate,
                                 completion: @escaping DataStoreCallback<Void>) {
        reinitStorageEngineIfNeeded()
        let onCompletion: DataStoreCallback<[M]> = { result in
            switch result {
            case .success(let models):
                for model in models {
                    self.publishMutationEvent(from: model, mutationType: .delete)
                }
                completion(.emptyResult)
            case .failure(let error):
                completion(.failure(error))
            }
        }
        storageEngine.delete(modelType,
                             predicate: predicate,
                             completion: onCompletion)
    }

    public func clear(completion: @escaping DataStoreCallback<Void>) {
        if storageEngine == nil {
            completion(.successfulVoid)
            return
        }
        storageEngine.clear { result in
            self.storageEngine = nil
            if #available(iOS 13.0, *) {
                if let publisher = self.dataStorePublisher as? DataStorePublisher {
                    publisher.sendFinished()
                }
            }
            self.dataStorePublisher = nil
            completion(result)
        }
    }

    // MARK: Private

    private func onDeleteCompletion<M: Model>(result: DataStoreResult<M?>,
                                              completion: @escaping DataStoreCallback<Void>) {
        switch result {
        case .success(let modelOptional):
            if let model = modelOptional {
                publishMutationEvent(from: model, mutationType: .delete)
            }
            completion(.emptyResult)
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func publishMutationEvent<M: Model>(from model: M,
                                                mutationType: MutationEvent.MutationType) {
        if #available(iOS 13.0, *) {
            let metadata = MutationSyncMetadata.keys
            storageEngine.query(MutationSyncMetadata.self,
                                predicate: metadata.id == model.id,
                                sort: nil,
                                paginationInput: .firstResult) {
                                    switch $0 {
                                    case .success(let result):
                                        do {
                                            let syncMetadata = try result.unique()
                                            let mutationEvent = try MutationEvent(model: model,
                                                                                  mutationType: mutationType,
                                                                                  version: syncMetadata?.version)
                                            if let publisher = self.dataStorePublisher as? DataStorePublisher {
                                                publisher.send(input: mutationEvent)
                                            }
                                        } catch {
                                            self.log.error(error: error)
                                        }
                                    case .failure(let error):
                                        self.log.error(error: error)
                                    }
            }
        }
    }

}
