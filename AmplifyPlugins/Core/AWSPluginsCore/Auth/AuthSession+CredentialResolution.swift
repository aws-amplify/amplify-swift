//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// The one place a consumer turns an `AuthSession` into AWS credentials, user pool tokens or an identity ID.
///
/// A session that can vend one of these conforms to the matching provider protocol
/// (`AuthAWSCredentialsProvider`, `AuthCognitoTokensProvider`, `AuthCognitoIdentityProvider`). When it
/// does, the session's own `AuthError` is propagated unchanged: it already says why the value is
/// missing (`AWSCognitoAuthPlugin` reports signed-out, no-identity-pool, expired and keychain
/// failures this way).
///
/// When it does not conform, the session cannot say why, so the reason is derived from what the
/// session *does* expose:
///
/// | Session | Error |
/// |---|---|
/// | `isSignedIn == false` | `AuthError.invalidState` — no one is signed in; a signed-in session may be able to vend the value |
/// | signed in, vends user pool tokens | `AuthError.configuration` — no identity pool is configured (credentials and identity ID only) |
/// | signed in, otherwise | `AuthError.configuration` — the Auth plugin's session type does not vend the value |
///
/// None of these paths produce `AuthError.unknown`. `AWSPluginsCoreTests` scans the plugin sources to
/// keep every credential and token downcast routed through here.
///
/// **Why not `.signedOut` or `.notAuthorized` for a signed-out session.** These errors replace
/// `AuthError.unknown`, and consumers branch on the case. `.signedOut` would make DataStore retry a
/// mutation on its serial queue until sign-in instead of falling back to the next auth type
/// (`SyncMutationToCloudOperation`), and would change `InitialSyncOperation`,
/// `ProcessMutationErrorFromCloudOperation` and Pinpoint's `EventRecorder`. `.notAuthorized` would make
/// `RetryableGraphQLOperation` try the next auth type where it used to stop. `.invalidState` and
/// `.configuration` take the same path as `.unknown` in every one of them, so only the error's
/// description changes. `AuthSessionCredentialResolutionTests` and
/// `SyncMutationToCloudOperationTests` pin that.
///
/// `package` rather than `public`: this is shared between the plugin modules in this repo and is not
/// API.
package extension AuthSession {

    /// The session's AWS credentials, or the reason it has none.
    func resolveAWSCredentials() throws(AuthError) -> AWSCredentials {
        guard let provider = self as? AuthAWSCredentialsProvider else {
            throw missingAWSCredentialsError()
        }
        return try provider.getAWSCredentials().get()
    }

    /// The session's Cognito user pool tokens, or the reason it has none.
    func resolveCognitoTokens() throws(AuthError) -> AuthCognitoTokens {
        guard let provider = self as? AuthCognitoTokensProvider else {
            throw missingCognitoTokensError()
        }
        return try provider.getCognitoTokens().get()
    }

    /// The session's Cognito identity pool identity ID, or the reason it has none.
    func resolveIdentityID() throws(AuthError) -> String {
        guard let provider = self as? AuthCognitoIdentityProvider else {
            throw missingIdentityIDError()
        }
        return try provider.getIdentityId().get()
    }
}

// MARK: - Why a session that does not conform has no value

private extension AuthSession {

    /// Whether the session vends user pool tokens. A signed-in session that does, but vends no
    /// credentials or identity ID, is user-pool-only: no identity pool is configured.
    var vendsUserPoolTokens: Bool {
        self is AuthCognitoTokensProvider
    }

    func missingAWSCredentialsError() -> AuthError {
        guard isSignedIn else {
            return .invalidState(
                "There is no signed-in user, and the Auth session does not include AWS credentials.",
                """
                Sign in before making a request that requires AWS credentials. To make the request as a \
                guest, configure an identity pool that allows unauthenticated identities.
                """
            )
        }
        if vendsUserPoolTokens {
            return .configuration(
                """
                The Auth session includes user pool tokens but no AWS credentials: no identity pool is \
                configured.
                """,
                """
                Add an identity pool to the Auth configuration, or use a user pool authorization mode for \
                this request.
                """
            )
        }
        return .configuration(
            """
            The Auth session does not include AWS credentials: its type, \(type(of: self)), does not conform to \
            AuthAWSCredentialsProvider.
            """,
            """
            Configure an Auth plugin whose session vends AWS credentials, such as AWSCognitoAuthPlugin with an \
            identity pool.
            """
        )
    }

    func missingCognitoTokensError() -> AuthError {
        guard isSignedIn else {
            return .invalidState(
                "There is no signed-in user, so the Auth session does not include user pool tokens.",
                "Sign in before making a request that requires user pool tokens."
            )
        }
        return .configuration(
            """
            The Auth session does not include user pool tokens: its type, \(type(of: self)), does not conform to \
            AuthCognitoTokensProvider.
            """,
            """
            Configure an Auth plugin whose session vends user pool tokens, such as AWSCognitoAuthPlugin with a \
            user pool.
            """
        )
    }

    func missingIdentityIDError() -> AuthError {
        guard isSignedIn else {
            return .invalidState(
                "There is no signed-in user, and the Auth session does not include an identity ID.",
                """
                Sign in before requesting an identity ID. To use an identity ID as a guest, configure an \
                identity pool that allows unauthenticated identities.
                """
            )
        }
        if vendsUserPoolTokens {
            return .configuration(
                """
                The Auth session includes user pool tokens but no identity ID: no identity pool is \
                configured.
                """,
                "Add an identity pool to the Auth configuration."
            )
        }
        return .configuration(
            """
            The Auth session does not include an identity ID: its type, \(type(of: self)), does not conform to \
            AuthCognitoIdentityProvider.
            """,
            """
            Configure an Auth plugin whose session vends an identity ID, such as AWSCognitoAuthPlugin with an \
            identity pool.
            """
        )
    }
}
