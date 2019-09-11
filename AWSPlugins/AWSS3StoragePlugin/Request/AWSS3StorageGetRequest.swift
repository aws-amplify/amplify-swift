//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the properties.
struct AWSS3StorageGetRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let key: String
    let storageGetDestination: StorageGetDestination
    let options: Any?

    /// Creates an instance with storage request input values.
    public init(accessLevel: StorageAccessLevel,
                targetIdentityId: String?,
                key: String,
                storageGetDestination: StorageGetDestination,
                options: Any?) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.key = key
        self.storageGetDestination = storageGetDestination
        self.options = options
    }

    /// Performs client side validation and returns a `StorageGetError` for any validation failures.
    func validate() -> StorageGetError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(targetIdentityId, accessLevel: accessLevel) {
            return StorageGetError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validateKey(key) {
            return StorageGetError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validate(storageGetDestination) {
            return StorageGetError.validation(error.errorDescription, error.recoverySuggestion)
        }

        return nil
    }
}
