//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The session operations: today's semantics, addressed to this handle's session only.
///
/// **Every operation is per session.** A sign-in, sign-out or deletion here changes this session and no
/// other; its events arrive on this session's stream. The one exception is inherent: a global sign-out
/// is a server-side revocation of the *user*, so another session holding the same user finds out on its
/// next refresh.
///
/// **A storage failure is never reported as signed out.** An operation that cannot read secure storage
/// throws `AuthClientError.storageUnavailable`.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Signs a user in to this session.
    ///
    /// Refused only when this session is already signed in, or federated: other sessions' users never block
    /// it. A guest session signs in and keeps its identity, and a session waiting on a challenge starts over,
    /// the new sign-in superseding the pending one.
    ///
    /// When sign-in needs more from the user, the result's `nextStep` says what, the session's state
    /// becomes `.awaitingChallenge(step)`, and `confirmSignIn(challengeResponse:options:)` continues it.
    /// The pending challenge is this session's only, and it survives the app being closed: it is saved in the
    /// same device-only, never-synchronized keychain storage as the session's tokens, and a client built later
    /// with this session ID reports `.awaitingChallenge(step)` and can answer it. The password is never saved.
    /// A challenge whose Cognito session has expired fails the answer with `.challengeExpired`; one saved more
    /// than 15 minutes ago, longer than Cognito keeps any, is discarded instead of resumed.
    ///
    /// **Cancellation.** Once sent to Cognito, a sign-in runs to its end even if the calling task is
    /// cancelled, so tokens Cognito issued are never lost: the call may then return successfully with
    /// `Task.isCancelled` true. A call cancelled while it still waits (for the session's restore, or behind
    /// another sign-in on this session) throws `CancellationError` and sends nothing.
    ///
    /// This overload shows no passkey sheet: to sign in with a passkey, use
    /// `signIn(username:password:presentationAnchor:options:)`.
    ///
    /// - Parameters:
    ///   - username: The user's username or alias.
    ///   - password: The password, or `nil` for a passwordless first factor.
    ///   - options: The flow and the client metadata.
    /// - Returns: `.done` once signed in, which sends `.signedIn`; otherwise the step to present.
    /// - Throws:
    ///   - `AuthClientError.validation(field: "username")` for an empty username, before anything is sent;
    ///   - `.validation(field: "presentationAnchor")`, since this overload has no window: for a WebAuthn first
    ///     factor (`.userAuth(preferredFirstFactor: .webAuthn)`), before anything is sent, and for a WebAuthn
    ///     step Cognito starts on its own, without presenting anything;
    ///   - `.configuration` without a user pool;
    ///   - `.invalidState` if this session is signed in (sign out first; a session whose refresh token is known
    ///     dead may sign in again) or federated (clear the federation first); if a sign-out, purge or deletion of this session cancelled the sign-in while it was in
    ///     progress; or if another sign-in completed for this session meanwhile, with a different user, who
    ///     stays signed in;
    ///   - `.notAuthorized` or `.service` as Cognito answers (a wrong password is `.notAuthorized`);
    ///   - `.storageUnavailable` if storage could not be read, did not answer in time, or the result could not
    ///     be saved; never reported as signed out;
    ///   - `.unknown` if the session's saved record cannot be read by this version, or for a failure the
    ///     client does not recognise;
    ///   - `CancellationError` if the calling task is cancelled before the sign-in is sent.
    func signIn(
        username: String,
        password: String? = nil,
        options: AuthClientSignInOptions = AuthClientSignInOptions()
    ) async throws -> AuthClientSignInResult {
        let core = core
        return try await core.signIn(username: username, password: password, options: options)
    }

    /// Answers the challenge this session's sign-in is waiting on.
    ///
    /// The challenge may be one a previous launch of the app left: a client built with this session ID resumes
    /// it, and this answers it the same way.
    ///
    /// Cancellation works as for `signIn(username:password:options:)`: once the answer is sent, the call runs
    /// to its end. A `"WEB_AUTHN"` answer shows the passkey sheet over the window the sign-in was given, if
    /// it was given one (`signIn(username:password:presentationAnchor:options:)`).
    ///
    /// - Parameters:
    ///   - challengeResponse: The code, new password, selection or custom answer the step asks for.
    ///   - options: User attributes, client metadata and, for a TOTP setup, the device name.
    /// - Returns: `.done` once signed in, which sends `.signedIn`; otherwise the next step.
    /// - Throws:
    ///   - `AuthClientError.validation(field: "challengeResponse")` for an empty response, or a selection
    ///     outside the step's choices (an MFA selection other than `AuthClientMFAType.<type>.challengeResponse`,
    ///     a first-factor selection other than `AuthClientFactorType.<type>.challengeResponse`);
    ///     `.validation(field: "presentationAnchor")` for a `"WEB_AUTHN"` answer when the sign-in was given no
    ///     window; each before anything is sent, keeping the challenge;
    ///   - `.configuration` without a user pool;
    ///   - `.invalidState` if no sign-in is in progress on this session; if it can no longer continue, so
    ///     sign-in must restart; if a sign-out, purge or deletion of this session cancelled it; or if another
    ///     sign-in completed for this session meanwhile, with a different user;
    ///   - `.challengeExpired` if Cognito no longer accepts the challenge (including one a previous launch saved
    ///     whose Cognito session has since lapsed), so sign-in must restart;
    ///   - `.notAuthorized` or `.service` as Cognito answers. After a wrong code the challenge is still
    ///     pending, so the user can retry;
    ///   - for a `"WEB_AUTHN"` answer, the passkey errors of
    ///     `signIn(username:password:presentationAnchor:options:)`;
    ///   - `.storageUnavailable` if storage could not be read, did not answer in time, or the result could not
    ///     be saved;
    ///   - `.unknown` if the session's saved record cannot be read by this version, or for a failure the
    ///     client does not recognise;
    ///   - `CancellationError` if the calling task is cancelled before the answer is sent.
    func confirmSignIn(
        challengeResponse: String,
        options: AuthClientConfirmSignInOptions = AuthClientConfirmSignInOptions()
    ) async throws -> AuthClientSignInResult {
        let core = core
        return try await core.confirmSignIn(challengeResponse: challengeResponse, options: options)
    }

    /// Signs this session out: revokes its tokens, then clears its credentials from this device.
    ///
    /// Keeps the session's saved row by default, so a picker built from
    /// `storedSessions(configuration:accessGroup:includingSignedOut:)` with `includingSignedOut: true` can
    /// still offer it; pass `purgeStoredSession: true` to remove it too. Any pending sign-in is cancelled.
    /// Other sessions are untouched, except that `globalSignOut` revokes the *user's* tokens everywhere.
    ///
    /// A server-side failure (`RevokeToken`, or `GlobalSignOut` with `globalSignOut`) never keeps the session
    /// signed in here: it is reported in `.partial`. After a failed global sign-out the refresh token is not
    /// revoked either, and `revokeTokenError` holds a placeholder error, as in the plugin.
    ///
    /// After a hosted-UI sign-in that shared the browser's cookies, this sign-out has no window to clear the
    /// hosted UI's cookie in, and reports that in `.partial` as `hostedUIError`; use
    /// `signOut(presentationAnchor:options:)` for such a session.
    ///
    /// Never throws, as the plugin's `signOut` does not. Check `signedOutLocally`, or switch over the result.
    ///
    /// - Returns:
    ///   - `.complete` when the session is signed out and nothing failed. Sends `.signedOut` if credentials
    ///     were removed.
    ///   - `.partial` when the session is signed out on this device but the revoke, the global sign-out or
    ///     the hosted UI's sign-out failed, or, with `purgeStoredSession`, the row could not be removed
    ///     (`storageError`).
    ///   - `.failed` when the session is still signed in: `storageUnavailable` if storage could not be read or
    ///     written or the record kept changing; `invalidState` if a different user signed in to the session
    ///     meanwhile and was left signed in; `unknown` with an underlying `CancellationError` if the calling
    ///     task was cancelled before anything was revoked. Once a revoke has completed, cancellation never
    ///     stops the local clear.
    @discardableResult
    func signOut(options: AuthClientSignOutOptions = AuthClientSignOutOptions()) async -> AuthClientSignOutResult {
        let core = core
        return await core.signOut(global: options.globalSignOut, purge: options.purgeStoredSession)
    }

    /// This session's credentials, refreshed if they need it, each field with its own result.
    ///
    /// A signed-out session with an identity pool that allows guest access becomes `.guest` here, and
    /// only here. A refresh already in flight for this session is joined, never duplicated.
    ///
    /// - Throws: only for failures that are not per field: `AuthClientError.storageUnavailable`; `.unknown`
    ///   when the session's saved record cannot be read by this version; `CancellationError` if the calling
    ///   task is cancelled while it waits (a refresh it joined carries on for the session). A failed refresh
    ///   is reported in the fields, as `sessionExpired` when the session needs a fresh sign-in.
    func fetchAuthSession(options: AuthClientFetchSessionOptions = AuthClientFetchSessionOptions()) async throws -> AuthClientSession {
        let core = core
        return try await core.fetchAuthSession(forceRefresh: options.forceRefresh)
    }

    /// The user signed in to this session, read from its saved credentials without the network.
    ///
    /// - Throws: `AuthClientError.notSignedIn` for a signed-out, guest or federated session; `.invalidState`
    ///   while a sign-in waits on a challenge, as the plugin does; `.storageUnavailable` if storage could not
    ///   be read; `.unknown` if the saved record cannot be read by this version; `CancellationError` if the
    ///   calling task is cancelled while the session is restored.
    func getCurrentUser() async throws -> AuthClientUser {
        let core = core
        return try await core.currentUser()
    }

    /// Deletes the signed-in user from the user pool, then removes this session's saved row, and sends
    /// `.userDeleted`. Other sessions, including ones holding the same user, find out on their next
    /// refresh.
    ///
    /// It never shows the hosted UI's sign-out, so after a hosted-UI sign-in that shared the browser's cookies,
    /// the browser keeps that sign-in's cookie, for a user who no longer exists.
    ///
    /// Once Cognito is asked, the deletion runs to its end even if the calling task is cancelled.
    ///
    /// - Throws:
    ///   - `AuthClientError.configuration` without a user pool;
    ///   - `.notSignedIn` for a signed-out, guest or federated session, and while a sign-in waits on a
    ///     challenge; `.sessionExpired` if the refresh the session needed first found its refresh token dead;
    ///   - `.invalidState` if a different user signed in to the session meanwhile: nothing is deleted;
    ///   - `.notAuthorized` when Cognito refuses the access token (revoked, for example); `.service` as Cognito
    ///     answers otherwise, and `.service(.userNotFound, …)` if the user no longer exists, after signing
    ///     the session out globally and removing its row;
    ///   - `.storageUnavailable` if storage could not be read before the deletion. Thrown **after** a
    ///     successful deletion too, when the user is gone but the session's row could not be removed: the
    ///     session is then already signed out and has sent `.userDeleted`; purge or sign it out to remove the
    ///     row;
    ///   - `.unknown` if the saved record cannot be read by this version, or for a failure the client does not
    ///     recognise;
    ///   - `CancellationError` if the calling task is cancelled before Cognito is asked.
    func deleteUser() async throws {
        let core = core
        try await core.deleteUser()
    }
}
