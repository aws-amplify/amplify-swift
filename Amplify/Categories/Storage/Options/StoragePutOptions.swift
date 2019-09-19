//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// StoragePutOptions specifies additional options when uploading an object to storage.
public struct StoragePutOptions {

    // Access level of the storage system.
    public let accessLevel: StorageAccessLevel?

    // Metadata for the object to store.
    public let metadata: [String: String]?

    // The standard MIME type describing the format of the object to store.
    public let contentType: String?

    // Extra plugin specific options
    public let pluginOptions: Any?

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
                pluginOptions: Any? = nil) {
        self.accessLevel = accessLevel
        self.contentType = contentType
        self.metadata = metadata
        self.pluginOptions = pluginOptions
    }
}
