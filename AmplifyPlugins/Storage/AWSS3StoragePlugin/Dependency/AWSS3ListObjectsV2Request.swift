//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

import AWSS3
import ClientRuntime
import AWSClientRuntime

public struct AWSS3ListObjectsV2Request {
    public let bucket: String
    public let prefix: String?
    public let continuationToken: String?
    public let delimiter: String?
    public let maxKeys: Int
    public let startAfter: String?

    public init(bucket: String,
         prefix: String? = nil,
         continuationToken: String? = nil,
         delimiter: String? = nil,
         maxKeys: Int = 1_000,
         startAfter: String? = nil) {
        self.bucket = bucket
        self.prefix = prefix
        self.continuationToken = continuationToken
        self.delimiter = delimiter
        self.maxKeys = maxKeys
        self.startAfter = startAfter
    }
}

public protocol S3Object {
    var key: String? { get }
    var eTag: String? { get }
    var size: Int { get }
    var lastModified: Date? { get }
}

public typealias S3BucketContents = [S3Object]

extension S3ClientTypes.Object: S3Object {
}

extension StorageListResult.Item {
    init(s3Object: S3Object, prefix: String) throws {
        guard let fullKey = s3Object.key else {
            throw StorageError.unknown("Missing key in response")
        }

        let resultKey = String(fullKey.dropFirst(prefix.count))

        guard let eTag = s3Object.eTag else {
            throw StorageError.unknown("Missing eTag in response")
        }

        guard let lastModified = s3Object.lastModified else {
            throw StorageError.unknown("Missing lastModified in response")
        }

        self.init(key: resultKey, size: s3Object.size, eTag: eTag, lastModified: lastModified)
    }
}
