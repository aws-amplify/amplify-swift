//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import AWSPluginsCore
import Foundation

enum InitStorageEngineResult {
    case successfullyInitialized
    case alreadyInitialized
    case failure(DataStoreError)
}

final public class AWSDataStorePlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "awsDataStorePlugin"

    /// `true` if any models are syncable. Resolved during configuration phase
    var isSyncEnabled: Bool

    /// The listener on hub events unsubscribe token
    var hubListener: UnsubscribeToken?

    /// The Publisher that sends mutation events to subscribers
    var dataStorePublisher: ModelSubcriptionBehavior?

    var dispatchedModelSyncedEvents: [ModelName: AtomicValue<Bool>]

    let modelRegistration: AmplifyModelRegistration

    /// The DataStore configuration
    let dataStoreConfiguration: DataStoreConfiguration

    /// A queue that regulates the execution of operations. This will be instantiated during initalization phase,
    /// and is clearable by `reset()`. This is implicitly unwrapped to be destroyed when resetting.
    var operationQueue: OperationQueue!

    let validAPIPluginKey: String

    let validAuthPluginKey: String

    var storageEngine: StorageEngineBehavior!
    var storageEngineInitQueue = DispatchQueue(label: "AWSDataStorePlugin.storageEngineInitQueue")
    let queue = DispatchQueue(label: "AWSDataStorePlugin.queue", target: DispatchQueue.global())
    var storageEngineBehaviorFactory: StorageEngineBehaviorFactory

    var iStorageEngineSink: Any?
    @available(iOS 13.0, *)
    var storageEngineSink: AnyCancellable? {
        get {
            if let iStorageEngineSink = iStorageEngineSink as? AnyCancellable {
                return iStorageEngineSink
            }
            return nil
        }
        set {
            iStorageEngineSink = newValue
        }
    }

    /// Configuration of the query against the local storage, whether it should load the belongs-to/has-one associations
    /// or not.
    var isEagerLoad: Bool = true

    /// No-argument init that uses defaults for all providers
    public init(modelRegistration: AmplifyModelRegistration,
                configuration dataStoreConfiguration: DataStoreConfiguration = .default) {
        self.modelRegistration = modelRegistration
        self.dataStoreConfiguration = dataStoreConfiguration
        self.isSyncEnabled = false
        self.operationQueue = OperationQueue()
        self.validAPIPluginKey =  "awsAPIPlugin"
        self.validAuthPluginKey = "awsCognitoAuthPlugin"
        self.storageEngineBehaviorFactory =
            StorageEngine.init(isSyncEnabled:dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:)
        if #available(iOS 13.0, *) {
            self.dataStorePublisher = DataStorePublisher()
        } else {
            self.dataStorePublisher = nil
        }
        self.dispatchedModelSyncedEvents = [:]
    }

    /// Internal initializer for testing
    init(modelRegistration: AmplifyModelRegistration,
         configuration dataStoreConfiguration: DataStoreConfiguration = .default,
         storageEngineBehaviorFactory: StorageEngineBehaviorFactory? = nil,
         dataStorePublisher: ModelSubcriptionBehavior,
         operationQueue: OperationQueue = OperationQueue(),
         validAPIPluginKey: String,
         validAuthPluginKey: String) {
        self.modelRegistration = modelRegistration
        self.dataStoreConfiguration = dataStoreConfiguration
        self.operationQueue = operationQueue
        self.isSyncEnabled = false
        self.storageEngineBehaviorFactory = storageEngineBehaviorFactory ??
            StorageEngine.init(isSyncEnabled:dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:)
        self.dataStorePublisher = dataStorePublisher
        self.dispatchedModelSyncedEvents = [:]
        self.validAPIPluginKey = validAPIPluginKey
        self.validAuthPluginKey = validAuthPluginKey
    }

    /// By the time this method gets called, DataStore will already have invoked
    /// `AmplifyModelRegistration.registerModels`, so we can inspect those models to derive isSyncEnabled, and pass
    /// them to `StorageEngine.setUp(modelSchemas:)`
    public func configure(using amplifyConfiguration: Any?) throws {
        modelRegistration.registerModels(registry: ModelRegistry.self)
        for modelSchema in ModelRegistry.modelSchemas {
            dispatchedModelSyncedEvents[modelSchema.name] = AtomicValue(initialValue: false)
            // `isEagerLoad` is true by default, unless the models contain the rootPath
            // which is indication of the codegen that supports for lazy loading.
            if isEagerLoad && ModelRegistry.modelType(from: modelSchema.name)?.rootPath != nil {
                isEagerLoad = false
            }
        }
        resolveSyncEnabled()
        ModelListDecoderRegistry.registerDecoder(DataStoreListDecoder.self)
        ModelProviderRegistry.registerDecoder(DataStoreModelDecoder.self)
    }

    /// Initializes the underlying storage engine
    /// - Returns: success if the engine is successfully initialized or
    ///            a failure with a DataStoreError
    func initStorageEngine() -> InitStorageEngineResult {
        storageEngineInitQueue.sync {
            if storageEngine != nil {
                return .alreadyInitialized
            }

            do {
                if #available(iOS 13.0, *) {
                    if self.dataStorePublisher == nil {
                        self.dataStorePublisher = DataStorePublisher()
                    }
                }
                try resolveStorageEngine(dataStoreConfiguration: dataStoreConfiguration)
                try storageEngine.setUp(modelSchemas: ModelRegistry.modelSchemas)
                try storageEngine.applyModelMigrations(modelSchemas: ModelRegistry.modelSchemas)

                return .successfullyInitialized
            } catch {
                log.error(error: error)
                return .failure(.invalidOperation(causedBy: error))
            }

        }
    }

    /// Initializes the underlying storage engine and starts the syncing process
    /// - Parameter completion: completion handler called with a success if the sync process started
    ///                         or with a DataStoreError in case of failure
    func initStorageEngineAndStartSync(completion: @escaping DataStoreCallback<Void> = { _ in }) {
        if storageEngine != nil {
            completion(.successfulVoid)
            return
        }

        switch initStorageEngine() {
        case .alreadyInitialized:
            completion(.successfulVoid)
        case .successfullyInitialized:
            storageEngine.startSync { result in

                self.operationQueue.operations.forEach { operation in
                    if let operation = operation as? DataStoreObserveQueryOperation {
                        operation.startObserveQuery(with: self.storageEngine)
                    }
                }
                completion(result)
            }
        case .failure(let error):
            completion(.failure(causedBy: error))
        }
    }

    func resolveStorageEngine(dataStoreConfiguration: DataStoreConfiguration) throws {
        guard storageEngine == nil else {
            return
        }

        storageEngine = try storageEngineBehaviorFactory(isSyncEnabled,
                                                         dataStoreConfiguration,
                                                         validAPIPluginKey,
                                                         validAuthPluginKey,
                                                         modelRegistration.version,
                                                         UserDefaults.standard)

        if #available(iOS 13.0, *) {
            setupStorageSink()
        }
    }

    // MARK: Private

    private func resolveSyncEnabled() {
        if #available(iOS 13.0, *) {
            isSyncEnabled = ModelRegistry.hasSyncableModels
        }
    }

    @available(iOS 13.0, *)
    private func setupStorageSink() {
        storageEngineSink = storageEngine
            .publisher
            .sink(
                receiveCompletion: { [weak self] in self?.onReceiveCompletion(completed: $0) },
                receiveValue: { [weak self] in self?.onReceiveValue(receiveValue: $0) }
            )
    }

    @available(iOS 13.0, *)
    private func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        switch completed {
        case .failure(let dataStoreError):
            log.error("StorageEngine completed with error: \(dataStoreError)")
        case .finished:
            break
        }
        stop { result in
            switch result {
            case .success:
                self.log.info("Stopping DataStore successful.")
                return
            case .failure(let error):
                self.log.error("Failed to stop StorageEngine with error: \(error)")
            }
        }
    }

    @available(iOS 13.0, *)
    func onReceiveValue(receiveValue: StorageEngineEvent) {
        guard let dataStorePublisher = self.dataStorePublisher else {
            log.error("Data store publisher not initalized")
            return
        }

        switch receiveValue {
        case .started:
            break
        case .mutationEvent(let mutationEvent):
            dataStorePublisher.send(input: mutationEvent)
        case .modelSyncedEvent(let modelSyncedEvent):
            log.verbose("Emitting DataStore event: modelSyncedEvent \(modelSyncedEvent)")
            dispatchedModelSyncedEvents[modelSyncedEvent.modelName]?.set(true)
            let modelSyncedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                                     data: modelSyncedEvent)
            Amplify.Hub.dispatch(to: .dataStore, payload: modelSyncedEventPayload)
        case .syncQueriesReadyEvent:
            log.verbose("[Lifecycle event 4]: syncQueriesReady")
            let syncQueriesReadyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
            Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyEventPayload)
        case .readyEvent:
            log.verbose("[Lifecycle event 6]: ready")
            let readyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.ready)
            Amplify.Hub.dispatch(to: .dataStore, payload: readyEventPayload)
        }
    }

    public func reset(onComplete: @escaping (() -> Void)) {
        if operationQueue != nil {
            operationQueue = nil
        }
        dispatchedModelSyncedEvents = [:]
        if let listener = hubListener {
            Amplify.Hub.removeListener(listener)
            hubListener = nil
        }
        let group = DispatchGroup()
        if let resettable = storageEngine as? Resettable {
            log.verbose("Resetting storageEngine")
            group.enter()
            resettable.reset {
                self.log.verbose("Resetting storageEngine: finished")
                group.leave()
            }
        }

        group.wait()
        onComplete()
    }

}

extension AWSDataStorePlugin: AmplifyVersionable { }
