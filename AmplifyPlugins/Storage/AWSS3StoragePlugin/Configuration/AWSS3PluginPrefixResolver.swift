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
    @available(*, deprecated, message: "Implement resolvePrefix with `completion` instead.")
    func resolvePrefix(for accessLevel: StorageAccessLevel, targetIdentityId: String?) -> Result<String, StorageError>

    func resolvePrefix(for accessLevel: StorageAccessLevel,
                       targetIdentityId: String?,
                       completion: @escaping (Result<String, StorageError>) -> Void)
}

extension AWSS3PluginPrefixResolver {
    public func resolvePrefix(for accessLevel: StorageAccessLevel,
                              targetIdentityId: String?,
                              completion: @escaping (Result<String, StorageError>) -> Void) {
        completion(resolvePrefix(for: accessLevel, targetIdentityId: targetIdentityId))
    }
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

    func resolvePrefix(for accessLevel: StorageAccessLevel,
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

    func resolvePrefix(for accessLevel: StorageAccessLevel,
                       targetIdentityId: String?,
                       completion: @escaping (Result<String, StorageError>) -> Void) {
        let identityIdResult = authService.getIdentityId()
        switch identityIdResult {
        case .success(let identityId):
            let prefix = StorageRequestUtils.getAccessLevelPrefix(accessLevel: accessLevel,
                                                                  identityId: identityId,
                                                                  targetIdentityId: targetIdentityId)
            completion(.success(prefix))
        case .failure(let error):
            completion(.failure(StorageError.authError(error.errorDescription, error.recoverySuggestion)))
        }
    }
}
