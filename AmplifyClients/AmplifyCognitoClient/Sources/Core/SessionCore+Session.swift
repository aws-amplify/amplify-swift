//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

extension SessionCore {

    // MARK: fetchAuthSession

    /// The session's credentials: what the session holds now, or a throw.
    ///
    /// - A signed-in, federated or guest session is refreshed through the session's single refresh flight if its
    ///   credentials need it. With `forceRefresh` it is refreshed through the forced flight, which joins
    ///   only other forced refreshes: a normal refresh in flight may find nothing to do.
    /// - A signed-out session acquires guest credentials when an identity pool is configured: the only
    ///   path from `.signedOut` to `.guest`. If the pool allows no guest access, or there is no identity pool, it
    ///   throws `notSignedIn` and stays signed out. If another writer has saved credentials meanwhile, it adopts
    ///   them instead, and refreshes them as above.
    /// - A field is `nil` only where nothing applies: the identity fields without an identity pool (or for a
    ///   user-pool-only login), and the user fields for a guest or a federated session.
    ///
    /// - Throws: every failure, where the plugin reports one per field. Always an `AuthClientError` or a
    ///   `CancellationError`: a `CredentialsError` from inside the core is converted.
    ///   - `notSignedIn` for a signed-out session that cannot become a guest;
    ///   - `sessionExpired` for a dead refresh token, or a federated session's refused provider token;
    ///   - `storageUnavailable` (never reported as signed out), and the record's own error when it is unreadable;
    ///   - the refresh's or the guest fetch's own failure (the network, Cognito), which leaves the login as it is;
    ///   - the identity step's failure for a carried session waiting for its identity, even when the refresh
    ///     stored new user pool tokens, as the plugin does (`FetchAuthSessionOperationHelper`); and, while that
    ///     step may not be tried again (`PendingIdentityRetry`), its last failure;
    ///   - `unknown` when the saved credentials lack what they should hold, or still need a refresh.
    nonisolated func fetchAuthSession(forceRefresh: Bool) async throws -> AuthClientSession {
        do {
            return try await fetchSession(forceRefresh: forceRefresh)
        } catch let error as CredentialsError {
            throw Self.authClientError(from: error)
        }
    }

