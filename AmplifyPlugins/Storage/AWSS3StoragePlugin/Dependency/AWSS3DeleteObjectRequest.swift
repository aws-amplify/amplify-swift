//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AWSS3DeleteObjectRequest {
    public let bucket: String
    public let key: String

    public init(bucket: String, key: String) {
        self.bucket = bucket
        self.key = key
    }
}
