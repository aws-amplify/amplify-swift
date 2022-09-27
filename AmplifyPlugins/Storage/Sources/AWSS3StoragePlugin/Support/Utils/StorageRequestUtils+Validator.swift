//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageRequestUtils {

    // MARK: Validation methods

    /// Validate `targetIdentityId` is specified only for `protected` accessLevel.
    static func validateTargetIdentityId(_ targetIdentityId: String?,
                                         accessLevel: StorageAccessLevel) -> StorageError? {
        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageError.validation(StorageErrorConstants.identityIdIsEmpty.field,
                                               StorageErrorConstants.identityIdIsEmpty.errorDescription,
                                               StorageErrorConstants.identityIdIsEmpty.recoverySuggestion)
            }

            if accessLevel != .protected {
                return StorageError.validation(StorageErrorConstants.invalidAccessLevelWithTarget.field,
                                               StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription,
                                               StorageErrorConstants.invalidAccessLevelWithTarget.recoverySuggestion)
            }
        }

        return nil
    }

    /// Validate `key` is non-empty string.
    static func validateKey(_ key: String) -> StorageError? {
        if key.isEmpty {
            return StorageError.validation(StorageErrorConstants.keyIsEmpty.field,
                                          StorageErrorConstants.keyIsEmpty.errorDescription,
                                          StorageErrorConstants.keyIsEmpty.recoverySuggestion)
        }

        return nil
    }

    /// Validate `expires` value is non-zero positive.
    static func validate(expires: Int) -> StorageError? {
        if expires <= 0 {
            return StorageError.validation(StorageErrorConstants.expiresIsInvalid.field,
                                           StorageErrorConstants.expiresIsInvalid.errorDescription,
                                           StorageErrorConstants.expiresIsInvalid.recoverySuggestion)
        }

        return nil
    }

    /// Validate `path` is non-empty, if specified.
    static func validatePath(_ path: String?) -> StorageError? {
        if let path = path {
            if path.isEmpty {
                return StorageError.validation(StorageErrorConstants.pathIsEmpty.field,
                                               StorageErrorConstants.pathIsEmpty.errorDescription,
                                               StorageErrorConstants.pathIsEmpty.recoverySuggestion)
            }
        }

        return nil
    }

    // Validate `contentType` is non-empty string
    static func validateContentType(_ contentType: String?) -> StorageError? {
        if let contentType = contentType {
            if contentType.isEmpty {
                return StorageError.validation(StorageErrorConstants.contentTypeIsEmpty.field,
                                               StorageErrorConstants.contentTypeIsEmpty.errorDescription,
                                               StorageErrorConstants.contentTypeIsEmpty.recoverySuggestion)
            }
        }

        return nil
    }

    // Validate `metadata` dictionary contains lowercased keys
    static func validateMetadata(_ metadata: [String: String]?) -> StorageError? {
        if let metadata = metadata {
            for (key, _) in metadata {
                if key != key.lowercased() {
                    return StorageError.validation(StorageErrorConstants.metadataKeysInvalid.field,
                                                   StorageErrorConstants.metadataKeysInvalid.errorDescription,
                                                   StorageErrorConstants.metadataKeysInvalid.recoverySuggestion)
                }
                // TODO: validate that metadata values are within a certain size.
                // https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#object-metadata 2KB
            }
        }

        return nil
    }

    // Validate `file` file exists
    static func validateFileExists(_ file: URL) -> StorageError? {
        if !FileManager.default.fileExists(atPath: file.path) {
            return StorageError.localFileNotFound(StorageErrorConstants.localFileNotFound.errorDescription,
                                                  StorageErrorConstants.localFileNotFound.recoverySuggestion)
        }

        return nil
    }
}