    /// - Parameter adopted: this call has already gone round once, so it goes round no more, and a second pass
    ///   answers from the record: it took credentials as a signed-out session (`acquireGuest`), or its refresh
    ///   found the session signed out (the last step below).
    private nonisolated func fetchSession(forceRefresh: Bool, adopted: Bool = false) async throws -> AuthClientSession {
        _ = try await restoredSnapshot()
        try await rereadIfExpired()
        let (snapshot, expired) = await snapshotAndExpiry
        switch snapshot.state(engine: engine, challenge: nil) {
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .failed(let error):
            throw error
        case .signedOut, .awaitingChallenge:
            // A signed-out session fetches guest credentials, or adopts what another writer (an app extension, the
            // Auth plugin, or another call of this session) has saved since (`acquireGuestOnce`). Either way it is
            // then answered as the session it now is, by the branch below: credentials it adopted are refreshed if
            // they need it, as another writer's login may have expired since it was saved, and a forced fetch
            // refreshes them whatever their expiry. A guest it fetched itself needs no refresh, forced or not.
            let acquisition = try await acquireGuest(forced: forceRefresh && !adopted)
            guard !adopted else {
                return try await acquiredSession()
            }
            return try await fetchSession(forceRefresh: forceRefresh && acquisition == .adopted, adopted: true)
        case .guest, .federated, .signedIn:
            if let expired {
                // The expiry's cause, not the snapshot's: the same login saved again since (other bytes, or the
                // plugin's expired flag) answers as the proof did.
                throw expiredError(expired)
            }
            guard let payload = snapshot.credentials else {
                // Not reached: each of these states holds credentials.
                throw Self.notSignedIn(sessionId)
            }
            guard try forceRefresh || needsRefresh(payload, of: snapshot) else {
                return try session(of: snapshot)
            }
            let refreshed: RefreshCommit
            do {
                let flight = forceRefresh ? forcedRefreshFlight : refreshFlight
                refreshed = try await flight.run { [self] in
                    try await refreshOnce(force: forceRefresh)
                }
            } catch let failure as IdentityStepFailure {
                // A carried session's refresh stored new user pool tokens, then failed the identity step. The call
                // fails as that step did, as the plugin's does, though the tokens are valid: the token provider
                // still hands them out (`freshPayload`).
                if Self.isCancellation(failure.error) {
                    throw CancellationError()
                }
                throw Self.identityStepError(failure.error)
            } catch let error as AuthClientError where Self.isCancellation(error) {
                throw CancellationError()
            }
            // What the flight left may be a re-read or adopted record rather than a refresh's result. Never
            // report credentials from one that still need a refresh, as the providers never vend them. The
            // refresh's own result is reported as it is, as the plugin does: checked again by a device clock
            // running ahead of Cognito's, every refresh Cognito accepted would fail.
            if case .adopted(let reread) = refreshed, let fresh = reread.credentials, try needsRefresh(fresh, of: reread) {
                throw Self.notRefreshed(sessionId)
            }
            // The refresh found the session signed out (another writer's sign-out, adopted): it is answered as a
            // signed-out session is, a guest if the identity pool allows one. Once: `adopted` stops both this and
            // the signed-out branch from going round again. A forced fetch stays forced, so a login a call on this
            // core installs before the second pass is still refreshed; another process's is found by
            // `acquireGuestOnce`, and answered as it is (`acquiredSession`).
            if !adopted, refreshed.snapshot.credentials == nil, case .signedOut = refreshed.snapshot.state(engine: engine, challenge: nil) {
                return try await fetchSession(forceRefresh: forceRefresh, adopted: true)
            }
            return try session(of: refreshed.snapshot)
        }
    }

    /// The answer of a call on its second pass (`fetchSession`'s `adopted`) that took credentials as a signed-out
    /// session again: after it had already taken some (another writer signed the session out meanwhile, and saved
    /// credentials again), or after its refresh found the session signed out. The record's, as they are, unless
    /// they need a refresh, which is never reported. The call does not go round again.
    private nonisolated func acquiredSession() async throws -> AuthClientSession {
        let snapshot = await restoredSnapshotIfAny ?? .absent
        if let payload = snapshot.credentials, try needsRefresh(payload, of: snapshot) {
            throw Self.notRefreshed(sessionId)
        }
        return try session(of: snapshot)
    }

    static func notRefreshed(_ sessionId: SessionID) -> AuthClientError {
        .unknown(
            "Session \"\(sessionId)\"'s credentials could not be refreshed.",
            "Retry the operation."
        )
    }

    static func authClientError(from error: CredentialsError) -> AuthClientError {
        .unknown(error.errorDescription, error.recoverySuggestion, error)
    }

    /// A signed-out session's guest credentials if the identity pool allows them, or what another writer saved.
    ///
    /// - Parameter forced: A forced fetch, which never joins an unforced one's guest flight, whose result may be
    ///   credentials it adopted.
    /// - Throws: `notSignedIn` when the session stays signed out: there is no identity pool, the pool allows no
    ///   guest access, or the session was signed out again meanwhile. The guest fetch's own failure otherwise, and
    ///   `CancellationError` for a cancelled one.
    private nonisolated func acquireGuest(forced: Bool) async throws -> GuestAcquisition {
        guard configuration.identityPool != nil else {
            throw Self.notSignedIn(sessionId)
        }
        let acquired: GuestAcquisition
        do {
            acquired = forced
                ? try await acquireGuestOnce()
                : try await guestFlight.run { [self] in
                    try await acquireGuestOnce()
                }
        } catch SessionEngineError.notSignedIn {
            // The identity pool allows no guest access. The session stays signed out.
            throw Self.notSignedIn(sessionId)
        } catch let error as AuthClientError where Self.isCancellation(error) {
            throw CancellationError()
        }
        if await restoredSnapshotIfAny?.credentials == nil {
            throw Self.notSignedIn(sessionId)
        }
        return acquired
    }

