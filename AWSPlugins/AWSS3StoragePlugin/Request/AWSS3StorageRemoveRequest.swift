//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageRemoveRequest {
    let bucket: String
    let accessLevel: StorageAccessLevel
    let key: String

    init(bucket: String,
         accessLevel: StorageAccessLevel,
         key: String) {
        self.bucket = bucket
        self.accessLevel = accessLevel
        self.key = key
    }

    func validate() -> StorageRemoveError? {
        if bucket.isEmpty {
            return StorageRemoveError.unknown("bucket is empty", "bucket is empty")
        }

        if key.isEmpty {
            return StorageRemoveError.unknown("key is empty", "key is empty")
        }

        return nil
    }
}
