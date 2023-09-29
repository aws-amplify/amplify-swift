//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol StorageErrorConvertible {
    var storageError: StorageError { get }
}

extension StorageError: StorageErrorConvertible {
    var storageError: StorageError { self }
}
