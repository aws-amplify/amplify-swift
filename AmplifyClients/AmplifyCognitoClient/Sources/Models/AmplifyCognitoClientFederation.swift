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
public struct AmplifyCognitoClientFederateToIdentityPoolOptions {

    /// An identity ID the developer's backend already obtained for this user, to use instead of asking
    /// the identity pool for one. The plugin's `developerProvidedIdentityID`.
    public let developerProvidedIdentityId: String?

    public init(developerProvidedIdentityId: String? = nil) {
        self.developerProvidedIdentityId = developerProvidedIdentityId
    }
}

extension AmplifyCognitoClientFederateToIdentityPoolOptions: Equatable {}

extension AmplifyCognitoClientFederateToIdentityPoolOptions: Sendable {}

/// The outcome of `federateToIdentityPool`.
///
/// Mirrors the plugin's `FederateToIdentityPoolResult`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientFederateToIdentityPoolResult {

    /// The federated identity's AWS credentials.
    public let credentials: AmplifyCognitoClientAWSCredentials

    /// The federated identity's ID.
    public let identityId: String

    /// Public so an app can build one for a test double; the client builds its own.
    public init(credentials: AmplifyCognitoClientAWSCredentials, identityId: String) {
        self.credentials = credentials
        self.identityId = identityId
    }
}

extension AmplifyCognitoClientFederateToIdentityPoolResult: Equatable {}

extension AmplifyCognitoClientFederateToIdentityPoolResult: Sendable {}

/// Options for `AmplifyCognitoClient.clearFederationToIdentityPool(options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of the plugin's
/// `AuthClearFederationToIdentityPoolRequest.Options`, which is empty too.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientClearFederationToIdentityPoolOptions {

    /// No options yet.
    public init() {}
}

extension AmplifyCognitoClientClearFederationToIdentityPoolOptions: Equatable {}

extension AmplifyCognitoClientClearFederationToIdentityPoolOptions: Sendable {}
