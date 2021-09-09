//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Resolves the final prefix prepended to the S3 key for a given request.
public protocol AWSS3PluginPrefixResolver {
    func resolvePrefix(for accessLevel: StorageAccessLevel, targetIdentityId: String?) -> Result<String, StorageError>
}

/// Convenience resolver. Resolves the provided key as-is, with no manipulation
public struct PassThroughPrefixResolver: AWSS3PluginPrefixResolver {
    public func resolvePrefix(for accessLevel: StorageAccessLevel,
                              targetIdentityId: String?) -> Result<String, StorageError> {
        return .success("")
    }
}

/// AWSS3StoragePlugin default logic
struct StorageAccessLevelAwarePrefixResolver: AWSS3PluginPrefixResolver {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func resolvePrefix(for accessLevel: StorageAccessLevel,
                              targetIdentityId: String?) -> Result<String, StorageError> {
        let identityIdResult = authService.getIdentityId()
        switch identityIdResult {
        case .success(let identityId):
            let prefix = StorageRequestUtils.getAccessLevelPrefix(accessLevel: accessLevel,
                                                                  identityId: identityId,
                                                                  targetIdentityId: targetIdentityId)
            return .success(prefix)
        case .failure(let error):
            return .failure(StorageError.authError(error.errorDescription, error.recoverySuggestion))
        }
    }
}
