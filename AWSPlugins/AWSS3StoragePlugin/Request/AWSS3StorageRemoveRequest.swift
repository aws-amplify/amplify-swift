//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageRemoveRequest {
    let accessLevel: StorageAccessLevel
    let key: String
    let options: Any?

    init(accessLevel: StorageAccessLevel,
         key: String,
         options: Any? = nil) {
        self.accessLevel = accessLevel
        self.key = key
        self.options = options
    }

    func validate() -> StorageRemoveError? {
        if key.isEmpty {
            return StorageRemoveError.validation(StorageErrorConstants.KeyIsEmpty.ErrorDescription,
                                                 StorageErrorConstants.KeyIsEmpty.RecoverySuggestion)
        }

        return nil
    }
}
