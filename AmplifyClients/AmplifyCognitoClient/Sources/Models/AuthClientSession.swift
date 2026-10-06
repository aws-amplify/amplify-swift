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
public struct AuthClientFetchSessionOptions {

    /// Refreshes the session's credentials even if they are still valid. A refresh already in flight
    /// for this session is joined rather than duplicated.
    public var forceRefresh: Bool

    /// - Parameter forceRefresh: Whether to refresh credentials that are still valid. `false` by default.
    public init(forceRefresh: Bool = false) {
        self.forceRefresh = forceRefresh
    }
}

extension AuthClientFetchSessionOptions: Equatable {}

extension AuthClientFetchSessionOptions: Sendable {}

/// What `fetchAuthSession` found: the session's credentials, each field with its own result.
///
/// Mirrors the plugin's `AWSAuthCognitoSession`, without its `isSignedIn`: whether a user is signed in is
/// the session's state, `currentSessionState()`, which also tells a guest and a storage failure apart. A
/// field fails when the session cannot provide it — for
/// example, the user pool tokens of a guest session, or the AWS credentials of a session with no identity
/// pool — or when refreshing it failed. `fetchAuthSession` itself throws only for failures that are not
/// per field: storage could not be read, the session's record is unusable, or the caller was cancelled.
@_spi(AmplifyExperimental)
public struct AuthClientSession {

    /// The identity pool identity ID.
    public let identityIdResult: Result<String, AuthClientError>

    /// The identity pool's temporary AWS credentials.
    public let awsCredentialsResult: Result<AuthClientAWSCredentials, AuthClientError>

    /// The signed-in user's `sub`.
    public let userSubResult: Result<String, AuthClientError>

    /// The user pool tokens. The plugin's `userPoolTokensResult` (its initializer's
    /// `cognitoTokensResult`).
    public let userPoolTokensResult: Result<AuthClientUserPoolTokens, AuthClientError>

    /// Public so an app can build one for a test double; the client builds its own.
    public init(
        identityIdResult: Result<String, AuthClientError>,
        awsCredentialsResult: Result<AuthClientAWSCredentials, AuthClientError>,
        userSubResult: Result<String, AuthClientError>,
        userPoolTokensResult: Result<AuthClientUserPoolTokens, AuthClientError>
    ) {
        self.identityIdResult = identityIdResult
        self.awsCredentialsResult = awsCredentialsResult
        self.userSubResult = userSubResult
        self.userPoolTokensResult = userPoolTokensResult
    }
}

extension AuthClientSession: Sendable {}

extension AuthClientSession: Equatable {

    /// Values compare exactly. Errors compare as `AuthSessionState.failed` does: same case, structured
    /// payload, description and suggestion; the underlying error is not compared.
    public static func == (lhs: AuthClientSession, rhs: AuthClientSession) -> Bool {
        equivalent(lhs.identityIdResult, rhs.identityIdResult)
            && equivalent(lhs.awsCredentialsResult, rhs.awsCredentialsResult)
            && equivalent(lhs.userSubResult, rhs.userSubResult)
            && equivalent(lhs.userPoolTokensResult, rhs.userPoolTokensResult)
    }

    private static func equivalent<Value: Equatable>(
        _ lhs: Result<Value, AuthClientError>,
        _ rhs: Result<Value, AuthClientError>
    ) -> Bool {
        switch (lhs, rhs) {
        case (.success(let left), .success(let right)):
            return left == right
        case (.failure(let left), .failure(let right)):
            return left.isEquivalent(to: right)
        default:
            return false
        }
    }
}

/// A signed-in session's user pool tokens.
///
/// Mirrors the plugin's `AWSCognitoUserPoolTokens`, without its deprecated `expiration`: each token
/// carries its own expiry claim.
@_spi(AmplifyExperimental)
public struct AuthClientUserPoolTokens {

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

extension AuthClientUserPoolTokens: Equatable {}

extension AuthClientUserPoolTokens: Sendable {}

extension AuthClientUserPoolTokens: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted, like the plugin's: tokens never reach a log through string interpolation.
    public var debugDescription: String {
        "AuthClientUserPoolTokens(idToken: <redacted>, accessToken: <redacted>, refreshToken: <redacted>)"
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
public struct AuthClientAWSCredentials: AWSTemporaryCredentials {

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

extension AuthClientAWSCredentials: Equatable {}

extension AuthClientAWSCredentials: Sendable {}

extension AuthClientAWSCredentials: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Redacted: the secret and the session token never reach a log through string interpolation.
    public var debugDescription: String {
        "AuthClientAWSCredentials(accessKeyId: \(maskedAccessKeyId), secretAccessKey: <redacted>, sessionToken: <redacted>, expiration: \(expiration))"
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
