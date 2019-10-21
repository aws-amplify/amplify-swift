//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AppSyncLocalPlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "AppSyncLocalPlugin"

    let storageEngine: StorageEngine

    // temporary, tied this up with configuration along with local db config,
    // sync endpoint, etc
    let models: [PersistentModel.Type]

    public init(storageEngine: StorageEngine, models: [PersistentModel.Type]) {
        self.storageEngine = storageEngine
        self.models = models
    }

    public convenience init(models: [PersistentModel.Type]) throws {
        let engine = try StorageEngine(adapter: SQLiteStorageEngineAdapter())
        self.init(storageEngine: engine, models: models)
    }

    public func configure(using configuration: Any) throws {
        try storageEngine.setUp(models: models)
    }

    public func save<M: PersistentModel>(_ model: M,
                                         completion: (DataStoreResult<M>) -> Void) {
        storageEngine.save(model, completion: completion)
    }

    public func query<M: PersistentModel>(_ modelType: M.Type,
                                          byId id: String,
                                          completion: (DataStoreResult<M?>) -> Void) {
        // TODO implement
    }

    public func query<M: PersistentModel>(_ modelType: M.Type,
                                          completion: (DataStoreResult<[M]>) -> Void) {
        storageEngine.query(modelType, completion: completion)
    }

    public func delete<M: PersistentModel>(_ model: M,
                                           completion: (DataStoreResult<Bool>) -> Void) {
//        self.delete(type(of: model), withId: model.id, completion: completion)
    }

    public func delete<M: PersistentModel>(_ modelType: M.Type,
                                           withId id: String,
                                           completion: DataStoreCallback<Void>?) {
        // TODO implement
    }

    public func reset(onComplete: @escaping (() -> Void)) {
//        storageEngine.shutdown()
        onComplete()
    }

}
