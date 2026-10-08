//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension StorageListRequest {
    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(
            options.legacyTargetIdentityId,
            accessLevel: options.legacyAccessLevel
        ) {
            return error
        }

        if let error = StorageRequestUtils.validatePath(options.legacyPath) {
            return error
        }

        return nil
    }
}
