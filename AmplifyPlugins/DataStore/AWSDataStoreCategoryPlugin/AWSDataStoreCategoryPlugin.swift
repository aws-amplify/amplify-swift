//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

final public class AWSDataStoreCategoryPlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "awsDataStoreCategoryPlugin"

    /// `true` if any models are syncable. Resolved during configuration phase
    var isSyncEnabled: Bool

    /// The Publisher that sends mutation events to subscribers
    let dataStorePublisher: DataStorePublisher

    let modelRegistration: DataStoreModelRegistration

    /// The local storage provider. Resolved during configuration phase
    var storageEngine: StorageEngineBehavior!

    /// No-argument init that uses defaults for all providers
    public init(modelRegistration: DataStoreModelRegistration) {
        self.modelRegistration = modelRegistration
        self.isSyncEnabled = false
        self.dataStorePublisher = DataStorePublisher()
    }

    /// Internal initializer for testing
    init(modelRegistration: DataStoreModelRegistration,
         storageEngine: StorageEngineBehavior,
         dataStorePublisher: DataStorePublisher) {
        self.modelRegistration = modelRegistration
        self.isSyncEnabled = false
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher
    }

    /// By the time this method gets called, DataStore will already have invoked
    /// `DataStoreModelRegistration.registerModels`, so we can inspect those models to derive isSyncEnabled, and pass
    /// them to `StorageEngine.setUp(models:)`
    public func configure(using configuration: Any) throws {
        modelRegistration.registerModels(registry: ModelRegistry.self)
        resolveSyncEnabled()
        try resolveStorageEngine()
        registerSystemModels()
        try storageEngine.setUp(models: ModelRegistry.models)

        let filter = HubFilters.forEventName(HubPayload.EventName.Amplify.configured)
        var token: UnsubscribeToken?
        token = Amplify.Hub.listen(to: .dataStore, isIncluded: filter) { _ in
            self.storageEngine.startSync()
            if let token = token {
                Amplify.Hub.removeListener(token)
            }
        }
    }

    public func reset(onComplete: @escaping (() -> Void)) {
        // TODO: Shutdown storage engine
        // - Cancelling in-process operations
        // - Unsubscribe from syncable model mutations
        // - ...?
        onComplete()
    }

    // MARK: Private

    private func resolveSyncEnabled() {
        if #available(iOS 13.0, *) {
            isSyncEnabled = ModelRegistry.hasSyncableModels
        }
    }

    private func resolveStorageEngine() throws {
        guard storageEngine == nil else {
            return
        }

        storageEngine = try StorageEngine(isSyncEnabled: isSyncEnabled)
    }

    private func registerSystemModels() {
        // TODO: should this run only when sync is enabled?
        ModelRegistry.register(modelType: MutationEvent.self)
        ModelRegistry.register(modelType: MutationSyncMetadata.self)
    }

}
