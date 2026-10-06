//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundationBridge
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import SmithyHTTPAPI

/// The SDK clients one session owns, shared by its engine and returned by the escape hatches.
///
/// Built once, when the session's core is built. Each is `nil` when its pool is not configured.
struct CognitoServiceClients: Sendable {

    let userPool: CognitoIdentityProviderClient?
    let identity: CognitoIdentityClient?

    init(userPool: CognitoIdentityProviderClient?, identity: CognitoIdentityClient?) {
        self.userPool = userPool
        self.identity = identity
    }

    /// Builds the clients for `configuration`, applying `configureUserPoolClient` to the user pool
    /// client's configuration.
    ///
    /// Each configuration is built at parity with the plugin's (`AWSCognitoAuthPlugin+Configure.swift`):
    /// the pool's region, an explicit `signingRegion` equal to it, and a credential identity resolver that
    /// always throws (`CognitoUnsignedOperationResolver`), because every operation the client calls is
    /// unsigned. `configureUserPoolClient` runs after those are set, so it sees them and can override any
    /// of them. Every HTTP engine is then wrapped in `UserAgentClientEngine`, after the closure, so a
    /// custom engine is wrapped too.
    ///
    /// Synchronous and cheap: it builds SDK configurations and clients, which make no network call.
    /// The escape-hatch closure is invoked here, synchronously, and never stored.
    ///
    /// - Parameter baseHTTPClientEngine: The engine both clients send through, inside the user-agent
    ///   wrapper. `nil` (the SDK default) everywhere but tests. The escape hatch can still replace it for
    ///   the user pool client.
    /// - Throws: whatever the SDK's configuration throws. The facade maps it to
    ///   `AuthClientError.configuration`.
    init(
        configuration: AuthClientConfiguration,
        configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider?,
        baseHTTPClientEngine: (any HTTPClient)? = nil
    ) throws {
        if let userPool = configuration.userPool {
            var config = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(
                awsCredentialIdentityResolver: CognitoUnsignedOperationResolver(for: .userPool),
                region: userPool.region,
                signingRegion: userPool.region,
                httpClientEngine: baseHTTPClientEngine
            )
            configureUserPoolClient?(&config)
            config.httpClientEngine = Self.userAgentEngine(wrapping: config.httpClientEngine)
            self.userPool = CognitoIdentityProviderClient(config: config)
        } else {
            self.userPool = nil
        }

        if let identityPool = configuration.identityPool {
            var config = try CognitoIdentityClient.CognitoIdentityClientConfig(
                awsCredentialIdentityResolver: CognitoUnsignedOperationResolver(for: .identity),
                region: identityPool.region,
                signingRegion: identityPool.region,
                httpClientEngine: baseHTTPClientEngine
            )
            config.httpClientEngine = Self.userAgentEngine(wrapping: config.httpClientEngine)
            self.identity = CognitoIdentityClient(config: config)
        } else {
            self.identity = nil
        }
    }

    /// The user pool client of a previous configuration, for the revoke of a login saved under it: its
    /// region, unsigned, with the user agent, as `init(configuration:configureUserPoolClient:)` builds it, and its
    /// custom endpoint if it recorded one (a Gen1 plugin configuration can), as the plugin's own client does. **No
    /// escape hatch:** the app's `configureUserPoolClient` belongs to the current configuration's session and is not
    /// applied here. No identity client: a revoke never calls one.
    init(previous configuration: AuthConfiguration, baseHTTPClientEngine: (any HTTPClient)? = nil) throws {
        if let userPool = configuration.getUserPoolConfiguration() {
            var config = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(
                awsCredentialIdentityResolver: CognitoUnsignedOperationResolver(for: .userPool),
                region: userPool.region,
                signingRegion: userPool.region,
                endpointResolver: userPool.endpoint?.resolver,
                httpClientEngine: baseHTTPClientEngine
            )
            config.httpClientEngine = Self.userAgentEngine(wrapping: config.httpClientEngine)
            self.userPool = CognitoIdentityProviderClient(config: config)
        } else {
            self.userPool = nil
        }
        self.identity = nil
    }

    /// Appends `lib/amplify-swift#<version> md/amplify-cognito#<version>` to the `User-Agent`. The `lib/`
    /// token is the plugin's (`AmplifyAWSServiceConfiguration.userAgentLib`) exactly, which is what
    /// attribution keys on; `md/amplify-cognito` follows the family (`md/amplify-kinesis`).
    private static func userAgentEngine(wrapping target: any HTTPClient) -> any HTTPClient {
        UserAgentClientEngine(target: target, additionalMetadata: ["md/amplify-cognito"])
    }
}
