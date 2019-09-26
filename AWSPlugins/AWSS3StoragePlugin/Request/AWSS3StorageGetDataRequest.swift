//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Stores the values of the storage request and provides validation on the properties.
struct AWSS3StorageGetDataRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let key: String
    let pluginOptions: Any?

    /// Creates an instance with storage request input values.
    public init(accessLevel: StorageAccessLevel,
                targetIdentityId: String?,
                key: String,
                pluginOptions: Any?) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.key = key
        self.pluginOptions = pluginOptions
    }

    /// Performs client side validation and returns a `StorageError` for any validation failures.
    func validate() -> StorageError? {
        if let error = StorageRequestUtils.validateTargetIdentityId(targetIdentityId, accessLevel: accessLevel) {
            return error
        }

        if let error = StorageRequestUtils.validateKey(key) {
            return error
        }

        return nil
    }
}
