//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the stored properties.
struct AWSS3StorageRemoveRequest {
    let accessLevel: StorageAccessLevel
    let key: String
    let options: Any?

    /// Creates an instance with storage request input values.
    init(accessLevel: StorageAccessLevel,
         key: String,
         options: Any? = nil) {
        self.accessLevel = accessLevel
        self.key = key
        self.options = options
    }

    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateKey(key) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        return nil
    }
}
