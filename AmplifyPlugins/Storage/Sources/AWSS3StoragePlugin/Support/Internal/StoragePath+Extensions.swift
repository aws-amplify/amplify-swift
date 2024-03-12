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
    func resolvePath() async throws -> String {
        if self is IdentityIdStoragePath {
            let authService = AWSAuthService()
            let identityId = try await authService.getIdentityID()
            let path = pathResolver(identityId)
            try validate(path)
            return path
        } else {
            let path = pathResolver("")
            try validate(path)
            return path
        }
    }

    func validate(_ path: String) throws {
        if !path.hasPrefix("/") {
            let errorDescription = "Invalid StoragePath specified."
            let recoverySuggestion = "Please specify a valid StoragePath that contains the prefix /."
            throw StorageError.validation(path, errorDescription, recoverySuggestion, nil)
        }
    }
}
