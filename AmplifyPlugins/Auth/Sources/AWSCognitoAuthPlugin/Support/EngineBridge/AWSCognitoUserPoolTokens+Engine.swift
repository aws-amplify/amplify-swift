//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// Conversions between the public `AWSCognitoUserPoolTokens` and the engine's `EngineUserPoolTokens`.
// Both directions copy the four stored properties as they are, so a round trip in either direction gives an equal value. `expiration` is copied, never recomputed.

extension AWSCognitoUserPoolTokens {

    /// The public value of engine tokens, for the plugin's API (`AWSAuthCognitoSession`). Goes through the
    /// public `init(idToken:accessToken:refreshToken:expiration:)`, so the value is kept exactly.
    init(_ tokens: EngineUserPoolTokens) {
        self = makeTokens(Self.self, from: tokens)
    }
}

extension EngineUserPoolTokens {

    /// The engine value of public tokens.
    init(_ tokens: AWSCognitoUserPoolTokens) {
        self.init(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiration: deprecatedExpiration(of: tokens)
        )
    }
}

// `AWSCognitoUserPoolTokens.expiration` and `init(idToken:accessToken:refreshToken:expiration:)` are
// deprecated for apps, but the conversion has to copy the expiration. Reaching both through this
// protocol keeps the conversion free of deprecation warnings without marking its callers deprecated.
private protocol DeprecatedUserPoolTokensMembers {
    init(idToken: String, accessToken: String, refreshToken: String, expiration: Date)
    var expiration: Date { get }
}

extension AWSCognitoUserPoolTokens: DeprecatedUserPoolTokensMembers { }

private func makeTokens<Tokens: DeprecatedUserPoolTokensMembers>(
    _: Tokens.Type,
    from tokens: EngineUserPoolTokens
) -> Tokens {
    Tokens(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiration: tokens.expiration
    )
}

private func deprecatedExpiration(of tokens: some DeprecatedUserPoolTokensMembers) -> Date {
    tokens.expiration
}
