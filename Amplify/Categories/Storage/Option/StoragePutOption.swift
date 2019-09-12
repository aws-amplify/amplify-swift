//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StoragePutOption {

    public var accessLevel: StorageAccessLevel?

    public var metadata: [String: String]?

    public var contentType: String?

    public var options: Any?

    /* TODO
     tags (may be in options)
     expires (may be in metadata)
     transferAcceleration should be in options most likely. and can be set globally
      https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
     multipartConcurrenyLimit probably in options (this is how many parts for multipart upload
     retryLimit - per request and also global
     timeoutIntervalForResource max duration of a transfer. can be overriden in global. does it need to be in request
     */
    public init(accessLevel: StorageAccessLevel?,
                contentType: String? = nil,
                metadata: [String: String]? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.contentType = contentType
        self.metadata = metadata
        self.options = options
    }
}
