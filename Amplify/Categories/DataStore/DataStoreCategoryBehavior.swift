//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol DataStoreCategoryBehavior {

    func save<M: PersistentModel>(_ model: M, completion: DataStoreCallback<M>)

    func query<M: PersistentModel>(_ modelType: M.Type,
                                   byId id: String,
                                   completion: DataStoreCallback<M?>)

    func query<M: PersistentModel>(_ modelType: M.Type,
                                   completion: DataStoreCallback<[M]>)

    func delete<M: PersistentModel>(_ model: M,
                                    completion: DataStoreCallback<Bool>)

    func delete<M: PersistentModel>(_ modelType: M.Type,
                                    withId id: String,
                                    completion: DataStoreCallback<Void>?)

}
