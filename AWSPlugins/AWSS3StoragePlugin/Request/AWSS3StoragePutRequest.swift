//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StoragePutRequest {
    let bucket: String
    let accessLevel: AccessLevel
    let key: String
    let data: Data?
    let fileURL: URL?
    let contentType: String?

    init(bucket: String,
         accessLevel: AccessLevel,
         key: String,
         data: Data?,
         fileURL: URL?,
         contentType: String?) {
        self.bucket = bucket
        self.accessLevel = accessLevel
        self.key = key
        self.data = data
        self.fileURL = fileURL
        self.contentType = contentType
    }

    func validate() -> StoragePutError? {
        if bucket.isEmpty {
            return StoragePutError.unknown("bucket is empty", "bucket is empty")
        }

        if key.isEmpty {
            return StoragePutError.unknown("key is empty", "key is empty")
        }

        if data != nil && fileURL != nil {
            return StoragePutError.unknown("Both data and local", "was specified")
        }

        if let contentType = contentType {
            if contentType.isEmpty {
                return StoragePutError.unknown("content type specified but is empty", "")
            }
            // else if contentTypeValidator(contentType) {
        }

        return nil
    }
}
