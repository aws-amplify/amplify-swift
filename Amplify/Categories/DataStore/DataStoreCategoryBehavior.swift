//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias DataStoreResult<T> = (_ result: T, _ error: Error?) -> Void

public protocol DataStoreCategoryBehavior {

    func save<M: PersistentModel>(model: M, result: DataStoreResult<M>?)

    func query<M: PersistentModel>(byId id: String, result: DataStoreResult<M?>)

    func delete<M: PersistentModel>(model: M, result: DataStoreResult<Bool>?)

    func delete(modelType: PersistentModel.Type, withId id: String, result: DataStoreResult<Bool>?)

}
