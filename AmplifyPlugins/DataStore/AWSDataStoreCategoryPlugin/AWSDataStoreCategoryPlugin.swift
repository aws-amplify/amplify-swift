//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSDataStoreCategoryPlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "AWSDataStoreCategoryPlugin"

    let storageEngine: StorageEngine

    // TODO temporary, replace with configuration
    let models: [Model.Type]

    public init(storageEngine: StorageEngine, models: [Model.Type]) {
        self.storageEngine = storageEngine
        self.models = models
    }

    public convenience init(models: [Model.Type]) throws {
        let engine = try StorageEngine(adapter: SQLiteStorageEngineAdapter())
        self.init(storageEngine: engine, models: models)
    }

    public func configure(using configuration: Any) throws {
        try storageEngine.setUp(models: models)
    }

    public func save<M: Model>(_ model: M,
                               completion: (DataStoreResult<M>) -> Void) {
        storageEngine.save(model, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: (DataStoreResult<M?>) -> Void) {
        // TODO implement
    }

    public func query<M: Model>(_ modelType: M.Type,
                                completion: (DataStoreResult<[M]>) -> Void) {
        storageEngine.query(modelType, completion: completion)
    }

    public func delete<M: Model>(_ model: M,
                                 completion: (DataStoreResult<Bool>) -> Void) {
//        self.delete(type(of: model), withId: model.id, completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: DataStoreCallback<Void>?) {
        // TODO implement
    }

    public func reset(onComplete: @escaping (() -> Void)) {
//        storageEngine.shutdown()
        onComplete()
    }

}
