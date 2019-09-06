//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageGetRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let key: String
    let storageGetDestination: StorageGetDestination
    let options: Any?

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

    func validate() -> StorageGetError? {
        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageGetError.unknown("The targetIde is specified but is empty", "..")
            }

            if accessLevel == .public {
                return StorageGetError.unknown("makes no sense to be public with target", ".")
            }
        }

        if key.isEmpty {
            return StorageGetError.unknown("key is empty", "key is empty")
        }

        switch storageGetDestination {
        case .data:
            break
        case .file:
            break
        case .url(let expires):
            if let expires = expires {
                if expires <= 0 {
                    return StorageGetError.unknown("expires should be non-zero", "")
                }
            }
        }

        return nil
    }
}
