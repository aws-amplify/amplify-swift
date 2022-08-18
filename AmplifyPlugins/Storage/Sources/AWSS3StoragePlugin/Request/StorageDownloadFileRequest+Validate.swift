//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageDownloadFileRequest {
    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(options.targetIdentityId,
                                                                    accessLevel: options.accessLevel) {
            return error
        }

        if let error = StorageRequestUtils.validateKey(key) {
            return error
        }

        return nil
    }
}
