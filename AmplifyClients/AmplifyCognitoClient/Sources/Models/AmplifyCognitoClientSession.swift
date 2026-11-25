//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// Options for `AmplifyCognitoClient.fetchAuthSession(options:)`.
///
/// Mirrors Amplify core's `AuthFetchSessionRequest.Options`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientFetchSessionOptions {

    /// Refreshes the session's credentials even if they are still valid. A forced refresh joins only
    /// another forced refresh in flight for this session; it runs after a normal refresh in flight, so it
    /// always calls Cognito.
    public let forceRefresh: Bool

    /// - Parameter forceRefresh: Whether to refresh credentials that are still valid. `false` by default.
    public init(forceRefresh: Bool = false) {
        self.forceRefresh = forceRefresh
    }
}

extension AmplifyCognitoClientFetchSessionOptions: Equatable {}

extension AmplifyCognitoClientFetchSessionOptions: Sendable {}

/// What `fetchAuthSession` found: the session's credentials, as it holds them now.
///
/// The plugin's `AWSAuthCognitoSession` reports each field as a `Result`; here `fetchAuthSession` throws
/// instead, so every field is a plain value, and an expired session can't be taken for a working one. A field
/// is `nil` only when the session has nothing for it: the identity ID and AWS credentials without an identity
/// pool (or for a login made to the user pool only), and the user's `sub` and tokens for a guest or a
/// federated session.
///
/// Without the plugin's `isSignedIn`: whether a user is signed in is the session's state,
/// `currentSessionState()`, which also tells a guest and a storage failure apart.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientSession {

    /// The identity pool identity ID, or `nil` without an identity pool.
    public let identityId: String?

    /// The identity pool's temporary AWS credentials, or `nil` without an identity pool.
    public let awsCredentials: AmplifyCognitoClientAWSCredentials?

    /// The signed-in user's `sub`, or `nil` for a guest or a federated session.
    public let userSub: String?

    /// The user pool tokens, or `nil` for a guest or a federated session. The plugin's `userPoolTokensResult`.
    public let userPoolTokens: AmplifyCognitoClientUserPoolTokens?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(
        identityId: String? = nil,
        awsCredentials: AmplifyCognitoClientAWSCredentials? = nil,
        userSub: String? = nil,
        userPoolTokens: AmplifyCognitoClientUserPoolTokens? = nil
    ) {
        self.identityId = identityId
        self.awsCredentials = awsCredentials
        self.userSub = userSub
        self.userPoolTokens = userPoolTokens
    }
}

extension AmplifyCognitoClientSession: Sendable {}

extension AmplifyCognitoClientSession: Equatable {}

/// A signed-in session's user pool tokens.
///
/// Mirrors the plugin's `AWSCognitoUserPoolTokens`, without its deprecated `expiration`: each token
/// carries its own expiry claim.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientUserPoolTokens {

    /// The ID token: a JWT with the user's identity claims.
    public let idToken: String

    /// The access token: a JWT that authorizes user pool calls for the user.
    public let accessToken: String

    /// The refresh token, which gets new ID and access tokens. Keep it secret.
    public let refreshToken: String

    /// Public so an app can build one for a test double; the client builds its own.
    public init(idToken: String, accessToken: String, refreshToken: String) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

extension AmplifyCognitoClientUserPoolTokens: Equatable {}

extension AmplifyCognitoClientUserPoolTokens: Sendable {}

extension AmplifyCognitoClientUserPoolTokens: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted, like the plugin's: tokens never reach a log through string interpolation.
    public var debugDescription: String {
        "AmplifyCognitoClientUserPoolTokens(idToken: <redacted>, accessToken: <redacted>, refreshToken: <redacted>)"
    }

    public var description: String {
        debugDescription
    }

    /// For `dump` and debuggers: every token redacted.
    public var customMirror: Mirror {
        Mirror(
            self,
            children: ["idToken": "<redacted>", "accessToken": "<redacted>", "refreshToken": "<redacted>"],
            displayStyle: .struct
        )
    }
}

/// Temporary AWS credentials from the identity pool, as `fetchAuthSession` reports them.
///
/// Mirrors the plugin's `AuthAWSCognitoCredentials`, and conforms to AmplifyFoundation's
/// `AWSTemporaryCredentials`, so it can be used wherever the family takes AWS credentials. To sign
/// requests continuously, prefer `credentialsProvider`, which refreshes them.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientAWSCredentials: AWSTemporaryCredentials {

    /// The AWS access key ID.
    public let accessKeyId: String

    /// The AWS secret access key. Keep it secret.
    public let secretAccessKey: String

    /// The session token that goes with the temporary access key.
    public let sessionToken: String

    /// When the credentials expire.
    public let expiration: Date

    /// Public so an app can build one for a test double; the client builds its own.
    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String, expiration: Date) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
        self.expiration = expiration
    }

    init(_ credentials: CognitoAWSCredentials) {
        self.init(
            accessKeyId: credentials.accessKeyId,
            secretAccessKey: credentials.secretAccessKey,
            sessionToken: credentials.sessionToken,
            expiration: credentials.expiration
        )
    }
}

extension AmplifyCognitoClientAWSCredentials: Equatable {}

extension AmplifyCognitoClientAWSCredentials: Sendable {}

extension AmplifyCognitoClientAWSCredentials: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted: the secret and the session token never reach a log through string interpolation.
    public var debugDescription: String {
        "AmplifyCognitoClientAWSCredentials(accessKeyId: \(maskedAccessKeyId), secretAccessKey: <redacted>, sessionToken: <redacted>, expiration: \(expiration))"
    }

    public var description: String {
        debugDescription
    }

    /// For `dump` and debuggers: the key ID masked, the secret and the session token redacted.
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "accessKeyId": maskedAccessKeyId,
                "secretAccessKey": "<redacted>",
                "sessionToken": "<redacted>",
                "expiration": expiration
            ],
            displayStyle: .struct
        )
    }

    /// Masked as the plugin's `AuthAWSCognitoCredentials` masks it.
    private var maskedAccessKeyId: String {
        accessKeyId.maskedForLog(interiorCount: 5)
    }
}
