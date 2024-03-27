//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension StoragePath {
    func resolvePath(authService: AWSAuthServiceBehavior? = nil) async throws -> String {
        if self is IdentityIDStoragePath {
            let authService = authService ?? AWSAuthService()
            guard let identityId = try await authService.getIdentityID() as? Input else {
                throw StorageError.configuration(
                    "Unable to resolve identity id as a storage path input type",
                    "Please verify that storage is configured correctly",
                    nil
                )
            }
            let path = resolve(identityId)
            try validate(path)
            return path
        } else if self is StringStoragePath {
            guard let input = "" as? Input else {
                throw StorageError.unknown(
                    "Unable to resolve StringStoragePath resolver input",
                    nil
                )
            }
            let path = resolve(input)
            try validate(path)
            return path
        } else {
            let errorDescription = "The StoragePath specified is not supported"
            let recoverySuggestion = "Please specify a StoragePath from string or from identityID."
            throw StorageError.validation("path", errorDescription, recoverySuggestion, nil)
        }
    }

    func validate(_ path: String) throws {
        if path.hasPrefix("/") {
            let errorDescription = "Invalid StoragePath specified."
            let recoverySuggestion = "Please specify a valid StoragePath that does not contain the prefix / "
            throw StorageError.validation("path", errorDescription, recoverySuggestion, nil)
        }
    }
}
