//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageGetRequest {
    let bucket: String
    let accessLevel: AccessLevel
    let targetIdentityId: String?
    let key: String
    let storageGetDestination: StorageGetDestination
    let options: Any?

    public init(bucket: String,
                accessLevel: AccessLevel,
                targetIdentityId: String?,
                key: String,
                storageGetDestination: StorageGetDestination,
                options: Any?) {
        self.bucket = bucket
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.key = key
        self.storageGetDestination = storageGetDestination
        self.options = options
    }

    // TODO: gettings for things in options
    func validate() -> StorageGetError? {
        if bucket.isEmpty {
            return StorageGetError.unknown("bucket is empty", "bucket is empty")
        }

        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageGetError.unknown("The targetIde is specified but is empty", "..")
            }

            if accessLevel == .Public {
                return StorageGetError.unknown("makes no sense to be public with target", ".")
            }
        }

        if key.isEmpty {
            return StorageGetError.unknown("key is empty", "key is empty")
        }

        switch(storageGetDestination) {
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
