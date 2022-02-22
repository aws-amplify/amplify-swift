//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import AWSPluginsCore
import ClientRuntime
import AWSClientRuntime

/// The class confirming to AWSS3PreSignedURLBuilderBehavior which uses GetObjectInput to
/// create a pre-signed URL.
class AWSS3PreSignedURLBuilderAdapter: AWSS3PreSignedURLBuilderBehavior {
    let bucket: String
    let config: AWSClientConfiguration

    /// Creates a pre-signed URL builder.
    /// - Parameter credentialsProvider: Credentials Provider.
    init(region: String, bucket: String) throws {
        self.bucket = bucket
        self.config = try S3Client.S3ClientConfiguration(region: region)
    }

    /// Gets pre-signed URL.
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(key: String, expires: Int64? = nil) -> URL? {
        let input = GetObjectInput(bucket: bucket, key: key)
        let preSignedURL = input.presignURL(config: config, expiration: expires ?? -1)
        return preSignedURL
    }
}