    /// What `acquireGuestOnce` did: fetched guest credentials and committed them, or adopted the record another
    /// writer saved.
    enum GuestAcquisition: Sendable {
        case fetched
        case adopted
    }

    /// Fetches and commits guest credentials, under the record's gate. If the record meanwhile holds
    /// credentials — another handle signed in or became a guest — it adopts them instead, and a lost write
    /// race is answered by adopting the re-read record, never by overwriting it.
    ///
    /// **Over `.default`'s signed-out record, the AWSMobileClient logins are cleared again first**, best effort
    /// (`SessionRecordStore.clearLegacyLogins()`), before the guest is written. The signed-out record is what stops a
    /// plugin build from migrating a login whose clear failed at sign-out (or that a release clearing after the
    /// signed-out write left when stopped in between); a guest counts as no session there, so once the guest replaces
    /// it only the clear protects the user. It is the sign-out's whole clear, so it also removes whatever AWSMobileClient
    /// or the AWS SDK for iOS, used beside the client, saved in those services since the sign-out: an app's
    /// `AWSCognitoCredentialsProvider` loses the identity ID and AWS credentials it cached for any identity pool, and
    /// gets a new identity ID. Never over an absent record: a client-only app that never signed in keeps
    /// those logins for a plugin build to migrate. That includes a sidecar with no shared record beside it (a label set
    /// before anyone signed in), which reads as a signed-out row with no version: the plugin's record is absent there.
    private nonisolated func acquireGuestOnce() async throws -> GuestAcquisition {
        try await withRecord { [self] store in
            let current = try await store.load(sessionId)
            if current.credentials != nil {
                await apply(current, event: nil)
                return .adopted
            }
            let guest: Data
            do {
                guest = try await engine.fetchGuestCredentials(current: nil)
            } catch SessionEngineError.notSignedIn {
                throw SessionEngineError.notSignedIn
            } catch {
                throw Self.engineFailure(error)
            }
            let summary = try engine.checkedDescribe(guest)
            // `.default`'s version is the shared record's bytes, so it is `nil` when only the sidecar is stored.
            if sessionId == .default, current.ownRecord != nil, current.version != nil {
                _ = try? await store.perform { $0.clearLegacyLogins() }
            }
            let record = SessionRecord(
                // A signed-out row left by a user keeps that user's label, which the guest must not take:
                // only a label that names no user yet passes to the guest. With none, the session ID's.
                label: Self.label(keptFrom: current.ownRecord, for: summary),
                username: summary.username,
                userId: summary.userId,
                kind: summary.kind,
                credentials: guest
            )
            switch try await store.write(record, for: sessionId, expecting: current.version, labelIfNone: sessionId.label) {
            case .committed(let committed):
                await apply(SessionSnapshot(committed), event: nil)
                return .fetched
            case .discarded:
                try await apply(store.load(sessionId), event: nil)
                return .adopted
            }
        }
    }

