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
    var fallbackDescription: String { get }
}

extension StorageError: StorageErrorConvertible {
    var fallbackDescription: String { "" }

    var storageError: StorageError { self }
}
