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

    // TODO: Remove this after calls to it are removed from API and DataStore plugins
    // MARK: List of Amplify internal usages of now deprecated AWSAuthServiceBehavior methods.
    /**
     `IncomingAsyncSubscriptionEventPublisher`
        - File Path: `AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin/Sync/SubscriptionSync/IncomingAsyncSubscriptionEventPublisher.swift`
        - Uses: `getToken()`
     `AWSOIDCAuthProvider`
        - File Path: `AmplifyPlugins/API/AWSAPICategoryPlugin/SubscriptionFactory/AWSOIDCAuthProvider.swift`
        - Uses: `getToken()`
     */
    @available(*, deprecated, renamed: "getUserPoolAccessToken")
    func getToken() -> Result<String, AuthError>

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>

    /// Retrieves the identity identifier of for the Auth service
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getIdentityID(completion: @escaping (Result<String, AuthError>) -> Void)
    
    /// Retrieves the token from the Auth token provider
    func getUserPoolAccessToken() async throws -> String
}
