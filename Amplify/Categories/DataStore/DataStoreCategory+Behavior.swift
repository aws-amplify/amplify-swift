//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DataStoreCategory: DataStoreCategoryBehavior {

    public func save<M: Model>(_ model: M, completion: DataStoreCallback<M>) {
        plugin.save(model, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        plugin.query(modelType, byId: id, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                completion: DataStoreCallback<[M]>) {
        plugin.query(modelType, completion: completion)
    }

    public func delete<M: Model>(_ model: M,
                                 completion: DataStoreCallback<Bool>) {
        plugin.delete(model, completion: completion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: DataStoreCallback<Void>?) {
        plugin.delete(modelType, withId: id, completion: completion)
    }
}
