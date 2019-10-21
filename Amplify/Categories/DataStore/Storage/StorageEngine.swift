//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final public class StorageEngine: StorageEngineBehavior {

    let adapter: StorageEngineAdapter

    public init(adapter: StorageEngineAdapter) {
        self.adapter = adapter
    }

    convenience init() throws {
        let key = kCFBundleNameKey as String
        let databaseName = Bundle.main.object(forInfoDictionaryKey: key) as? String
        try self.init(adapter: SQLiteStorageEngineAdapter(databaseName: databaseName ?? "app"))
    }

    public func setUp(models: [PersistentModel.Type]) throws {
        try adapter.setUp(models: models)
    }

    public func save<M: PersistentModel>(_ model: M, completion: DataStoreCallback<M>) {
        adapter.save(model, completion: completion)
    }

    public func query<M: PersistentModel>(_ modelType: M.Type,
                                          completion: DataStoreCallback<[M]>) {
        return adapter.query(modelType, completion: completion)
    }

}
