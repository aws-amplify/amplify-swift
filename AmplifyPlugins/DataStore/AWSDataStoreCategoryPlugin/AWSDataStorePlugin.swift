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

final public class AWSDataStorePlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "awsDataStorePlugin"

    /// `true` if any models are syncable. Resolved during configuration phase
    var isSyncEnabled: Bool

    /// The Publisher that sends mutation events to subscribers
    var dataStorePublisher: ModelSubcriptionBehavior?

    let modelRegistration: AmplifyModelRegistration

    /// The DataStore configuration
    let dataStoreConfiguration: DataStoreConfiguration

    let validAPIPluginKey: String

    let validAuthPluginKey: String

    var storageEngine: StorageEngineBehavior!
    var storageEngineInitSemaphore: DispatchSemaphore
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

    /// No-argument init that uses defaults for all providers
    public init(modelRegistration: AmplifyModelRegistration,
                configuration dataStoreConfiguration: DataStoreConfiguration = .default) {
        self.modelRegistration = modelRegistration
        self.dataStoreConfiguration = dataStoreConfiguration
        self.isSyncEnabled = false
        self.validAPIPluginKey =  "awsAPIPlugin"
        self.validAuthPluginKey = "awsCognitoAuthPlugin"
        self.storageEngineBehaviorFactory =
            StorageEngine.init(isSyncEnabled:dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:)
        if #available(iOS 13.0, *) {
            self.dataStorePublisher = DataStorePublisher()
        } else {
            self.dataStorePublisher = nil
        }
        self.storageEngineInitSemaphore = DispatchSemaphore(value: 1)
    }

    /// Internal initializer for testing
    init(modelRegistration: AmplifyModelRegistration,
         configuration dataStoreConfiguration: DataStoreConfiguration = .default,
         storageEngineBehaviorFactory: StorageEngineBehaviorFactory? = nil,
         dataStorePublisher: ModelSubcriptionBehavior,
         validAPIPluginKey: String,
         validAuthPluginKey: String) {
        self.modelRegistration = modelRegistration
        self.dataStoreConfiguration = dataStoreConfiguration
        self.isSyncEnabled = false
        self.storageEngineBehaviorFactory = storageEngineBehaviorFactory ??
            StorageEngine.init(isSyncEnabled:dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:)
        self.dataStorePublisher = dataStorePublisher
        self.validAPIPluginKey = validAPIPluginKey
        self.validAuthPluginKey = validAuthPluginKey
        self.storageEngineInitSemaphore = DispatchSemaphore(value: 1)
    }

    /// By the time this method gets called, DataStore will already have invoked
    /// `AmplifyModelRegistration.registerModels`, so we can inspect those models to derive isSyncEnabled, and pass
    /// them to `StorageEngine.setUp(modelSchemas:)`
    public func configure(using amplifyConfiguration: Any?) throws {
        modelRegistration.registerModels(registry: ModelRegistry.self)
        resolveSyncEnabled()
        ModelListDecoderRegistry.registerDecoder(DataStoreListDecoder.self)
    }

    /// Initializes the underlying storage engine
    /// - Returns: success if the engine is successfully initialized or
    ///            a failure with a DataStoreError
    func initStorageEngine() -> DataStoreResult<Void> {
        storageEngineInitSemaphore.wait()
        if storageEngine != nil {
            storageEngineInitSemaphore.signal()
            return .successfulVoid
        }

        var result: DataStoreResult<Void>
        do {
            if #available(iOS 13.0, *) {
                if self.dataStorePublisher == nil {
                    self.dataStorePublisher = DataStorePublisher()
                }
            }
            try resolveStorageEngine(dataStoreConfiguration: dataStoreConfiguration)
            try storageEngine.setUp(modelSchemas: ModelRegistry.modelSchemas)
            result = .successfulVoid
        } catch {
            result = .failure(causedBy: error)
            log.error(error: error)
        }
        storageEngineInitSemaphore.signal()

        return result
    }

    /// Initializes the underlying storage engine and starts the syncing process
    /// - Parameter completion: completion handler called with a success if the sync process started
    ///                         or with a DataStoreError in case of failure
    func initStorageEngineAndStartSync(completion: @escaping DataStoreCallback<Void> = {_ in}) {
        if storageEngine != nil {
            completion(.successfulVoid)
            return
        }

        switch initStorageEngine() {
        case .success:
            storageEngine.startSync(completion: completion)
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
                receiveValue: { [weak self] in self?.onRecieveValue(receiveValue: $0) }
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
    }

    @available(iOS 13.0, *)
    private func onRecieveValue(receiveValue: StorageEngineEvent) {
        guard let dataStorePublisher = self.dataStorePublisher else {
            log.error("Data store publisher not initalized")
            return
        }

        if case .mutationEvent(let mutationEvent) = receiveValue {
            dataStorePublisher.send(input: mutationEvent)
        }
    }

    public func reset(onComplete: @escaping (() -> Void)) {
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
