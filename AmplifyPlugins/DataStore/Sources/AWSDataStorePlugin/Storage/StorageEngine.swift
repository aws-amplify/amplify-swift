//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(OptionalExtension) import Amplify
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
    private let operationQueue: OperationQueue

    var iSyncEngineSink: Any?
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

        let operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.StorageEngine"
        self.operationQueue = operationQueue
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
    }

    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        switch receiveCompletion {
        case .failure(let dataStoreError):
            storageEnginePublisher.send(completion: .failure(dataStoreError))
        case .finished:
            storageEnginePublisher.send(completion: .finished)
        }
    }

    func onReceive(receiveValue: RemoteSyncEngineEvent) {
        switch receiveValue {
        case .storageAdapterAvailable:
            break
        case .subscriptionsPaused:
            break
        case .mutationsPaused:
            break
        case .clearedStateOutgoingMutations:
            break
        case .subscriptionsInitialized:
            break
        case .performedInitialSync:
            break
        case .subscriptionsActivated:
            break
        case .mutationQueueStarted:
            break
        case .syncStarted:
            break
        case .cleanedUp:
            break
        case .cleanedUpForTermination:
            break
        case .mutationEvent(let mutationEvent):
            storageEnginePublisher.send(.mutationEvent(mutationEvent))
        case .modelSyncedEvent(let modelSyncedEvent):
            storageEnginePublisher.send(.modelSyncedEvent(modelSyncedEvent))
        case .syncQueriesReadyEvent:
            storageEnginePublisher.send(.syncQueriesReadyEvent)
        case .readyEvent:
            storageEnginePublisher.send(.readyEvent)
        case .schedulingRestart:
            break
        }
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
        try storageAdapter.setUp(modelSchemas: modelSchemas)
    }

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws {
        try storageAdapter.applyModelMigrations(modelSchemas: modelSchemas)
    }

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M?, DataStoreError> {
        storageAdapter.query(
            modelType,
            modelSchema: modelSchema,
            withIdentifier: identifier,
            condition: condition,
            eagerLoad: eagerLoad
        )
    }

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate? = nil,
        sort: [QuerySortDescriptor]? = nil,
        paginationInput: QueryPaginationInput? = nil,
        eagerLoad: Bool = true
    ) -> Swift.Result<[M], DataStoreError> {
        storageAdapter.query(
            modelType,
            modelSchema: modelSchema,
            condition: condition,
            sort: sort,
            paginationInput: paginationInput,
            eagerLoad: eagerLoad
        )
    }

    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) async -> Swift.Result<(M, MutationEvent.MutationType), DataStoreError> {
        storageAdapter.save(
            model,
            modelSchema: modelSchema,
            condition: condition,
            eagerLoad: eagerLoad
        ).flatMap { result in
            let (savedModel, mutationType) = result
            return createMutationEvent(savedModel, modelSchema: modelSchema, mutationType: mutationType)
                .flatMap { mutationEvent in
                    submitToSyncEngine(mutationEvent: mutationEvent, syncEngine: syncEngine)
                }
                .map { _ in result }
        }
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) async -> Swift.Result<M?, DataStoreError> {
        do {
            var result: Swift.Result<M?, DataStoreError> = .failure(.unknown(
                "Default failure for cascade deletion",
                "The delete operation failed to execute"
            ))
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let cascadeDeleteOperation = CascadeDeleteOperation(
                    storageAdapter: storageAdapter,
                    syncEngine: syncEngine,
                    modelType: modelType,
                    modelSchema: modelSchema,
                    withIdentifier: identifier,
                    condition: condition) {
                        result = $0
                        continuation.resume()
                    }
                operationQueue.addOperation(cascadeDeleteOperation)
            }
            return result
        } catch {
            return .failure(DataStoreError(error: error))
        }
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate
    ) async -> Swift.Result<[M], DataStoreError> {
        do {
           var result: Swift.Result<[M], DataStoreError> = .failure(.unknown(
               "Default failure for cascade deletion",
               "The delete operation failed to execute"
           ))
           try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
               let cascadeDeleteOperation = CascadeDeleteOperation(
                   storageAdapter: storageAdapter,
                   syncEngine: syncEngine,
                   modelType: modelType,
                   modelSchema: modelSchema,
                   filter: condition) {
                       result = $0
                       continuation.resume()
                   }
               operationQueue.addOperation(cascadeDeleteOperation)
           })
           return result
       } catch {
           return .failure(DataStoreError(error: error))
       }
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

    private func createMutationEvent<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        mutationType: MutationEvent.MutationType,
        predicate: QueryPredicate? = nil
    ) -> Swift.Result<MutationEvent?, DataStoreError> {
        do {
            if modelSchema.isSyncable {
                let graphQLFilterJSON = try predicate.map {
                    try GraphQLFilterConverter.toJSON($0, modelSchema: modelSchema)
                }
                return .success(try MutationEvent(
                    model: model,
                    modelSchema: modelSchema,
                    mutationType: mutationType,
                    graphQLFilterJSON: graphQLFilterJSON
                ))
            } else {
                return .success(nil)
            }
        } catch {
            return .failure(DataStoreError(error: error))
        }
    }

    private func submitToSyncEngine(
        mutationEvent: MutationEvent?,
        syncEngine: RemoteSyncEngineBehavior?
    ) -> Swift.Result<Void, DataStoreError> {
        if let mutationEvent = mutationEvent, let syncEngine = syncEngine {
            return syncEngine.submit(mutationEvent).dropSuccessValue()
        } else {
            return .success(())
        }
    }

}

extension StorageEngine: Resettable {
    func reset() async {
        // TOOD: Perform cleanup on StorageAdapter, including releasing its `Connection` if needed
        if let resettable = syncEngine as? Resettable {
            log.verbose("Resetting syncEngine")
            await resettable.reset()
            self.log.verbose("Resetting syncEngine: finished")
        }
    }
}

extension StorageEngine: DefaultLogger { }
