//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the stored properties.
struct AWSS3StorageListRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let path: String?
    let options: Any?

    /// Creates an instance with storage request input values.
    init(accessLevel: StorageAccessLevel,
         targetIdentityId: String?,
         path: String? = nil,
         options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.path = path
        self.options = options
    }

    /// Performs client side validation and returns a `StorageListError` for any validation failures.
    func validate() -> StorageListError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(targetIdentityId, accessLevel: accessLevel) {
            return StorageListError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validatePath(path) {
            return StorageListError.validation(error.errorDescription, error.recoverySuggestion)
        }

        return nil
    }
}
