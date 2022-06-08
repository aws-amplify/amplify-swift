//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct CreateMultipartUploadRequest {
    let bucket: String
    let key: String

    let expires: Date?
    let cacheControl: String?
    let contentDisposition: String?
    let contentEncoding: String?
    let contentLanguage: String?
    let contentType: String?
    let metadata: [String: String]?

    init(bucket: String, key: String,
         expires: Date? = nil,
         cacheControl: String? = nil,
         contentDisposition: String? = nil,
         contentEncoding: String? = nil,
         contentLanguage: String? = nil,
         contentType: String? = nil,
         metadata: [String: String]? = nil) {
        self.bucket = bucket
        self.key = key

        self.expires = expires
        self.cacheControl = cacheControl
        self.contentDisposition = contentDisposition
        self.contentEncoding = contentEncoding
        self.contentLanguage = contentLanguage
        self.contentType = contentType
        self.metadata = metadata
    }
}
