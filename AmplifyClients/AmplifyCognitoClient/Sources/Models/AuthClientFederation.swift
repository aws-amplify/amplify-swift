//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Options for `AmplifyCognitoClient.federateToIdentityPool(withProviderToken:for:options:)`.
///
/// Mirrors the plugin's `AuthFederateToIdentityPoolRequest.Options`.
@_spi(AmplifyExperimental)
public struct AuthClientFederateToIdentityPoolOptions {

    /// An identity ID the developer's backend already obtained for this user, to use instead of asking
    /// the identity pool for one. The plugin's `developerProvidedIdentityID`.
    public var developerProvidedIdentityId: String?

    public init(developerProvidedIdentityId: String? = nil) {
        self.developerProvidedIdentityId = developerProvidedIdentityId
    }
}

extension AuthClientFederateToIdentityPoolOptions: Equatable {}

extension AuthClientFederateToIdentityPoolOptions: Sendable {}

/// The outcome of `federateToIdentityPool`.
///
/// Mirrors the plugin's `FederateToIdentityPoolResult`.
@_spi(AmplifyExperimental)
public struct AuthClientFederateToIdentityPoolResult {

    /// The federated identity's AWS credentials.
    public let credentials: AuthClientAWSCredentials

    /// The federated identity's ID.
    public let identityId: String

    /// Public so an app can build one for a test double; the client builds its own.
    public init(credentials: AuthClientAWSCredentials, identityId: String) {
        self.credentials = credentials
        self.identityId = identityId
    }
}

extension AuthClientFederateToIdentityPoolResult: Equatable {}

extension AuthClientFederateToIdentityPoolResult: Sendable {}
