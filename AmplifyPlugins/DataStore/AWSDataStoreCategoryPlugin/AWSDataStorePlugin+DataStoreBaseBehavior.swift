//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension AWSDataStorePlugin: DataStoreBaseBehavior {

    public func save<M: Model>(_ model: M,
                               completion: @escaping DataStoreCallback<M>) {
        log.verbose("Saving: \(model)")

        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            guard let engine = storageEngine as? StorageEngine else {
                throw DataStoreError.configuration("Unable to get storage adapter",
                                                   "")
            }
            modelExists = try engine.storageAdapter.exists(M.self, withId: model.id)
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

        storageEngine.save(model, completion: publishingCompletion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        let predicate: QueryPredicateFactory = { field("id") == id }
        query(modelType, where: predicate) {
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
                                where predicateFactory: QueryPredicateFactory? = nil,
                                completion: DataStoreCallback<[M]>) {
        storageEngine.query(modelType,
                            predicate: predicateFactory?(),
                            completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: @escaping DataStoreCallback<Void>) {
        storageEngine.delete(modelType,
                             withId: id,
                             completion: completion)
    }

    public func delete<M: Model>(_ model: M,
                                 completion: @escaping DataStoreCallback<Void>) {
        let publishingCompletion: DataStoreCallback<Void> = { result in
            switch result {
            case .success:
                // TODO: Handle errors from mutation event creation
                self.publishMutationEvent(from: model, mutationType: .delete)
            case .failure:
                break
            }

            completion(result)
        }

        delete(type(of: model),
               withId: model.id,
               completion: publishingCompletion)
    }

    // MARK: Private

    private func publishMutationEvent<M: Model>(from model: M,
                                                mutationType: MutationEvent.MutationType) {
        if #available(iOS 13.0, *) {
            let metadata = MutationSyncMetadata.keys
            storageEngine.query(MutationSyncMetadata.self,
                                predicate: metadata.id == model.id) {
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
