//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

final class StorageEngine: StorageEngineBehavior {
    // TODO: Make this private once we get a mutation flow that passes the type of mutation as needed
    let storageAdapter: StorageEngineAdapter

    private var syncEngine: RemoteSyncEngineBehavior?

    private weak var api: APICategoryGraphQLBehavior?

    var iSyncEngineSink: Any?
    @available(iOS 13.0, *)
    var sinkEngineSink: AnyCancellable? {
        get {
            if let iSyncEngineSink = iSyncEngineSink as? AnyCancellable {
                return iSyncEngineSink
            }
            return nil
        }
        set {
            iSyncEngineSink = newValue
        }
    }

    var iStorageEnginePublisher: Any?
    @available(iOS 13.0, *)
    var storageEnginePublisher: PassthroughSubject<StorageEngineEvent, DataStoreError> {
        get {
            if iStorageEnginePublisher == nil {
                iStorageEnginePublisher = PassthroughSubject<StorageEngineEvent, DataStoreError>()
            }
            return iStorageEnginePublisher as! PassthroughSubject<StorageEngineEvent, DataStoreError> // swiftlint:disable:this force_cast
        }
        set {
            iStorageEnginePublisher = newValue
        }
    }

    @available(iOS 13.0, *)
    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> {
        return storageEnginePublisher.eraseToAnyPublisher()
    }

    static var systemModels: [Model.Type] {
        return [
            ModelSyncMetadata.self,
            MutationEvent.self,
            MutationSyncMetadata.self
        ]
    }

    // Internal initializer used for testing, to allow lazy initialization of the SyncEngine. Note that the provided
    // storageAdapter must have already been set up with system models
    init(storageAdapter: StorageEngineAdapter,
         syncEngine: RemoteSyncEngineBehavior?) {
        self.storageAdapter = storageAdapter
        self.syncEngine = syncEngine
    }

