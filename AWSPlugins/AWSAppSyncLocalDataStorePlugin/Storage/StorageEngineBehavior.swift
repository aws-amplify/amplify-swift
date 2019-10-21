//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol StorageEngineBehavior {

    func setUp(models: [PersistentModel.Type]) throws

    func save<M: PersistentModel>(_ model: M, completion: DataStoreCallback<M>)

    func query<M: PersistentModel>(_ modelType: M.Type, completion: DataStoreCallback<[M]>)

}
