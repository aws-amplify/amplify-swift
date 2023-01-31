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

extension AWSS3StorageService {

    func list(prefix: String,
              options: StorageListRequest.Options) async throws -> StorageListResult {
        if let error = StorageRequestUtils.validateTargetIdentityId(options.targetIdentityId,
                                                                    accessLevel: options.accessLevel) {
            throw error
        }
        if let error = StorageRequestUtils.validatePath(options.path) {
            throw error
        }

        let finalPrefix: String
        if let path = options.path {
            finalPrefix = prefix + path
        } else {
            finalPrefix = prefix
        }
        let input = ListObjectsV2Input(bucket: bucket,
                                       continuationToken: nil,
                                       delimiter: nil,
                                       maxKeys: 1_000,
                                       prefix: finalPrefix,
                                       startAfter: nil)
        do {
            let response = try await client.listObjectsV2(input: input)
            let contents: S3BucketContents = response.contents ?? []
            let items = try contents.map {
                try StorageListResult.Item(s3Object: $0, prefix: prefix)
            }
            return StorageListResult(items: items)
        } catch let error as SdkError<ListObjectsV2OutputError> {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }
    }

}
