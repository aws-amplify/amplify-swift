//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSS3AbortMultipartUploadRequest {
    let bucket: String
    let key: String
    let uploadId: String

    init(bucket: String,
         key: String,
         uploadId: String) {
        self.bucket = bucket
        self.key = key
        self.uploadId = uploadId
    }
}
