//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime

public protocol AWSAuthServiceBehavior: AnyObject {

    func getCredentialsProvider() -> CredentialsProvider

    // TODO: Remove this after 
    @available(*, deprecated, message: "Use getUserPoolAccessToken(completion:) instead")
    func getToken() -> Result<String, AuthError>

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>

    /// Retrieves the identity identifier of for the Auth service
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getIdentityID(completion: @escaping (Result<String, AuthError>) -> Void)

    /// Retrieves the token from the Auth token provider
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void)
}


    // MARK: List of Amplify internal usages of now deprecated AWSAuthServiceBehavior methods.
    /**
     `BasicUserPoolTokenProvider`
        - File Path: `AmplifyPlugins/Core/AWSPluginsCore/Auth/Provider/AuthTokenProvider.swift`
        - Uses: `getToken()`
     `AWSOIDCAuthProvider`
        - File Path: `AmplifyPlugins/API/AWSAPICategoryPlugin/SubscriptionFactory/AWSOIDCAuthProvider.swift`
        - Uses: `getToken()`
     */

