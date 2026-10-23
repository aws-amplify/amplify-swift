//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A federated identity provider: the one to send a hosted-UI sign-in straight to, or the one whose token
/// `federateToIdentityPool(withProviderToken:for:options:)` exchanges.
///
/// Mirrors Amplify core's `AuthProvider` case for case, which this client cannot import. Two uses:
/// - `federateToIdentityPool(withProviderToken:for:options:)`, on every platform: the provider whose token
///   is exchanged for identity pool credentials;
/// - `WebUIOptions.provider`, on iOS, macOS and visionOS, where the hosted UI is: skips Cognito's provider
///   picker, as the plugin's `signInWithWebUI(for:presentationAnchor:options:)` overload does.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientProvider {

    /// A provider name, which means one thing for each use:
    /// - for `WebUIOptions.provider`, the provider's name as configured on the user pool;
    /// - for `federateToIdentityPool(withProviderToken:for:options:)`, the identity pool's login key for the
    ///   provider, sent unchanged as the key of the identity pool's `Logins` map: the issuer host for OIDC
    ///   (`mycorp.auth0.com`), the provider's ARN for SAML, and for any other provider the key the identity pool
    ///   expects (`cognito-idp.<region>.amazonaws.com/<user pool ID>` for a user pool, for example).
    ///
    /// So the same provider usually has a different name for each use.
    public typealias ProviderName = String

    /// Login with Amazon.
    case amazon

    /// Sign in with Apple.
    case apple

    /// Facebook Login.
    case facebook

    /// Google Sign-In.
    case google

    /// Twitter Sign-In.
    case twitter

    /// An OpenID Connect provider: by the name configured on the user pool for `WebUIOptions.provider`, by its
    /// issuer host (`mycorp.auth0.com`) for `federateToIdentityPool` (`ProviderName`).
    case oidc(ProviderName)

    /// A SAML provider: by the name configured on the user pool for `WebUIOptions.provider`, by its ARN for
    /// `federateToIdentityPool` (`ProviderName`).
    case saml(ProviderName)

    /// Any other provider: by the name configured on the user pool for `WebUIOptions.provider`, by the identity
    /// pool's login key for it for `federateToIdentityPool` (`ProviderName`).
    case custom(ProviderName)
}

extension AuthClientProvider: Sendable {}

extension AuthClientProvider: Hashable {}
