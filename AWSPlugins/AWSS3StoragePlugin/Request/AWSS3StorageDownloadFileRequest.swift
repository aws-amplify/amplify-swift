//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the properties.
struct AWSS3StorageDownloadFileRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let key: String
    let local: URL
    let options: Any?

    /// Creates an instance with storage request input values.
    public init(accessLevel: StorageAccessLevel,
                targetIdentityId: String?,
                key: String,
                local: URL,
                options: Any?) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.key = key
        self.local = local
        self.options = options
    }

    /// Performs client side validation and returns a `StorageDownloadFileError` for any validation failures.
    func validate() -> StorageDownloadFileError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(targetIdentityId, accessLevel: accessLevel) {
            return StorageDownloadFileError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validateKey(key) {
            return StorageDownloadFileError.validation(error.errorDescription, error.recoverySuggestion)
        }

        return nil
    }
}
