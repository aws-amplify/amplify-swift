//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify

public protocol AWSAuthServiceBehavior: AnyObject {

    func getCredentialsProvider() -> AWSCredentialsProvider

    @available(*, deprecated, message: "Use getIdentityId(completion: (Result<String, AuthError>) -> Void) instead")
    func getIdentityId() -> Result<String, AuthError>

    @available(*, deprecated, message: "Use getToken(completion: (Result<String, AuthError>) -> Void) instead")
    func getToken() -> Result<String, AuthError>

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>

    /// Retrieves the identity identifier of for the Auth service
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getIdentityId(completion: @escaping (Result<String, AuthError>) -> Void)

    /// Retrieves the token from the Auth token provider
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getToken(completion: @escaping (Result<String, AuthError>) -> Void)
}

extension AWSAuthServiceBehavior {
    /// Retrieves the identity identifier of for the Auth service
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    /// - Note: This default implementation was added to prevent a breaking change,
    /// and will be removed when the blocking API versions are removed.
    public func getIdentityId(completion: @escaping (Result<String, AuthError>) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let identityIdResult = self?.getIdentityId() else { return }
            completion(identityIdResult)
        }
    }

    /// Retrieves the token from the Auth token provider
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    /// - Note: This default implementation was added to prevent a breaking change,
    ///  and will be removed when the blocking API versions are removed.
    public func getToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let tokenResult = self?.getToken() else { return }
            completion(tokenResult)
        }
    }
}
