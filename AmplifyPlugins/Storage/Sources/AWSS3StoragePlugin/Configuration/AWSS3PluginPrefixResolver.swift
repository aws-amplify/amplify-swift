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
    func resolvePrefix(for accessLevel: StorageAccessLevel,
                       targetIdentityId: String?) async throws -> String
}

/// Convenience resolver. Resolves the provided key as-is, with no manipulation
public struct PassThroughPrefixResolver: AWSS3PluginPrefixResolver {
    public func resolvePrefix(for accessLevel: StorageAccessLevel,
                              targetIdentityId: String?) async throws -> String {
        ""
    }
}

/// AWSS3StoragePlugin default logic
struct StorageAccessLevelAwarePrefixResolver: AWSS3PluginPrefixResolver {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    func resolvePrefix(for accessLevel: StorageAccessLevel,
                       targetIdentityId: String?) async throws -> String {
        do {
            let identityId = try await authService.getIdentityID()
            let prefix = StorageRequestUtils.getAccessLevelPrefix(accessLevel: accessLevel,
                                                                  identityId: identityId,
                                                                  targetIdentityId: targetIdentityId)
            return prefix
        } catch {
            guard let authError = error as? AuthError else {
                throw StorageError.unknown("Unknown Auth Error", error)
            }
            throw StorageError.authError(authError.errorDescription, authError.recoverySuggestion)
        }
    }
}
