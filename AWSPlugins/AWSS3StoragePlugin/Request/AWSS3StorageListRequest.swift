//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageListRequest {
    let accessLevel: StorageAccessLevel
    let targetIdentityId: String?
    let path: String?
    let options: Any?

    init(accessLevel: StorageAccessLevel,
         targetIdentityId: String?,
         path: String? = nil,
         options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.path = path
        self.options = options
    }

    func validate() -> StorageListError? {
        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageListError.validation(StorageErrorConstants.IdentityIdIsEmpty.ErrorDescription,
                                                  StorageErrorConstants.IdentityIdIsEmpty.RecoverySuggestion)
            }

            if accessLevel == .private {
                return StorageListError.validation(StorageErrorConstants.PrivateWithTarget.ErrorDescription,
                                                  StorageErrorConstants.PrivateWithTarget.RecoverySuggestion)
            }
        }

        if let path = path {
            if path.isEmpty {
                return StorageListError.validation(StorageErrorConstants.PathIsEmpty.ErrorDescription,
                                                   StorageErrorConstants.PathIsEmpty.RecoverySuggestion)
            }
        }

        return nil
    }
}
