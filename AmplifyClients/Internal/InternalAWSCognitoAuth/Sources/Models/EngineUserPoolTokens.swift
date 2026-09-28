//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of the plugin's public `AWSCognitoUserPoolTokens`
/// (`AWSCognitoAuthPlugin/Models/AWSCognitoUserPoolTokens.swift`).
///
/// It is persisted inside `SignedInData`, so the stored properties, their names, types and order, the
/// synthesized `Codable` and the synthesized `Equatable` are the public type's. The two types encode to
/// the same JSON tree and decode each other's encoding. The
/// debug output is the public type's too, so log lines that print tokens do not change.
///
/// The public type keeps its `AuthCognitoTokens` conformance in the plugin. The plugin converts between
/// the two in `Support/EngineBridge/AWSCognitoUserPoolTokens+Engine.swift`.
package struct EngineUserPoolTokens {

    package let idToken: String

    package let accessToken: String

    package let refreshToken: String

    package let expiration: Date

    /// The memberwise initializer. The value is kept as given.
    package init(
        idToken: String,
        accessToken: String,
        refreshToken: String,
        expiration: Date
    ) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }

    /// A copy of the public type's internal `init(idToken:accessToken:refreshToken:expiresIn:)`, with
    /// `EngineJWT` in place of `AWSAuthService().getTokenClaims`.
    ///
    /// With `expiresIn`, the expiration is that many seconds from now. Without it, it is the earlier of
    /// the two tokens' `exp` claims, or now when neither token has one.
    package init(
        idToken: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int? = nil
    ) {

        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken

        if let expiresIn {
            self.expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            let expirationDoubleValue: Double
            let idTokenExpiration = try? EngineJWT.claims(idToken).get()["exp"]?.doubleValue
            let accessTokenExpiration = try? EngineJWT.claims(accessToken).get()["exp"]?.doubleValue

            switch (idTokenExpiration, accessTokenExpiration) {
            case (.some(let idTokenValue), .some(let accessTokenValue)):
                expirationDoubleValue = min(idTokenValue, accessTokenValue)
            case (.none, .some(let accessTokenValue)):
                expirationDoubleValue = accessTokenValue
            case (.some(let idTokenValue), .none):
                expirationDoubleValue = idTokenValue
            case (.none, .none):
                expirationDoubleValue = Date().timeIntervalSince1970
            }

            self.expiration = Date(timeIntervalSince1970: TimeInterval(expirationDoubleValue))
        }
    }

    /// A copy of the plugin's `AWSCognitoUserPoolTokens.doesExpire(in:)`
    /// (`Support/Helpers/AuthCognitoTokens+Validation.swift`), with `EngineJWT` in place of
    /// `AWSAuthService().getTokenClaims`.
    ///
    /// Returns `true` when either token's `exp` claim is earlier than `seconds` from `now`, and when either
    /// token's claims cannot be read, so that a refresh is forced. `now` defaults to the current time, which
    /// is the plugin's behaviour; the Cognito client passes its own clock.
    package func doesExpire(in seconds: TimeInterval = 0, at now: Date = Date()) -> Bool {

        guard let idTokenClaims = try? EngineJWT.claims(idToken).get(),
              let accessTokenClaims = try? EngineJWT.claims(accessToken).get(),
              let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
              let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue
        else {
            // If token parsing fails, return as expired, to just force refresh
            return true
        }

        let idTokenExpiry = Date(timeIntervalSince1970: idTokenExpiration)
        let accessTokenExpiry = Date(timeIntervalSince1970: accessTokenExpiration)

        let currentTime = now.addingTimeInterval(seconds)
        return currentTime > idTokenExpiry || currentTime > accessTokenExpiry
    }
}

extension EngineUserPoolTokens: Equatable { }

extension EngineUserPoolTokens: Codable { }

extension EngineUserPoolTokens: Sendable { }

extension EngineUserPoolTokens: CustomDebugDictionaryConvertible {
    /// The same keys and masking as the public type's `debugDictionary`.
    package var debugDictionary: [String: Any] {
        [
            "idToken": idToken.maskedForLog(interiorCount: 5),
            "accessToken": accessToken.maskedForLog(interiorCount: 5),
            "refreshToken": refreshToken.maskedForLog(interiorCount: 5),
            "expiry": expiration
        ]
    }
}

extension EngineUserPoolTokens: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
