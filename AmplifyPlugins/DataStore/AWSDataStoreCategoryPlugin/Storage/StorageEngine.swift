//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

typealias StorageEngineBehaviorFactory =
    (Bool,
    DataStoreConfiguration,
    String,
    String,
    String,
    UserDefaults) throws -> StorageEngineBehavior

// swiftlint:disable type_body_length
final class StorageEngine: StorageEngineBehavior {

    // TODO: Make this private once we get a mutation flow that passes the type of mutation as needed
    let storageAdapter: StorageEngineAdapter
    var syncEngine: RemoteSyncEngineBehavior?
    let validAPIPluginKey: String
    let validAuthPluginKey: String
    var signInListener: UnsubscribeToken?

    private let dataStoreConfiguration: DataStoreConfiguration
    private let serialQueueSyncDeletions: DispatchQueue

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

    static var systemModelSchemas: [ModelSchema] {
        return [
            ModelSyncMetadata.schema,
            MutationEvent.schema,
            MutationSyncMetadata.schema
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
        self.serialQueueSyncDeletions = DispatchQueue(label: "com.amazoncom.StorageEngine.syncDeletions.concurrency")
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

        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
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

    func setUp(modelSchemas: [ModelSchema]) throws {
        try storageAdapter.setUp(modelSchemas: modelSchemas)
    }

    public func save<M: Model>(_ model: M,
                               modelSchema: ModelSchema,
                               condition: QueryPredicate? = nil,
                               completion: @escaping DataStoreCallback<M>) {

        // TODO: Refactor this into a proper request/result where the result includes metadata like the derived
        // mutation type
        let modelExists: Bool
        do {
            modelExists = try storageAdapter.exists(modelSchema, withId: model.id, predicate: nil)
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
            guard modelSchema.isSyncable, let syncEngine = self.syncEngine else {
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
                                  modelSchema: modelSchema,
                                  mutationType: mutationType,
                                  predicate: condition,
                                  syncEngine: syncEngine,
                                  completion: completion)
            } else {
                completion(result)
            }
        }

        storageAdapter.save(model,
                            modelSchema: modelSchema,
                            condition: condition,
                            completion: wrappedCompletion)
    }

    func save<M: Model>(_ model: M, condition: QueryPredicate? = nil, completion: @escaping DataStoreCallback<M>) {
        save(model, modelSchema: model.schema, condition: condition, completion: completion)
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          predicate: QueryPredicate? = nil,
                          completion: @escaping (DataStoreResult<M?>) -> Void) {
        var deleteInput = DeleteInput.withId(id: id)
        if let predicate = predicate {
            deleteInput = .withIdAndPredicate(id: id, predicate: predicate)
        }
        let transactionResult = queryAndDeleteTransaction(modelType,
                                                          modelSchema: modelSchema,
                                                          deleteInput: deleteInput)
        let modelsFromTransactionResult = collapseMResult(transactionResult)
        let associatedModelsFromTransactionResult = resolveAssociatedModels(transactionResult)

        let deletedModel: M
        switch modelsFromTransactionResult {
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

        guard modelSchema.isSyncable, let syncEngine = self.syncEngine else {
            if !modelSchema.isSystem {
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
            self.syncDeletions(of: modelType,
                               modelSchema: modelSchema,
                               withModels: [deletedModel],
                               associatedModels: associatedModelsFromTransactionResult,
                               syncEngine: syncEngine,
                               completion: syncCompletionWrapper)
        } else {
            completion(.success(deletedModel))
        }
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        let transactionResult = queryAndDeleteTransaction(modelType,
                                                          modelSchema: modelSchema,
                                                          deleteInput: .withPredicate(predicate: predicate))
        let modelsFromTransactionResult = collapseMResult(transactionResult)
        let associatedModelsFromTransactionResult = resolveAssociatedModels(transactionResult)

        guard modelSchema.isSyncable, let syncEngine = self.syncEngine else {
            if !modelSchema.isSystem {
                log.error("Unable to sync model (\(modelSchema.name)) where isSyncable is false")
            }
            if self.syncEngine == nil {
                log.error("Unable to sync because syncEngine is nil")
            }
            completion(modelsFromTransactionResult)
            return
        }

        guard case .success(let queriedModels) = modelsFromTransactionResult else {
            completion(modelsFromTransactionResult)
            return
        }

        if #available(iOS 13.0, *) {
            let syncCompletionWrapper: DataStoreCallback<Void> = { syncResult in
                switch syncResult {
                case .success:
                    completion(modelsFromTransactionResult)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            if queriedModels.isEmpty {
                completion(modelsFromTransactionResult)
            } else {
                self.syncDeletions(of: modelType,
                                   modelSchema: modelSchema,
                                   withModels: queriedModels,
                                   predicate: predicate,
                                   associatedModels: associatedModelsFromTransactionResult,
                                   syncEngine: syncEngine,
                                   completion: syncCompletionWrapper)
            }
        } else {
            completion(modelsFromTransactionResult)
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        return storageAdapter.query(modelType,
                                    modelSchema: modelSchema,
                                    predicate: predicate,
                                    sort: sort,
                                    paginationInput: paginationInput,
                                    completion: completion)
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate? = nil,
                         sort: [QuerySortDescriptor]? = nil,
                         paginationInput: QueryPaginationInput? = nil,
                         completion: DataStoreCallback<[M]>) {
        query(modelType,
              modelSchema: modelType.schema,
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

    func stopSync(completion: @escaping DataStoreCallback<Void>) {
        if let syncEngine = syncEngine {
            syncEngine.stop { _ in
                completion(.successfulVoid)
            }
        } else {
            completion(.successfulVoid)
        }
    }

    @available(iOS 13.0, *)
    private func syncDeletions<M: Model>(of modelType: M.Type,
                                         modelSchema: ModelSchema,
                                         withModels models: [M],
                                         predicate: QueryPredicate? = nil,
                                         associatedModels: [ModelName: [Model]],
                                         syncEngine: RemoteSyncEngineBehavior,
                                         completion: @escaping DataStoreCallback<Void>) {
        var graphQLFilterJSON: String?
        if let predicate = predicate {
            do {
                graphQLFilterJSON = try GraphQLFilterConverter.toJSON(predicate,
                                                                      modelSchema: modelSchema)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }
        }
        var mutationEventsSubmitCompleted = 0
        var savedDataStoreError: DataStoreError?
        for model in models {
            let mutationEvent: MutationEvent
            do {
                mutationEvent = try MutationEvent(model: model,
                                                  modelSchema: modelSchema,
                                                  mutationType: .delete,
                                                  graphQLFilterJSON: graphQLFilterJSON)
            } catch {
                let dataStoreError = DataStoreError(error: error)
                completion(.failure(dataStoreError))
                return
            }

            let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
                self.serialQueueSyncDeletions.async {
                    mutationEventsSubmitCompleted += 1
                    switch result {
                    case .failure(let dataStoreError):
                        self.log.error("\(#function) failed to submit to sync engine \(mutationEvent)")
                        if savedDataStoreError == nil {
                            savedDataStoreError = dataStoreError
                        }
                    case .success:
                        self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                    }
                    if mutationEventsSubmitCompleted == models.count {
                        self.syncDeletions(of: associatedModels,
                                           syncEngine: syncEngine,
                                           dataStoreError: savedDataStoreError,
                                           completion: completion)
                    }
                }
            }

            submitToSyncEngine(mutationEvent: mutationEvent,
                               syncEngine: syncEngine,
                               completion: mutationEventCallback)
        }
    }

    @available(iOS 13.0, *)
    private func syncDeletions(of associatedModelsMap: [ModelName: [Model]],
                               syncEngine: RemoteSyncEngineBehavior,
                               dataStoreError: DataStoreError?,
                               completion: @escaping DataStoreCallback<Void>) {
        guard !associatedModelsMap.isEmpty else {
            if let savedDataStoreError = dataStoreError {
                completion(.failure(savedDataStoreError))
            } else {
                completion(.successfulVoid)
            }
            return
        }

        var mutationEventsSubmitCompleted = 0
        let associatedModelsCount = associatedModelsMap.values.reduce(0) { totalCount, models in
            totalCount + models.count
        }
        var savedDataStoreError = dataStoreError
        for (modelName, associatedModels) in associatedModelsMap {
            for associatedModel in associatedModels {
                let mutationEvent: MutationEvent
                do {
                    mutationEvent = try MutationEvent(untypedModel: associatedModel,
                                                      modelName: modelName,
                                                      mutationType: .delete)
                } catch {
                    let dataStoreError = DataStoreError(error: error)
                    completion(.failure(dataStoreError))
                    return
                }

                let mutationEventCallback: DataStoreCallback<MutationEvent> = { result in
                    self.serialQueueSyncDeletions.async {
                        mutationEventsSubmitCompleted += 1
                        switch result {
                        case .failure(let dataStoreError):
                            self.log.error("\(#function) failed to submit to sync engine \(mutationEvent)")
                            if savedDataStoreError == nil {
                                savedDataStoreError = dataStoreError
                            }
                        case .success(let mutationEvent):
                            self.log.verbose("\(#function) successfully submitted to sync engine \(mutationEvent)")
                        }
                        if mutationEventsSubmitCompleted == associatedModelsCount {
                            if let lastEmittedDataStoreError = savedDataStoreError {
                                completion(.failure(lastEmittedDataStoreError))
                            } else {
                                completion(.successfulVoid)
                            }
                        }
                    }
                }
                submitToSyncEngine(mutationEvent: mutationEvent,
                                   syncEngine: syncEngine,
                                   completion: mutationEventCallback)
            }
        }
    }

    @available(iOS 13.0, *)
    private func syncMutation<M: Model>(of savedModel: M,
                                        modelSchema: ModelSchema,
                                        mutationType: MutationEvent.MutationType,
                                        predicate: QueryPredicate? = nil,
                                        syncEngine: RemoteSyncEngineBehavior,
                                        completion: @escaping DataStoreCallback<M>) {
        let mutationEvent: MutationEvent
        do {
            var graphQLFilterJSON: String?
            if let predicate = predicate {
                graphQLFilterJSON = try GraphQLFilterConverter.toJSON(predicate,
                                                                      modelSchema: modelSchema)
            }

            mutationEvent = try MutationEvent(model: savedModel,
                                              modelSchema: modelSchema,
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

extension StorageEngine: Resettable {
    func reset(onComplete: @escaping BasicClosure) {
        // TOOD: Perform cleanup on StorageAdapter, including releasing its `Connection` if needed
        let group = DispatchGroup()
        if #available(iOS 13.0, *), let resettable = syncEngine as? Resettable {
            log.verbose("Resetting syncEngine")
            group.enter()
            resettable.reset {
                self.log.verbose("Resetting syncEngine: finished")
                group.leave()
            }
        }

        group.wait()
        onComplete()
    }
}

extension StorageEngine: DefaultLogger { }
