//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol StorageEngineAdapter: StorageEngineBehavior {

    func exists(_ modelType: Model.Type, withId id: Model.Identifier) throws -> Bool
}
