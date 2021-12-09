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

/// Provide default conformance to `AWSS3PluginPrefixResolver`
extension AWSS3PluginPrefixResolver {

    /// The default conformance to this method will fail with falal error to indicate that developers, if providing
    /// their own prefix resolver, should conform to the asynchronous version of `resolvePrefix` with completion
    /// closure. The synchronous version existed originally without the async vserion and now has the below default
    /// implementation to allow new conforming classes without the requirement to conform to the synchronous version,
    /// and can conform to just the asynchronous method.
    public func resolvePrefix(for accessLevel: StorageAccessLevel,
                              targetIdentityId: String?) -> Result<String, StorageError> {
        fatalError("Protocol conformance should implement `resolvePrefix(for:targetIdentityId:completion)`.")
    }

    /// The default conformance of the asynchronous method calls the synchronous `resolvePrefix` for backwards
    /// compatibility for developers that originally implemented the synchronous version (which now has the deprecated
    /// flag).
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
                       targetIdentityId: String?,
                       completion: @escaping (Result<String, StorageError>) -> Void) {
        authService.getIdentityID { identityIdResult in
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
}
