//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// What a hosted-UI sign-in checks about the tokens it gets back, before it signs anyone in.
///
/// Carried by `HostedUIEnvironment.identityPolicy`, not by `HostedUIOptions`, so it is never stored or logged
/// with the sign-in method. `AmplifyCognitoClient` builds an environment per operation, which makes it a
/// per-flow input there. The plugin never sets it, and `.none` verifies nothing, which is the plugin's
/// behaviour. The client always verifies the token claims and may add an expectation.
package struct HostedUIIdentityPolicy: Sendable, Equatable {

    /// Checks that the token response belongs to this flow and this app: the id token's `token_use`,
    /// `aud` and `iss`, and its `nonce` when the flow sent one. (That the id token's `sub` is the user the
    /// sign-in stores is checked under every active policy.) The expiry and the signature are not checked: the tokens come straight from the token endpoint
    /// over TLS, bound to this flow by PKCE, and a wrong device clock must not block sign-in.
    package let verifiesTokenClaims: Bool

    /// When set, the returned user must be this one: equal to the returned `sub`, or to the returned
    /// username. Compared exactly.
    package let expectedIdentity: String?

    /// The returned `sub` must not be one of these: the users signed in to the caller's other sessions.
    package let excludedSubjects: Set<String>

    package init(
        verifiesTokenClaims: Bool,
        expectedIdentity: String? = nil,
        excludedSubjects: Set<String> = []
    ) {
        self.verifiesTokenClaims = verifiesTokenClaims
        self.expectedIdentity = expectedIdentity
        self.excludedSubjects = excludedSubjects
    }

    /// Verifies nothing.
    package static let none = HostedUIIdentityPolicy(verifiesTokenClaims: false)

    package var isNone: Bool {
        !verifiesTokenClaims && expectedIdentity == nil && excludedSubjects.isEmpty
    }
}

/// Why a hosted-UI sign-in was refused after the token exchange. Carried by
/// `HostedUIError.unexpectedIdentity`, and the underlying error of its `EngineAuthError`.
///
/// The returned identity is kept in fields, never in the description, so logging the error does not log it.
package struct HostedUIIdentityMismatch: Error, Sendable, Equatable {

    package enum Reason: String, Sendable, Equatable, CaseIterable {
        /// The id token's `token_use` is not `id`.
        case tokenUse
        /// The id token's `aud` does not name the hosted-UI app client.
        case audience
        /// The id token's `iss` is not this user pool.
        case issuer
        /// The id token does not carry the nonce this flow sent.
        case nonce
        /// The id token's `sub` is not the user the sign-in would store (read from the access token).
        case subject
        /// The id token names no user (`sub` missing or empty).
        case missingIdentity
        /// The user is not the expected one.
        case notExpectedIdentity
        /// The user is signed in to another of the caller's sessions.
        case signedInToAnotherSession
    }

    package let reason: Reason

    /// The expectation that was not met, for `notExpectedIdentity`.
    package let expected: String?

    /// The username that came back, when it could be read.
    package let returnedUsername: String?

    /// The `sub` that came back, when it could be read.
    package let returnedUserId: String?

    package init(
        reason: Reason,
        expected: String? = nil,
        returnedUsername: String? = nil,
        returnedUserId: String? = nil
    ) {
        self.reason = reason
        self.expected = expected
        self.returnedUsername = returnedUsername
        self.returnedUserId = returnedUserId
    }

    /// Whether a real user came back, just not the one wanted, as opposed to a response that could not be
    /// attributed to this flow at all.
    package var isIdentityMismatch: Bool {
        switch reason {
        case .notExpectedIdentity, .signedInToAnotherSession:
            return true
        case .tokenUse, .audience, .issuer, .nonce, .subject, .missingIdentity:
            return false
        }
    }

    // The strings live here rather than in `AuthPluginErrorConstants`, whose entries are pinned by the locked
    // error catalogue.

    package static let identityMismatchDescription =
        "The hosted UI sign-in returned a different user than the one expected, so nobody was signed in."

    package static let unverifiedResponseDescription =
        "The hosted UI sign-in response could not be verified for this sign-in, so nobody was signed in."

    package static let recoverySuggestion = """
    Sign in again with the prompt option set to login, so the browser asks for credentials instead of reusing \
    a saved sign-in.
    """

    package var errorDescription: String {
        isIdentityMismatch ? Self.identityMismatchDescription : Self.unverifiedResponseDescription
    }
}

// Every printed form names the reason only. The mismatch is the underlying error of an `EngineAuthError`, whose
// `debugDescription` interpolates it, and it sits in `HostedUISignInState.error`, which verbose logs dump, so
// default printing or reflection would log the expected and returned users.
extension HostedUIIdentityMismatch: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    package var description: String {
        "HostedUIIdentityMismatch(reason: \(reason.rawValue))"
    }

    package var debugDescription: String {
        description
    }

    package var customMirror: Mirror {
        Mirror(self, children: ["reason": reason.rawValue], displayStyle: .struct)
    }
}

