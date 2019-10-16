//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol StorageAdapter {

    func setUp(models: [PersistentModel.Type]) throws

    func save(_ model: PersistentModel) throws

    func select<M: PersistentModel>(from model: M.Type) throws -> [M]

}
