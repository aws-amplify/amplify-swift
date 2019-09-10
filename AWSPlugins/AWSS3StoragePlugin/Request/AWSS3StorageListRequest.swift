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
    let prefix: String?
    let limit: Int?
    let options: Any?

    init(accessLevel: StorageAccessLevel,
         targetIdentityId: String?,
         prefix: String? = nil,
         limit: Int? = nil,
         options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.prefix = prefix
        self.limit = limit
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

        if let prefix = prefix {
            if prefix.isEmpty {
                return StorageListError.validation(StorageErrorConstants.PrefixIsEmpty.ErrorDescription,
                                                   StorageErrorConstants.PrefixIsEmpty.RecoverySuggestion)
            }
        }

        if let limit = limit {
            if limit < 0 {
                return StorageListError.validation(StorageErrorConstants.LimitIsInvalid.ErrorDescription,
                                                   StorageErrorConstants.LimitIsInvalid.RecoverySuggestion)
            }
        }

        return nil
    }
}
