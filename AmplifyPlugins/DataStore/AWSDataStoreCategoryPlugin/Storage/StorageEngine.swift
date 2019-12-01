//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

final class StorageEngine: StorageEngineBehavior {

    // TODO: Make this private once we get a request/response flow with metadata/mutation types figured out
    let storageAdapter: StorageEngineAdapter

    private let isSyncEnabled: Bool

    private var syncEngine: CloudSyncEngineBehavior?

    private weak var api: APICategoryGraphQLBehavior?

    static var systemModels: [Model.Type] {
        return [
            MutationEvent.self,
            MutationSyncMetadata.self
        ]
    }

    // Internal initializer used for testing, to allow lazy initialization of the SyncEngine. Note that the provided
    // storageAdapter must have already been set up with system models
    init(storageAdapter: StorageEngineAdapter,
         syncEngine: CloudSyncEngineBehavior? = nil,
         isSyncEnabled: Bool) {
        self.storageAdapter = storageAdapter
        self.syncEngine = syncEngine
        self.isSyncEnabled = isSyncEnabled
    }

    convenience init(isSyncEnabled: Bool) throws {
        let key = kCFBundleNameKey as String
        let databaseName = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let storageAdapter = try SQLiteStorageEngineAdapter(databaseName: databaseName ?? "app")

        try storageAdapter.setUp(models: StorageEngine.systemModels)
        if #available(iOS 13, *) {
            let syncEngine = isSyncEnabled ? try? CloudSyncEngine(storageAdapter: storageAdapter) : nil
            self.init(storageAdapter: storageAdapter, syncEngine: syncEngine, isSyncEnabled: isSyncEnabled)
        } else {
            self.init(storageAdapter: storageAdapter, syncEngine: nil, isSyncEnabled: isSyncEnabled)
        }
    }

    func setUp(models: [Model.Type]) throws {
        try storageAdapter.setUp(models: models)
    }

    func save<M: Model>(_ model: M, completion: @escaping DataStoreCallback<M>) {
        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            modelExists = try storageAdapter.exists(M.self, withId: model.id)
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            completion(.failure(dataStoreError))
            return
        }

        let mutationType = modelExists ? MutationEvent.MutationType.update : .create

        let saveMutationEventCompletion: DataStoreCallback<M> = { result in
            guard type(of: model).schema.isSyncable, let syncEngine = self.syncEngine else {
                completion(result)
                return
            }

            guard case .success(let savedModel) = result else {
                completion(result)
                return
            }

            do {
                let mutationEvent = try MutationEvent(model: savedModel, mutationType: mutationType)

                // TODO: Refactor this into something actually readable once we get the final sync implementation done
                if #available(iOS 13, *) {
                    _ = syncEngine
                        .submit(mutationEvent)
                        .sink(
                            receiveCompletion: { futureCompletion in
                                switch futureCompletion {
                                case .failure(let error):
                                    completion(.failure(causedBy: error))
                                default:
                                    // Success case handled by receiveValue
                                    break
                                }

                        }, receiveValue: { _ in
                            completion(.success(savedModel))
                        })
                }
            } catch let dataStoreError as DataStoreError {
                completion(.failure(dataStoreError))
            } catch {
                let dataStoreError = DataStoreError.decodingError(
                    "Could not create MutationEvent from model",
                    """
                    Review the data in the model below and ensure it doesn't contain invalid UTF8 data:

                    \(savedModel)
                    """)
                completion(.failure(dataStoreError))
            }
        }

        storageAdapter.save(model, completion: saveMutationEventCompletion)

    }

    func delete(_ modelType: Model.Type,
                withId id: Model.Identifier,
                completion: (DataStoreResult<Void>) -> Void) {
        storageAdapter.delete(modelType, withId: id, completion: completion)
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate? = nil,
                         completion: DataStoreCallback<[M]>) {
        return storageAdapter.query(modelType, predicate: predicate, completion: completion)
    }

    func startSync() {
        syncEngine?.start(api: Amplify.API)
    }

    func reset(onComplete: () -> Void) {
        // TOOD: Perform cleanup on StorageAdapter, including releasing its `Connection` if needed
        let group = DispatchGroup()
        if #available(iOS 13, *) {

            if let cloudSyncEngine = syncEngine as? CloudSyncEngine {
                group.enter()
                DispatchQueue.global().async {
                    cloudSyncEngine.reset {
                        group.leave()
                    }
                }
            }
        }
        group.wait()
        onComplete()
    }
}

extension StorageEngine: DefaultLogger { }
