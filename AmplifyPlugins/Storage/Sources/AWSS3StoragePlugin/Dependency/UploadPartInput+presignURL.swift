//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSS3
import ClientRuntime

extension UploadPartInput {
    func customPresignURL(config: S3Client.S3ClientConfiguration, expiration: TimeInterval) async throws -> ClientRuntime.URL? {
        return try await presign(config: config, expiration: expiration)?.endpoint.url
     }
 }
