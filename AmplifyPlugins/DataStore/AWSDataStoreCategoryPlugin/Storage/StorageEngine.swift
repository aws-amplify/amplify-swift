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

// swiftlint:disable type_body_length
final class StorageEngine: StorageEngineBehavior {
    // TODO: Make this private once we get a mutation flow that passes the type of mutation as needed
    let storageAdapter: StorageEngineAdapter
    private let dataStoreConfiguration: DataStoreConfiguration
    var syncEngine: RemoteSyncEngineBehavior?
    let validAPIPluginKey: String
    let validAuthPluginKey: String
    var signInListener: UnsubscribeToken?

    var iSyncEngineSink: Any?
    @available(iOS 13.0, *)
    var syncEngineSink: AnyCancellable? {
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
            // swiftlint:disable:next force_cast
            return iStorageEnginePublisher as! PassthroughSubject<StorageEngineEvent, DataStoreError>
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
         dataStoreConfiguration: DataStoreConfiguration,
         syncEngine: RemoteSyncEngineBehavior?,
         validAPIPluginKey: String,
         validAuthPluginKey: String) {
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        self.syncEngine = syncEngine
        self.validAPIPluginKey = validAPIPluginKey
        self.validAuthPluginKey = validAuthPluginKey
    }

    convenience init(isSyncEnabled: Bool,
                     dataStoreConfiguration: DataStoreConfiguration,
                     validAPIPluginKey: String = "awsAPIPlugin",
                     validAuthPluginKey: String = "awsCognitoAuthPlugin",
                     modelRegistryVersion: String,
                     userDefault: UserDefaults = UserDefaults.standard) throws {

        let key = kCFBundleNameKey as String
        let databaseName = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "app"

        let storageAdapter = try SQLiteStorageEngineAdapter(version: modelRegistryVersion, databaseName: databaseName)

        try storageAdapter.setUp(models: StorageEngine.systemModels)
        if #available(iOS 13.0, *) {
            let syncEngine = isSyncEnabled ? try? RemoteSyncEngine(storageAdapter: storageAdapter,
                                                                   dataStoreConfiguration: dataStoreConfiguration) : nil
            self.init(storageAdapter: storageAdapter,
                      dataStoreConfiguration: dataStoreConfiguration,
                      syncEngine: syncEngine,
                      validAPIPluginKey: validAPIPluginKey,
                      validAuthPluginKey: validAuthPluginKey)
            self.storageEnginePublisher = PassthroughSubject<StorageEngineEvent, DataStoreError>()
            syncEngineSink = syncEngine?.publisher.sink(receiveCompletion: onReceiveCompletion(receiveCompletion:),
                                                        receiveValue: onReceive(receiveValue:))
        } else {
            self.init(storageAdapter: storageAdapter,
                      dataStoreConfiguration: dataStoreConfiguration,
                      syncEngine: nil,
                      validAPIPluginKey: validAPIPluginKey,
                      validAuthPluginKey: validAuthPluginKey)
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

    func save<M: Model>(_ model: M, condition: QueryPredicate? = nil, completion: @escaping DataStoreCallback<M>) {
        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            modelExists = try storageAdapter.exists(M.self, withId: model.id, predicate: nil)
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            completion(.failure(dataStoreError))
            return
        }

        let mutationType = modelExists ? MutationEvent.MutationType.update : .create

        if mutationType == .create && condition != nil {
            let dataStoreError = DataStoreError.invalidCondition(
                "Cannot apply a condition on model which does not exist.",
                "Save the model instance without a condition first.")
            completion(.failure(causedBy: dataStoreError))
        }

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
                                  predicate: condition,
                                  syncEngine: syncEngine,
                                  completion: completion)
            } else {
                completion(result)
            }
        }

        storageAdapter.save(model, condition: condition, completion: wrappedCompletion)
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: @escaping (DataStoreResult<M?>) -> Void) {
        let transactionResult = queryAndDeleteTransaction(modelType, predicate: field("id").eq(id))

        let deletedModel: M
        switch transactionResult {
        case .success(let queriedModels):
            guard queriedModels.count <= 1 else {
                completion(.failure(.unknown("delete with id returned more than one result", "", nil)))
                return
            }

            guard let first = queriedModels.first else {
                completion(.success(nil))
                return
            }
            deletedModel = first
        case .failure(let error):
            completion(.failure(error))
            return
        }

        guard modelType.schema.isSyncable, let syncEngine = self.syncEngine else {
            if !modelType.schema.isSystem {
                log.error("Unable to sync modelType (\(modelType)) where isSyncable is false")
            }
            if self.syncEngine == nil {
                log.error("Unable to sync because syncEngine is nil")
            }
            completion(.success(deletedModel))
            return
        }

        if #available(iOS 13.0, *) {
            let syncCompletionWrapper: DataStoreCallback<Void> = { syncResult in
                switch syncResult {
                case .success:
                    completion(.success(deletedModel))
                case .failure(let error):
                    completion(.failure(error))
                }
            }

            self.syncDeletion(with: deletedModel,
                              syncEngine: syncEngine,
                              completion: syncCompletionWrapper)

        } else {
            completion(.success(deletedModel))
        }
    }

    func delete<M: Model>(_ modelType: M.Type,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        let transactionResult = queryAndDeleteTransaction(modelType, predicate: predicate)

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
            if queriedModels.isEmpty {
                completion(transactionResult)
            } else {
                self.syncDeletions(of: modelType,
                                   withModels: queriedModels,
                                   predicate: predicate,
                                   syncEngine: syncEngine,
                                   completion: syncCompletionWrapper)
            }
        } else {
            completion(transactionResult)
        }
    }

    private func queryAndDeleteTransaction<M: Model>(_ modelType: M.Type,
                                                     predicate: QueryPredicate) -> DataStoreResult<[M]> {
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
                                     sort: nil,
                                     paginationInput: nil,
                                     completion: queryCompletionBlock)
            }
        } catch {
            return .failure(causedBy: error)
        }

        return collapseResults(queryResult: queriedResult, deleteResult: deletedResult)
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
                         sort: QuerySortInput? = nil,
                         paginationInput: QueryPaginationInput? = nil,
                         completion: DataStoreCallback<[M]>) {
        return storageAdapter.query(modelType,
                                    predicate: predicate,
                                    sort: sort,
                                    paginationInput: paginationInput,
                                    completion: completion)
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        if let syncEngine = syncEngine {
            syncEngine.stop(completion: { _ in
                self.storageAdapter.clear(completion: completion)
            })
        } else {
            storageAdapter.clear(completion: completion)
        }
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
    private func syncDeletion<M: Model>(with model: M,
                                        syncEngine: RemoteSyncEngineBehavior,
                                        completion: @escaping DataStoreCallback<Void>) {

        let mutationEvent: MutationEvent
        do {
            mutationEvent = try MutationEvent(model: model,
                                              mutationType: .delete)
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
                                         withModels models: [M],
                                         predicate: QueryPredicate? = nil,
                                         syncEngine: RemoteSyncEngineBehavior,
                                         completion: @escaping DataStoreCallback<Void>) {
        var mutationEvents: Set<Model.Identifier> = []

        var graphQLFilterJSON: String?
        if let predicate = predicate {
            do {
                graphQLFilterJSON = try GraphQLFilterConverter.toJSON(predicate)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }
        }

        for model in models {
            let mutationEvent: MutationEvent
            do {
                mutationEvent = try  MutationEvent(model: model,
                                                  mutationType: .delete,
                                                  graphQLFilterJSON: graphQLFilterJSON)
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
                    mutationEvents.insert(mutationEvent.modelId)
                    self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                    if mutationEvents.count == models.count {
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
                                        predicate: QueryPredicate? = nil,
                                        syncEngine: RemoteSyncEngineBehavior,
                                        completion: @escaping DataStoreCallback<M>) {
        let mutationEvent: MutationEvent
        do {
            var graphQLFilterJSON: String?
            if let predicate = predicate {
                graphQLFilterJSON = try GraphQLFilterConverter.toJSON(predicate)
            }

            mutationEvent = try MutationEvent(model: savedModel,
                                              mutationType: mutationType,
                                              graphQLFilterJSON: graphQLFilterJSON)

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