    /// The session's fields, read from a payload without the network.
    ///
    /// A guest or a federated session has no user fields: `nil`, where the plugin reports an error. For a
    /// federated session that drops `federatedHasNoUser`'s guidance, which the user's own calls still give.
    ///
    /// - Throws: `notSignedIn` for a signed-out snapshot (signed out during the call, after it had gone round);
    ///   for a carried session still waiting for its identity, its identity step's last failure while the step may
    ///   not be tried again, else `identityNotFetched`; `missing` when the credentials lack a field they should
    ///   hold; the record's own errors.
    private nonisolated func session(of snapshot: SessionSnapshot) throws -> AuthClientSession {
        switch snapshot.state(engine: engine, challenge: nil) {
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later.")
        case .failed(let error):
            throw error
        case .signedOut, .awaitingChallenge:
            throw Self.notSignedIn(sessionId)
        case .guest, .federated, .signedIn:
            break
        }
        guard let payload = snapshot.credentials else {
            // Not reached: each of these states holds credentials.
            throw Self.notSignedIn(sessionId)
        }
        let summary = try engine.checkedDescribe(payload)

        var identityId: String?
        var awsCredentials: AuthClientAWSCredentials?
        if configuration.identityPool == nil || summary.kind == .userPoolOnly {
            // No identity to report, unless this is a carried session waiting for its identity, which has not
            // fetched it yet: the call then fails as its identity step last did, while that step may not be tried
            // again, as the plugin fails a session whose identity step failed.
            if isIdentityPending(snapshot) {
                throw identityRetry.blockingError(at: now(), userId: snapshot.ownRecord?.userId)
                    ?? Self.identityNotFetched(sessionId)
            }
        } else {
            guard let identity = summary.identityId else {
                throw Self.missing("an identity ID", in: sessionId)
            }
            guard let credentials = try engine.checkedAWSCredentials(in: payload) else {
                throw Self.missing("AWS credentials", in: sessionId)
            }
            identityId = identity
            awsCredentials = AuthClientAWSCredentials(credentials)
        }

        var userPoolTokens: AuthClientUserPoolTokens?
        if summary.user != nil {
            guard let tokens = try engine.checkedUserPoolTokens(in: payload) else {
                throw Self.missing("user pool tokens", in: sessionId)
            }
            userPoolTokens = tokens
        }
        return AuthClientSession(
            identityId: identityId,
            awsCredentials: awsCredentials,
            userSub: summary.user?.userId,
            userPoolTokens: userPoolTokens
        )
    }

    static func identityNotFetched(_ sessionId: SessionID) -> AuthClientError {
        .unknown(
            "Session \"\(sessionId)\" was carried forward from a previous configuration and has not fetched its identity yet.",
            "Retry the operation."
        )
    }

    static func missing(_ what: String, in sessionId: SessionID) -> AuthClientError {
        .unknown(
            "Session \"\(sessionId)\"'s saved credentials hold no \(what).",
            "Sign the session out and sign in again."
        )
    }

    // MARK: getCurrentUser

    /// The signed-in user, read from the saved credentials without the network.
    ///
    /// Still answers for a session whose refresh token has expired: it is signed in as that user, and the
    /// app needs to know whom to re-authenticate.
    ///
    /// The errors are the plugin's (`AWSAuthTaskHelper.getCurrentUser`), except that the recovery suggestion
    /// names the client's calls rather than `Auth.signIn` and `Auth.getCurrentUser`.
    ///
    /// - Throws: `notSignedIn` for a signed-out or guest session; `invalidState` while a sign-in waits on a
    ///   challenge; `storageUnavailable` if storage could not be read; the record's own error if it is
    ///   unreadable.
    nonisolated func currentUser() async throws -> AuthClientUser {
        _ = try await restoredSnapshot()
        switch await currentState ?? .signedOut {
        case .signedIn(let user):
            return user
        case .awaitingChallenge:
            throw AuthClientError.invalidState(
                "Auth State not in a valid state",
                "Operation performed is not a valid operation for the current auth state"
            )
        case .signedOut, .guest:
            throw AuthClientError.notSignedIn(
                "There is no user signed in to retrieve current user",
                "Call signIn to sign a user in to this session, then call getCurrentUser."
            )
        case .federated:
            // A sign-in is refused over a federated session (`signInSeed`): say what lets one in.
            throw AuthClientError.notSignedIn(
                "There is no user signed in to retrieve current user",
                "Call clearFederationToIdentityPool() or sign the session out, then sign a user in to this session and call getCurrentUser."
            )
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .failed(let error):
            throw error
        }
    }

    // MARK: deleteUser

    private enum Deletion: Sendable {
        case deleted
        case userNotFound(AuthClientError)
    }

