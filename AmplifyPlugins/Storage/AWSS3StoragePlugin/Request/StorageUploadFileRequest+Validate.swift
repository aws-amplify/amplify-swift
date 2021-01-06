//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageUploadFileRequest {
    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateKey(key) {
            return error
        }

        if let error = StorageRequestUtils.validateContentType(options.contentType) {
            return error
        }

        if let error = StorageRequestUtils.validateMetadata(options.metadata) {
            return error
        }

        return nil
    }
}

extension StorageUploadFileRequest.Options {
    /// The minimum size before utilizing multipart upload functionality is 5MB
    static let multiPartUploadSizeThreshold = 5_000_000
}
