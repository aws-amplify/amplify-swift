//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// - Note: `Sendable` because auth services are held by plugins (themselves `Sendable`) and reached
///   from concurrent request paths.
public protocol AWSAuthServiceBehavior: AnyObject, Sendable {

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>

    /// Retrieves the identity identifier of for the Auth service
    func getIdentityID() async throws -> String

    /// Retrieves the token from the Auth token provider
    func getUserPoolAccessToken() async throws -> String
}