    /// Deletes the signed-in user, then removes the session's saved row: a
    /// row for a user who no longer exists cannot be resumed. Sends `.userDeleted`.
    ///
    /// A federated session, or one whose sign-in waits on a challenge, is refused first, with nothing refreshed
    /// (`requireUserPoolUser`). The credentials are then refreshed if they need it, through the session's refresh
    /// flight, since Cognito needs a valid access token. A caller cancelled by then deletes nothing. The deletion
    /// then runs under the record's gate, in an unstructured task: the caller's cancellation cannot stop it
    /// between deleting the user at Cognito and removing the row, which would leave a row for a user who no
    /// longer exists. If Cognito says the user does not exist, the session is signed out globally, as the plugin
    /// does, in the same task, its row is purged as for a deletion, and the error is rethrown. The per-user
    /// device records are left as the engine leaves them.
    ///
    /// - Throws: `notSignedIn`, `sessionExpired` or `storageUnavailable` as the credential providers do (except
    ///   that it is `notSignedIn` while a sign-in waits on a challenge, an expired session's included);
    ///   `invalidState` if a different user signed in to the session meanwhile; the engine's mapped
    ///   failure. If the user was deleted but the row could not be removed, the session still reports
    ///   the deletion (signed out, `.userDeleted`), then `storageUnavailable` says so. `CancellationError` if
    ///   the calling task is cancelled before Cognito is asked.
    nonisolated func deleteUser() async throws {
        try requireUserPool(for: "delete the user")
        try await requireUserPoolUser()
        let payload = try await freshPayload(for: .accessToken)
        let principal = try engine.checkedDescribe(payload)
        try Task.checkCancellation()
        let deletion = try await Task { [self] in
            let deletion = try await deleteUnderGate(payload: payload, principal: principal)
            if case .userNotFound = deletion {
                // Here, not in the caller's task: the record's gate refuses a cancelled task, so the sign-out would
                // fail and keep the row of a user who no longer exists.
                _ = await signOut(global: true, purge: true)
            }
            return deletion
        }.value
        if case .userNotFound(let error) = deletion {
            throw error
        }
    }

    private nonisolated func deleteUnderGate(payload: Data, principal: CredentialSummary) async throws -> Deletion {
        try await withRecord { [self] store -> Deletion in
            let current = try await store.load(sessionId)
            guard let held = current.credentials else {
                await apply(current, event: nil)
                throw Self.notSignedIn(sessionId)
            }
            // Another handle may have refreshed meanwhile: delete with whatever the same user holds now.
            guard held == payload || (try? engine.describe(held))?.isSamePrincipal(as: principal) == true else {
                await apply(current, event: nil)
                throw AuthClientError.invalidState(
                    "A different user signed in to session \"\(sessionId)\" while its user was being deleted.",
                    "Nothing was deleted. Check which user is signed in, then retry."
                )
            }
            do {
                try await engine.deleteUser(held)
            } catch {
                let mapped = Self.engineFailure(error)
                if let mapped = mapped as? AuthClientError, case .service(.userNotFound?, _, _, _) = mapped {
                    return .userNotFound(mapped)
                }
                throw mapped
            }
            var purgeFailure: Error?
            do {
                try await store.purge(sessionId)
            } catch {
                purgeFailure = error
            }
            // The user is gone at Cognito whether or not the row could be removed, so the session says
            // so either way: signed out, `.userDeleted`, nothing pending.
            forgetRecordMemory()
            await cancelPendingSignIns()
            await apply(.absent, challenge: .set(nil), event: .userDeleted)
            if let purgeFailure {
                throw AuthClientError.storageUnavailable(
                    (purgeFailure as? AuthClientError).flatMap(\.storageUnavailableReason) ?? .interrupted,
                    "The user was deleted, but session \"\(sessionId)\"'s saved record could not be removed.",
                    "Purge the session, or sign it out, to remove the record.",
                    purgeFailure
                )
            }
            return .deleted
        }
    }
}

extension AuthClientError {

    /// The reason, for `storageUnavailable`.
    var storageUnavailableReason: StorageUnavailableReason? {
        guard case .storageUnavailable(let reason, _, _, _) = self else {
            return nil
        }
        return reason
    }
}
