//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageRequestUtils {

    // MARK: Validation methods

    static func validateTargetIdentityId(_ targetIdentityId: String?,
                                         accessLevel: StorageAccessLevel) -> StorageErrorString? {
        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageErrorConstants.identityIdIsEmpty
            }

            if accessLevel == .private {
                return StorageErrorConstants.privateWithTarget
            }

            // TODO: if it is public, it doesn't make sense to have a targetIdentityId.
        }

        return nil
    }

    static func validateKey(_ key: String) -> StorageErrorString? {
        if key.isEmpty {
            return StorageErrorConstants.keyIsEmpty
        }

        return nil
    }

    static func validate(expires: Int) -> StorageErrorString? {
        if expires <= 0 {
            return StorageErrorConstants.expiresIsInvalid
        }

        return nil
    }

    static func validatePath(_ path: String?) -> StorageErrorString? {
        if let path = path {
            if path.isEmpty {
                return StorageErrorConstants.pathIsEmpty
            }
        }

        return nil
    }

    static func validateContentType(_ contentType: String?) -> StorageErrorString? {
        if let contentType = contentType {
            if contentType.isEmpty {
                return StorageErrorConstants.contentTypeIsEmpty
            }
            // TODO content type validation
        }

        return nil
    }

    static func validateMetadata(_ metadata: [String: String]?) -> StorageErrorString? {
        if let metadata = metadata {
            for (key, _) in metadata {
                if key != key.lowercased() {
                    return StorageErrorConstants.metadataKeysInvalid
                }
                // TODO: validate that metadata values are within a certain size.
                // https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#object-metadata 2KB
            }
        }

        return nil
    }

    static func validateFileExists(_ file: URL) -> StorageErrorString? {
        if !FileManager.default.fileExists(atPath: file.path) {
            return StorageErrorConstants.missingFile
        }

        return nil
    }
}
