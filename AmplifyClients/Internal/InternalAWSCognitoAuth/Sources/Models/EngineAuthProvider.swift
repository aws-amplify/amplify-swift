//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of `Amplify.AuthProvider` (`Amplify/Categories/Auth/Models/AuthProvider.swift`).
///
/// It is persisted through `FederatedToken.provider`, with synthesized `Codable`: the case name is the
/// key, and the payloads are left unlabeled so they encode as `_0` (`{"oidc":{"_0":"name"}}`,
/// `{"amazon":{}}`), exactly as the public type does. Case names, payloads and the synthesized `==`
/// match the public type. The plugin converts case to case in
/// `AWSCognitoAuthPlugin/Support/EngineBridge/AuthProvider+Engine.swift`.
package enum EngineAuthProvider: Sendable {

    package typealias ProviderName = String

    /// Auth provider that uses Login with Amazon
    case amazon

    /// Auth provider that uses Sign in with Apple
    case apple

    /// Auth provider that uses Facebook Login
    case facebook

    /// Auth provider that uses Google Sign-In
    case google

    /// Auth provider that uses Twitter Sign-In
    case twitter

    /// Auth provider that uses OpenID Connect Protocol
    case oidc(ProviderName)

    /// Auth provider that uses Security Assertion Markup Language standard
    case saml(ProviderName)

    /// Custom auth provider that is not in this list, the associated string value will be the identifier used by
    /// the plugin service.
    case custom(ProviderName)
}

extension EngineAuthProvider: Codable { }

extension EngineAuthProvider: Equatable { }
