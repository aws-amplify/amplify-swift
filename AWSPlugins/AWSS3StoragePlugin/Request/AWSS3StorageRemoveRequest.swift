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

    init(accessLevel: StorageAccessLevel,
         key: String) {
        self.accessLevel = accessLevel
        self.key = key
    }

    func validate() -> StorageRemoveError? {
        if key.isEmpty {
            return StorageRemoveError.unknown("key is empty", "key is empty")
        }

        return nil
    }
}
