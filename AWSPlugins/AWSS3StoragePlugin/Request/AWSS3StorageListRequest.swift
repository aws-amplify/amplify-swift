//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageListRequest {
    let bucket: String
    let accessLevel: StorageAccessLevel
    let prefix: String?
    let limit: Int?

    init(bucket: String,
         accessLevel: StorageAccessLevel,
         prefix: String? = nil,
         limit: Int? = nil) {
        self.bucket = bucket
        self.accessLevel = accessLevel
        self.prefix = prefix
        self.limit = limit
    }

    func validate() -> StorageListError? {
        if bucket.isEmpty {
            return StorageListError.unknown("bucket is empty", "bucket is empty")
        }

        if let prefix = prefix {
            if prefix.isEmpty {
                return StorageListError.unknown("prefix is specified but is empty", "empty")
            }
        }

        if let limit = limit {
            if limit < 0 {
                return StorageListError.unknown("limit is negative", "")
            }
        }

        return nil
    }
}
