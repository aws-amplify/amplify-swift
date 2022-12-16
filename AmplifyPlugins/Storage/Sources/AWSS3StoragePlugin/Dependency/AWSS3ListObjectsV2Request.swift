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

extension StorageListResult.Item {
    init(s3Object: S3ClientTypes.Object, prefix: String) throws {
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