/// Checks a hosted-UI token response against a `HostedUIIdentityPolicy`. Pure: no I/O and no clock.
package enum HostedUIIdentityVerifier {

    /// Where a flow's id token must say it comes from: the nonce the flow sent, the app client it is for, and
    /// the user pool that issued it.
    package struct TokenOrigin: Sendable, Equatable {
        /// The nonce this flow sent, if any.
        package let expectedNonce: String?
        /// The hosted-UI app client, which the id token's `aud` must name.
        package let hostedUIClientId: String
        /// The user pool, which the id token's `iss` must name. The issuer's region is the pool ID's prefix
        /// (`us-east-1_…`), which is where Cognito issues from, whatever region is configured.
        package let userPoolId: String
        /// The configured region, used only for a pool ID without a region prefix.
        package let region: String

        package init(expectedNonce: String?, hostedUIClientId: String, userPoolId: String, region: String) {
            self.expectedNonce = expectedNonce
            self.hostedUIClientId = hostedUIClientId
            self.userPoolId = userPoolId
            self.region = region
        }
    }

    /// - Parameters:
    ///   - idToken: The id token from the token response.
    ///   - storedUserId: The user ID the sign-in will store (`SignedInData.userId`, read from the access token,
    ///     `"unknown"` when that could not be read). It must be the id token's `sub`, so the identity verified
    ///     here is exactly the identity stored.
    ///   - storedUsername: The username the sign-in will store (`SignedInData.username`).
    ///   - policy: What to check. `.none` returns at once without reading anything.
    ///   - origin: The nonce, app client and user pool the id token's claims must name.
    /// - Throws: `HostedUIError.tokenParsing` for an id token that cannot be read, or
    ///   `HostedUIError.unexpectedIdentity` for the first check that fails.
    package static func verify(
        idToken: String,
        storedUserId: String,
        storedUsername: String,
        policy: HostedUIIdentityPolicy,
        origin: TokenOrigin
    ) throws {
        guard !policy.isNone else {
            return
        }
        guard let idClaims = claims(of: idToken) else {
            throw HostedUIError.tokenParsing
        }
        let userId = nonEmptyString(idClaims["sub"])
        let username = usable(storedUsername) ?? nonEmptyString(idClaims["cognito:username"])

        func mismatch(_ reason: HostedUIIdentityMismatch.Reason, expected: String? = nil) -> HostedUIError {
            .unexpectedIdentity(HostedUIIdentityMismatch(
                reason: reason,
                expected: expected,
                returnedUsername: username,
                returnedUserId: userId
            ))
        }

        if policy.verifiesTokenClaims, let reason = firstUnmatchedClaim(of: idClaims, origin: origin) {
            throw mismatch(reason)
        }

        guard let userId else {
            throw mismatch(.missingIdentity)
        }
        // Under every active policy: what is checked below must be what gets stored. An access token that
        // cannot be read stores `"unknown"`, which never equals a `sub`.
        guard storedUserId == userId else {
            throw mismatch(.subject)
        }
        if let expected = policy.expectedIdentity, expected != userId, expected != username {
            throw mismatch(.notExpectedIdentity, expected: expected)
        }
        if policy.excludedSubjects.contains(userId) {
            throw mismatch(.signedInToAnotherSession)
        }
    }

    /// The region an issuer names for a pool: the pool ID's prefix, else the configured region.
    package static func issuerRegion(userPoolId: String, configuredRegion: String) -> String {
        guard let separator = userPoolId.firstIndex(of: "_"), separator != userPoolId.startIndex else {
            return configuredRegion
        }
        return String(userPoolId[..<separator])
    }

    /// The payload claims of a JWT, or `nil` if it is not a readable JWT. Decodes base64url with or without
    /// padding, as `TokenParserHelper` does.
    package static func claims(of token: String) -> [String: Any]? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 2 else {
            return nil
        }
        let base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddedLength = base64.count + (4 - (base64.count % 4)) % 4
        let padded = base64.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        guard let data = Data(base64Encoded: padded),
              let object = try? JSONSerialization.jsonObject(with: data),
              let claims = object as? [String: Any] else {
            return nil
        }
        return claims
    }

    /// The first of the id token's `token_use`, `aud`, `iss` and `nonce` claims, checked in that order, that
    /// does not match `origin`, or `nil` when they all do. The `nonce` is checked only when the flow sent one.
    private static func firstUnmatchedClaim(
        of idClaims: [String: Any],
        origin: TokenOrigin
    ) -> HostedUIIdentityMismatch.Reason? {
        guard idClaims["token_use"] as? String == "id" else {
            return .tokenUse
        }
        guard audience(of: idClaims).contains(origin.hostedUIClientId) else {
            return .audience
        }
        guard let issuer = idClaims["iss"] as? String,
              isIssuer(issuer, userPoolId: origin.userPoolId, region: origin.region) else {
            return .issuer
        }
        if let expectedNonce = origin.expectedNonce, idClaims["nonce"] as? String != expectedNonce {
            return .nonce
        }
        return nil
    }

    /// A stored username that names someone: not empty, and not `SignedInData`'s `"unknown"` fallback.
    private static func usable(_ storedUsername: String) -> String? {
        storedUsername.isEmpty || storedUsername == "unknown" ? nil : storedUsername
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else {
            return nil
        }
        return string
    }

    /// `aud` is a string for Cognito, and may be an array under OIDC.
    private static func audience(of claims: [String: Any]) -> [String] {
        if let audience = claims["aud"] as? String {
            return [audience]
        }
        return claims["aud"] as? [String] ?? []
    }

    /// `https://cognito-idp.<region>.amazonaws.com/<poolId>`, or the `.com.cn` partition's form, where the
    /// region is the pool ID's prefix. A custom endpoint does not change the issuer.
    private static func isIssuer(_ issuer: String, userPoolId: String, region: String) -> Bool {
        let issuerRegion = issuerRegion(userPoolId: userPoolId, configuredRegion: region)
        let host = "cognito-idp.\(issuerRegion).amazonaws.com"
        return issuer == "https://\(host)/\(userPoolId)" || issuer == "https://\(host).cn/\(userPoolId)"
    }
}
