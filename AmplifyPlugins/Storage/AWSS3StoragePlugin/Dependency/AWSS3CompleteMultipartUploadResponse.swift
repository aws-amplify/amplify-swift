//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSS3CompleteMultipartUploadResponse {
    let bucket: String
    let key: String
    let eTag: String
    
    init(bucket: String, key: String, eTag: String) {
        self.bucket = bucket
        self.key = key
        self.eTag = eTag
    }
}
