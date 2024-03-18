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
            let identityId = try await authService.getIdentityID()
            let path = resolve(identityId as! Self.Input)
            try validate(path)
            return path
        } else if self is StringStoragePath {
            let path = resolve("" as! Self.Input)
            try validate(path)
            return path
        } else {
            let errorDescription = "Invalid StoragePath specified."
            let recoverySuggestion = "Please specify a valid StoragePath."
            throw StorageError.validation("path", errorDescription, recoverySuggestion, nil)
        }
    }

    func validate(_ path: String) throws {
        if !path.hasPrefix("/") {
            let errorDescription = "Invalid StoragePath specified."
            let recoverySuggestion = "Please specify a valid StoragePath that contains the prefix / "
            throw StorageError.validation(path, errorDescription, recoverySuggestion, nil)
        }
    }
}
