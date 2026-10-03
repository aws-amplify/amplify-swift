//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension StorageDownloadFileRequest {
    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        guard path == nil else {
            // return nil here StoragePath are validated
            // at during execution of request operation where the path is resolved
            return nil
        }
        if let error = StorageRequestUtils.validateTargetIdentityId(
            options.legacyTargetIdentityId,
            accessLevel: options.legacyAccessLevel
        ) {
            return error
        }

        if let error = StorageRequestUtils.validateKey(legacyKey) {
            return error
        }

        return nil
    }
}
