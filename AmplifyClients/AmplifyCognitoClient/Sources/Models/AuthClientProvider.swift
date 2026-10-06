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

    /// A provider name as configured on the user pool.
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

    /// An OpenID Connect provider, by the name configured on the user pool.
    case oidc(ProviderName)

    /// A SAML provider, by the name configured on the user pool.
    case saml(ProviderName)

    /// Any other provider, by the name configured on the user pool.
    case custom(ProviderName)
}

extension AuthClientProvider: Sendable {}

extension AuthClientProvider: Hashable {}

extension AuthClientProvider {

    /// The value sent as the `identity_provider` query item of the authorize request.
    ///
    /// The same strings as the plugin's `AuthProvider.userPoolProviderName`
    /// (`InternalAWSCognitoAuth/Support/Helpers/AuthProvider+Cognito.swift`).
    var userPoolProviderName: String {
        switch self {
        case .amazon:
            return "LoginWithAmazon"
        case .apple:
            return "SignInWithApple"
        case .facebook:
            return "Facebook"
        case .google:
            return "Google"
        case .twitter:
            return "Twitter"
        case .oidc(let providerName),
             .saml(let providerName),
             .custom(let providerName):
            return providerName
        }
    }
}
