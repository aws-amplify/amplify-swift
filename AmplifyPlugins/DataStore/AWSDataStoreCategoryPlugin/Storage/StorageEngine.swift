//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

final class StorageEngine: StorageEngineBehavior {

    // TODO: Make this private once we get a request/response flow with metadata/mutation types figured out
    let storageAdapter: StorageEngineAdapter

    private let isSyncEnabled: Bool

    private var syncEngine: RemoteSyncEngineBehavior?

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
         syncEngine: RemoteSyncEngineBehavior? = nil,
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
            let syncEngine = isSyncEnabled ? try? RemoteSyncEngine(storageAdapter: storageAdapter) : nil
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

        let wrappedCompletion: DataStoreCallback<M> = { result in
            guard type(of: model).schema.isSyncable, let syncEngine = self.syncEngine else {
                completion(result)
                return
            }

            guard case .success(let savedModel) = result else {
                completion(result)
                return
            }

            if #available(iOS 13, *) {
                self.log.verbose("\(#function) syncing mutation for \(savedModel)")
                self.syncMutation(of: savedModel,
                                  mutationType: mutationType,
                                  syncEngine: syncEngine,
                                  completion: completion)
            } else {
                completion(result)
            }
        }

        storageAdapter.save(model, completion: wrappedCompletion)

    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: @escaping (DataStoreResult<Void>) -> Void) {
        let wrappedCompletion: DataStoreCallback<Void> = { result in
            guard modelType.schema.isSyncable, let syncEngine = self.syncEngine else {
                completion(result)
                return
            }

            guard case .success = result else {
                completion(result)
                return
            }

            if #available(iOS 13, *) {
                // TODO: Add a delete-specific APICategory API that allows delete mutations with just sync metadata
                // like type, ID, and version
                self.syncDeletion(of: modelType, withId: id, syncEngine: syncEngine, completion: completion)
            } else {
                completion(result)
            }
        }

        storageAdapter.delete(modelType, withId: id, completion: wrappedCompletion)
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

            if let remoteSyncEngine = syncEngine as? RemoteSyncEngine {
                group.enter()
                DispatchQueue.global().async {
                    remoteSyncEngine.reset {
                        group.leave()
                    }
                }
            }
        }
        group.wait()
        onComplete()
    }

    @available(iOS 13, *)
    private func syncDeletion<M: Model>(of modelType: M.Type,
                                        withId id: Model.Identifier,
                                        syncEngine: RemoteSyncEngineBehavior,
                                        completion: @escaping DataStoreCallback<Void>) {

        let mutationEvent = MutationEvent(id: UUID().uuidString,
                                          modelId: id, modelName: modelType.modelName,
                                          json: "{}",
                                          mutationType: .delete,
                                          createdAt: Date())

        let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let mutationEvent):
                self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                completion(.success(()))
            }
        }

        submitToSyncEngine(mutationEvent: mutationEvent,
                           syncEngine: syncEngine,
                           completion: mutationEventCallback)
    }

    @available(iOS 13, *)
    private func syncMutation<M: Model>(of savedModel: M,
                                        mutationType: MutationEvent.MutationType,
                                        syncEngine: RemoteSyncEngineBehavior,
                                        completion: @escaping DataStoreCallback<M>) {
        let mutationEvent: MutationEvent
        do {
            mutationEvent = try MutationEvent(model: savedModel, mutationType: mutationType)
        } catch {
            let dataStoreError = DataStoreError(error: error)
            completion(.failure(dataStoreError))
            return
        }

        let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let mutationEvent):
                self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                completion(.success(savedModel))
            }
        }

        submitToSyncEngine(mutationEvent: mutationEvent,
                           syncEngine: syncEngine,
                           completion: mutationEventCallback)
    }

    @available(iOS 13, *)
    private func submitToSyncEngine(mutationEvent: MutationEvent,
                                    syncEngine: RemoteSyncEngineBehavior,
                                    completion: @escaping DataStoreCallback<MutationEvent>) {
        var mutationQueueSink: AnyCancellable?
        mutationQueueSink = syncEngine
            .submit(mutationEvent)
            .sink(
                receiveCompletion: { futureCompletion in
                    switch futureCompletion {
                    case .failure(let error):
                        completion(.failure(causedBy: error))
                    case .finished:
                        self.log.verbose("\(#function) Received successful completion")
                    }
                    mutationQueueSink?.cancel()
                    mutationQueueSink = nil

            }, receiveValue: { mutationEvent in
                self.log.verbose("\(#function) saved mutation event: \(mutationEvent)")
                completion(.success(mutationEvent))
            })
    }

}

extension StorageEngine: DefaultLogger { }
