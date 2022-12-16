//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSS3
import Amplify
import ClientRuntime
import Foundation

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
            var listing = try await StorageListing.create(with: self.client,
                                                          prefix: prefix,
                                                          input: input)
            return StorageListResult(items: try await listing.firstPage())
        } catch let error as SdkError<ListObjectsV2OutputError> {
            throw StorageListingErrorTransformer(key: options.path).transform(sdkError: error)
        } catch {
            throw StorageError.init(error: error)
        }
    }
    
}