    convenience init(isSyncEnabled: Bool) throws {
        let key = kCFBundleNameKey as String
        let databaseName = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let storageAdapter = try SQLiteStorageEngineAdapter(databaseName: databaseName ?? "app")

        try storageAdapter.setUp(models: StorageEngine.systemModels)
        if #available(iOS 13.0, *) {
            let syncEngine = isSyncEnabled ? try? RemoteSyncEngine(storageAdapter: storageAdapter) : nil
            self.init(storageAdapter: storageAdapter, syncEngine: syncEngine)
            self.storageEnginePublisher = PassthroughSubject<StorageEngineEvent, DataStoreError>()
            sinkEngineSink = syncEngine?.publisher.sink(receiveCompletion: onReceiveCompletion(receiveCompletion:),
                                                        receiveValue: onReceive(receiveValue:))
        } else {
            self.init(storageAdapter: storageAdapter, syncEngine: nil)
        }
    }

    @available(iOS 13.0, *)
    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        switch receiveCompletion {
        case .failure(let dataStoreError):
            storageEnginePublisher.send(completion: .failure(dataStoreError))
        case .finished:
            storageEnginePublisher.send(completion: .finished)
        }
    }

    @available(iOS 13.0, *)
    private func onReceive(receiveValue: RemoteSyncEngineEvent) {
        if case .mutationEvent(let mutationEvent) = receiveValue {
            self.storageEnginePublisher.send(.mutationEvent(mutationEvent))
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

            if #available(iOS 13.0, *) {
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
                if !modelType.schema.isSystem {
                    self.log.error("Unable to sync modelType (\(modelType)) where isSyncable is false")
                }
                if self.syncEngine == nil {
                    self.log.error("Unable to sync because syncEngine is nil")
                }
                completion(result)
                return
            }

            guard case .success = result else {
                completion(result)
                return
            }

            if #available(iOS 13.0, *) {
                // TODO: Add a delete-specific APICategory API that allows delete mutations with just sync metadata
                // like type, ID, and version
                self.syncDeletion(of: modelType, withId: id, syncEngine: syncEngine, completion: completion)
            } else {
                completion(result)
            }
        }

        storageAdapter.delete(modelType, withId: id, completion: wrappedCompletion)
    }

    func delete<M: Model>(_ modelType: M.Type,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        var queriedResult: DataStoreResult<[M]>?
        var deletedResult: DataStoreResult<[M]>?

        let queryCompletionBlock: DataStoreCallback<[M]> = { queryResult in
            queriedResult = queryResult
            if case .success = queryResult {
                let deleteCompletionWrapper: DataStoreCallback<[M]> = { deleteResult in
                    deletedResult = deleteResult
                }
                self.storageAdapter.delete(modelType, predicate: predicate, completion: deleteCompletionWrapper)
            }
        }

        do {
            try storageAdapter.transaction {
                storageAdapter.query(modelType,
                                     predicate: predicate,
                                     additionalStatements: nil,
                                     completion: queryCompletionBlock)
            }
        } catch {
            completion(.failure(causedBy: error))
            return
        }

        let transactionResult = collapseResults(queryResult: queriedResult, deleteResult: deletedResult)

        guard modelType.schema.isSyncable, let syncEngine = self.syncEngine else {
            if !modelType.schema.isSystem {
                log.error("Unable to sync modelType (\(modelType)) where isSyncable is false")
            }
            if self.syncEngine == nil {
                log.error("Unable to sync because syncEngine is nil")
            }
            completion(transactionResult)
            return
        }

        guard case .success(let queriedModels) = transactionResult else {
            completion(transactionResult)
            return
        }

        if #available(iOS 13.0, *) {
            let syncCompletionWrapper: DataStoreCallback<Void> = { syncResult in
                switch syncResult {
                case .success:
                    completion(transactionResult)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            let modelIds = queriedModels.map { $0.id }
            if modelIds.isEmpty {
                completion(transactionResult)
            } else {
                self.syncDeletions(of: modelType,
                                   withModelIds: modelIds,
                                   syncEngine: syncEngine,
                                   completion: syncCompletionWrapper)
            }
        } else {
            completion(transactionResult)
        }
    }

    private func collapseResults<M: Model>(queryResult: DataStoreResult<[M]>?,
                                           deleteResult: DataStoreResult<[M]>?) -> DataStoreResult<[M]> {
        if let queryResult = queryResult {
            switch queryResult {
            case .success(let models):
                if let deleteResult = deleteResult {
                    switch deleteResult {
                    case .success:
                        return .success(models)
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    return .failure(.unknown("deleteResult not set during transaction", "coding error", nil))
                }
            case .failure(let error):
                return .failure(error)
            }
        } else {
            return .failure(.unknown("queryResult not set during transaction", "coding error", nil))
        }
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
        if #available(iOS 13.0, *) {

            if let resettable = syncEngine as? Resettable {
                group.enter()
                DispatchQueue.global().async {
                    resettable.reset {
                        group.leave()
                    }
                }
            }
        }
        group.wait()
        onComplete()
    }

    @available(iOS 13.0, *)
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
                completion(.successfulVoid)
            }
        }

        submitToSyncEngine(mutationEvent: mutationEvent,
                           syncEngine: syncEngine,
                           completion: mutationEventCallback)
    }

    @available(iOS 13.0, *)
    //Note: this function looks a lot like syncDeletion, but will change when
    // we start to pass in the predicate
    private func syncDeletions<M: Model>(of modelType: M.Type,
                                         withModelIds modelIds: [Model.Identifier],
                                         syncEngine: RemoteSyncEngineBehavior,
                                         completion: @escaping DataStoreCallback<Void>) {
        var mutationEvents: Set<Model.Identifier> = []

        for modelId in modelIds {
            let mutationEvent = MutationEvent(id: UUID().uuidString,
                                              modelId: modelId,
                                              modelName: modelType.modelName,
                                              json: "{}",
                                              mutationType: .delete,
                                              createdAt: Date())

            let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
                switch result {
                case .failure(let dataStoreError):
                    completion(.failure(dataStoreError))
                case .success(let mutationEvent):
                    mutationEvents.insert(mutationEvent.modelId)
                    self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                    if mutationEvents.count == modelIds.count {
                        completion(.successfulVoid)
                    }
                }
            }

            submitToSyncEngine(mutationEvent: mutationEvent,
                               syncEngine: syncEngine,
                               completion: mutationEventCallback)
        }
    }

    @available(iOS 13.0, *)
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

    @available(iOS 13.0, *)
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
