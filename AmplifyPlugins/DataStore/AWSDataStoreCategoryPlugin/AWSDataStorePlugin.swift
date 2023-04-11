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
    var syncEngine: RemoteSyncEngineBehavior? {
        didSet {
            if #available(iOS 13.0, *) {
                syncEngineSink = syncEngine?.publisher.sink(
                    receiveCompletion: self.onReceiveCompletion(completed:),
                    receiveValue: self.onReceiveValue(receiveValue:)
                )
            }
        }
    }

    let initQueue = DispatchQueue(label: "AWSDataStorePlugin.initQueue")
    let initCompletionQueue = DispatchQueue(label: "AWSDataStorePlugin.initCompletionQueue", target: DispatchQueue.global())
    var storageEngineBehaviorFactory: StorageEngineBehaviorFactory

    var syncEngineSink: Any? {
        didSet {
            if #available(iOS 13.0, *), let cancellable = oldValue as? AnyCancellable {
                cancellable.cancel()
            }
        }
    }

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
            StorageEngine.init(dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:) // swiftlint:disable:this line_length
        if #available(iOS 13.0, *) {
            self.dataStorePublisher = DataStorePublisher()
        } else {
            self.dataStorePublisher = nil
        }
        self.dispatchedModelSyncedEvents = [:]
    }

    deinit {
        if #available(iOS 13.0, *), let cancellable = syncEngineSink as? AnyCancellable {
            cancellable.cancel()
        }
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
            StorageEngine.init(dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:) // swiftlint:disable:this line_length
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
        }
        resolveSyncEnabled()
        ModelListDecoderRegistry.registerDecoder(DataStoreListDecoder.self)
    }

    /// Initializes the underlying storage engine
    /// - Returns: success if the engine is successfully initialized or
    ///            a failure with a DataStoreError
    func initStorageEngine() -> Result<StorageEngineBehavior, DataStoreError> {
        initQueue.sync {
            if storageEngine != nil {
                return .success(storageEngine)
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

                return .success(storageEngine)
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
        completion(initStorageEngine()
            .flatMap(initSyncEngine(storageEngine:))
            .map { _ in () }
        )
    }

    func initSyncEngine(storageEngine: StorageEngineBehavior) -> Result<RemoteSyncEngineBehavior?, DataStoreError> {
        initQueue.sync {
            if #available(iOS 13.0, *), syncEngine == nil, isSyncEnabled {
                self.syncEngine = try? RemoteSyncEngine(
                    storageAdapter: storageEngine.storageAdapter,
                    dataStoreConfiguration: dataStoreConfiguration
                )
            }
            storageEngine.syncEngine = self.syncEngine

            if let syncEngine = syncEngine, !syncEngine.isSyncing() {
                return getApiPlugin().flatMap { api in
                    let authPluginRequired = Self.requiresAuthPlugin(api)
                    if authPluginRequired {
                        return getAuthPlugin().map { (api, Optional.some($0)) }
                    } else {
                        return .success((api, Optional.none))
                    }
                }.map { plugins in
                    syncEngine.start(api: plugins.0, auth: plugins.1)
                    self.operationQueue.operations.forEach { operation in
                        if let operation = operation as? DataStoreObserveQueryOperation {
                            operation.startObserveQuery(with: storageEngine)
                        }
                    }
                    return syncEngine
                }
            } else {
                return .success(syncEngine)
            }
        }
    }

    func resolveStorageEngine(dataStoreConfiguration: DataStoreConfiguration) throws {
        guard storageEngine == nil else {
            return
        }

        storageEngine = try storageEngineBehaviorFactory(dataStoreConfiguration,
                                                         validAPIPluginKey,
                                                         validAuthPluginKey,
                                                         modelRegistration.version,
                                                         UserDefaults.standard)
    }

    // MARK: Private

    private func resolveSyncEnabled() {
        if #available(iOS 13.0, *) {
            isSyncEnabled = ModelRegistry.hasSyncableModels
        }
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
    func onReceiveValue(receiveValue: RemoteSyncEngineEvent) {
        guard let dataStorePublisher = self.dataStorePublisher else {
            log.error("Data store publisher not initalized")
            return
        }

        switch receiveValue {
        case .storageAdapterAvailable,
             .subscriptionsPaused,
             .mutationsPaused,
             .clearedStateOutgoingMutations,
             .subscriptionsInitialized,
             .performedInitialSync,
             .subscriptionsActivated,
             .mutationQueueStarted,
             .syncStarted,
             .cleanedUp,
             .cleanedUpForTermination,
             .schedulingRestart: break

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
        if let resettable = syncEngine as? Resettable {
            log.verbose("Resetting syncEngine")
            group.enter()
            resettable.reset {
                self.log.verbose("Resetting syncEngine: finished")
                group.leave()
            }
        }

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

    private func getApiPlugin() -> Result<APICategoryPlugin, DataStoreError> {
        do {
            return .success(try Amplify.API.getPlugin(for: validAPIPluginKey))
        } catch {
            log.error("Unable to find suitable API plugin for syncEngine. syncEngine will not be started")
            return .failure(.configuration(
                "Unable to find suitable API plugin for syncEngine. syncEngine will not be started",
                "Ensure the API category has been setup and configured for your project",
                error)
            )
        }
    }

    private func getAuthPlugin() -> Result<AuthCategoryBehavior, DataStoreError> {
        do {
            return .success(try Amplify.Auth.getPlugin(for: validAuthPluginKey))
        } catch {
            log.error("Unable to find suitable Auth plugin for syncEngine. Models require auth")
            return .failure(.configuration(
                "Unable to find suitable Auth plugin for syncEngine. Models require auth",
                "Ensure the Auth category has been setup and configured for your project",
                error
            ))
        }
    }

}

extension AWSDataStorePlugin: AmplifyVersionable { }

extension AWSDataStorePlugin {
    static func requiresAuthPlugin(_ apiPlugin: APICategoryPlugin) -> Bool {
        let modelsRequireAuthPlugin = ModelRegistry.modelSchemas.contains { schema in
            guard schema.isSyncable  else {
                return false
            }
            return Self.requiresAuthPlugin(apiPlugin, authRules: schema.authRules)
        }

        return modelsRequireAuthPlugin
    }

    static func requiresAuthPlugin(_ apiPlugin: APICategoryPlugin, authRules: [AuthRule]) -> Bool {
        if let rulesRequireAuthPlugin = authRules.requireAuthPlugin {
            return rulesRequireAuthPlugin
        }

        // Fall back to the endpoint's auth type if a determination cannot be made from the auth rules. This can
        // occur for older generation of the auth rules which do not have provider information such as the initial
        // single auth rule use cases. The auth type from the API is used to determine whether or not the auth
        // plugin is required.
        if let awsAPIAuthInfo = apiPlugin as? AWSAPIAuthInformation {
            do {
                return try awsAPIAuthInfo.defaultAuthType().requiresAuthPlugin
            } catch {
                log.error(error: error)
            }
        }

        log.warn("""
            Could not determine whether the auth plugin is required or not. The auth rules present
            may be missing provider information. When this happens, the API Plugin is used to determine
            whether the default auth type requires the auth plugin. The default auth type could not be determined.
        """)

        // If both checks above cannot determine if auth plugin is required, fallback to previous logic
        let apiAuthProvider = (apiPlugin as APICategoryAuthProviderFactoryBehavior).apiAuthProviderFactory()
        if apiAuthProvider.oidcAuthProvider() != nil {
            log.verbose("Found OIDC Auth Provider from the API Plugin.")
            return false
        }

        if apiAuthProvider.functionAuthProvider() != nil {
            log.verbose("Found Function Auth Provider from the API Plugin.")
            return false
        }

        // There are auth rules and no ODIC/Function providers on the API plugin, then return true.
        return true
    }
}
