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
                return StorageGetError.validation(StorageErrorConstants.IdentityIdIsEmpty.ErrorDescription,
                                                  StorageErrorConstants.IdentityIdIsEmpty.RecoverySuggestion)
            }
        }

        if key.isEmpty {
            return StorageGetError.validation(StorageErrorConstants.KeyIsEmpty.ErrorDescription,
                                              StorageErrorConstants.KeyIsEmpty.RecoverySuggestion)
        }

        switch storageGetDestination {
        case .data:
            break
        case .file:
            break
        case .url(let expires):
            if let expires = expires {
                if expires <= 0 {
                    return StorageGetError.validation(StorageErrorConstants.ExpiresIsInvalid.ErrorDescription,
                                                      StorageErrorConstants.ExpiresIsInvalid.RecoverySuggestion)
                }
            }
        }

        return nil
    }
}
