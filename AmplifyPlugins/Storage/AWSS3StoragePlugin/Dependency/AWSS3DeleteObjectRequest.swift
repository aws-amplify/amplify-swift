//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSS3DeleteObjectRequest {
    let bucket: String
    let key: String

    init(bucket: String, key: String) {
        self.bucket = bucket
        self.key = key
    }
}
