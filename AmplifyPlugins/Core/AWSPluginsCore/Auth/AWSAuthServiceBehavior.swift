//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime

public protocol AWSAuthServiceBehavior: AnyObject {

    func getCredentialsProvider() -> CredentialsProvider

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>

    /// Retrieves the identity identifier of for the Auth service
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getIdentityID(completion: @escaping (Result<String, AuthError>) -> Void)

    /// Retrieves the token from the Auth token provider
    /// - Parameter completion: Completion handler defined for the input `Result<String, AuthError>`
    func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void)
}

//    // MARK: List of Amplify internal usages of now deprecated AWSAuthServiceBehavior methods.
//    /**
//     `StorageAccessLevelAwarePrefixResolver`
//        - File Path: `AmplifyPlugins/Storage/AWSS3StoragePlugin/Configuration/AWSS3PluginPrefixResolver.swift`
//        - Uses: `getIdentityId()`
//
//     `IncomingAsyncSubscriptionEventPublisher`
//        - File Path: `AmplifyPlugins/Core/AWSPluginsCore/Auth/AWSAuthServiceBehavior.swift`
//        - Uses: `getToken()`
//
//     `BasicUserPoolTokenProvider`
//        - File Path: `AmplifyPlugins/Core/AWSPluginsCore/Auth/Provider/AuthTokenProvider.swift`
//        - Uses: `getToken()`
//
//     `AWSOIDCAuthProvider`
//        - File Path: `AmplifyPlugins/API/AWSAPICategoryPlugin/SubscriptionFactory/AWSOIDCAuthProvider.swift`
//        - Uses: `getToken()`
//
//     `AWSAuthServiceBehavior` protocol extension.
//        Default implementation of new completion handler APIs to prevent breaking change.
//         - File Path: `AmplifyPlugins/Core/AWSPluginsCore/Auth/AWSAuthServiceBehavior.swift`
//         - Uses: `getToken()`, `getIdentityId()`
//     */

