//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the stored properties.
struct AWSS3StoragePutRequest {
    let accessLevel: StorageAccessLevel
    let key: String
    let uploadSource: UploadSource
    let contentType: String?
    let metadata: [String: String]?
    let options: Any?

    /// Creates an instance with storage request input values.
    init(accessLevel: StorageAccessLevel,
         key: String,
         uploadSource: UploadSource,
         contentType: String?,
         metadata: [String: String]?,
         options: Any?) {
        self.accessLevel = accessLevel
        self.key = key
        self.uploadSource = uploadSource
        self.contentType = contentType
        self.metadata = metadata
        self.options = options
    }

    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateKey(key) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validateContentType(contentType) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        if let error = StorageRequestUtils.validateMetadata(metadata) {
            return StorageError.validation(error.errorDescription, error.recoverySuggestion)
        }

        return nil
    }
}
