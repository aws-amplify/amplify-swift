//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol StorageEngineBehavior: class, ModelStorageBehavior {

    /// Tells the StorageEngine to begin syncing, if sync is enabled
    func startSync()
}
