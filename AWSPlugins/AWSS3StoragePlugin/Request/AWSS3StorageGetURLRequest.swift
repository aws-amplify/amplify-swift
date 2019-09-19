//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the properties.
struct AWSS3StorageGetURLRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let key: String
    let expires: Int?
    let options: Any?

    /// Creates an instance with storage request input values.
    public init(accessLevel: StorageAccessLevel,
                targetIdentityId: String?,
                key: String,
                expires: Int?,
                options: Any?) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.key = key
        self.expires = expires
        self.options = options
    }

    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(targetIdentityId, accessLevel: accessLevel) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validateKey(key) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let expires = expires {
            if let error = StorageRequestUtils.validate(expires: expires) {
                return StorageError.validation(error.errorDescription, error.recoverySuggestion)
            }
        }

        return nil
    }
}
