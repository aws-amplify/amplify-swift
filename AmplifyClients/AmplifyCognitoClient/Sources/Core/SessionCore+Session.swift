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

    /// The session's credentials, each field with its own result.
    ///
    /// - A signed-in or guest session is refreshed through the session's single refresh flight if its
    ///   credentials need it. With `forceRefresh` it is refreshed through the forced flight, which joins
    ///   only other forced refreshes: a normal refresh in flight may find nothing to do.
    /// - A signed-out session acquires guest credentials when an identity pool is configured: the only
    ///   path from `.signedOut` to `.guest`. If the pool allows no guest access it stays signed out.
    /// - A refresh or guest fetch that fails is reported in the fields, as the plugin does:
    ///   `sessionExpired` for a dead refresh token, and the mapped error otherwise.
    ///
    /// - Throws: only what is not per field: `storageUnavailable` (never reported as signed out), the
    ///   record's own error when it is unreadable, and `CancellationError`. Always an `AuthClientError`
    ///   otherwise: a `CredentialsError` from inside the core is converted.
    nonisolated func fetchAuthSession(forceRefresh: Bool) async throws -> AuthClientSession {
        do {
            return try await fetchSession(forceRefresh: forceRefresh)
        } catch let error as CredentialsError {
            throw Self.authClientError(from: error)
        }
    }

    private nonisolated func fetchSession(forceRefresh: Bool) async throws -> AuthClientSession {
        _ = try await restoredSnapshot()
        try await rereadIfExpired()
        let (snapshot, expired) = await snapshotAndExpiry
        switch snapshot.state(engine: engine, challenge: nil) {
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .failed(let error):
            throw error
        case .signedOut, .awaitingChallenge:
            return try await signedOutSession()
        case .guest, .federated, .signedIn:
            if expired {
                return Self.session(failingWith: Self.sessionExpired(sessionId))
            }
            guard let payload = snapshot.credentials else {
                return Self.session(failingWith: Self.notSignedIn(sessionId))
            }
            guard try forceRefresh || needsRefresh(payload, of: snapshot) else {
                return try session(of: snapshot)
            }
            let refreshed: SessionSnapshot
            do {
                let flight = forceRefresh ? forcedRefreshFlight : refreshFlight
                refreshed = try await flight.run { [self] in
                    try await refreshOnce(force: forceRefresh)
                }
            } catch let failure as IdentityStepFailure {
                // A carried session's refresh stored new user pool tokens, then failed the identity step: only the
                // identity and its AWS credentials fail. If the stored tokens need a refresh after all, the session
                // is expired, as the plugin reports it.
                if Self.isCancellation(failure.error) {
                    throw CancellationError()
                }
                let error = Self.identityStepError(failure.error)
                if case .storageUnavailable = error {
                    throw error
                }
                return try await sessionWithoutIdentity(failingWith: error)
                    ?? Self.session(failingWith: Self.sessionExpired(sessionId))
            } catch let error as AuthClientError {
                if case .storageUnavailable = error {
                    throw error
                }
                return Self.session(failingWith: error)
            } catch let error as CredentialsError {
                return Self.session(failingWith: Self.authClientError(from: error))
            }
            // What the flight left may be a re-read record rather than a refresh's result. Never report
            // credentials that still need a refresh, as the providers never vend them.
            if let fresh = refreshed.credentials, try needsRefresh(fresh, of: refreshed) {
                return Self.session(failingWith: .unknown(
                    "Session \"\(sessionId)\"'s credentials could not be refreshed.",
                    "Retry the operation."
                ))
            }
            return try session(of: refreshed)
        }
    }

    static func authClientError(from error: CredentialsError) -> AuthClientError {
        .unknown(error.errorDescription, error.recoverySuggestion, error)
    }

    /// A signed-out session's answer: guest credentials if the identity pool allows them, else every field
    /// failing with `notSignedIn`.
    private nonisolated func signedOutSession() async throws -> AuthClientSession {
        guard configuration.identityPool != nil else {
            return Self.signedOutSession(sessionId)
        }
        do {
            _ = try await guestFlight.run { [self] in
                try await acquireGuestOnce()
            }
        } catch SessionEngineError.notSignedIn {
            // The identity pool allows no guest access. The session stays signed out.
            return Self.signedOutSession(sessionId)
        } catch let error as AuthClientError {
            if case .storageUnavailable = error {
                throw error
            }
            return Self.session(failingWith: error)
        }
        let snapshot = await restoredSnapshotIfAny ?? .absent
        if snapshot.credentials == nil {
            return Self.signedOutSession(sessionId)
        }
        return try session(of: snapshot)
    }

    /// Fetches and commits guest credentials, under the record's gate. If the record meanwhile holds
    /// credentials — another handle signed in or became a guest — it adopts them instead, and a lost write
    /// race is answered by adopting the re-read record, never by overwriting it.
    private nonisolated func acquireGuestOnce() async throws -> SessionSnapshot {
        try await withRecord { [self] store in
            let current = try await store.load(sessionId)
            if current.credentials != nil {
                return await apply(current, event: nil)
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
            let record = SessionRecord(
                // A signed-out row left by a user keeps that user's label, which the guest must not take:
                // only a label that names no user yet passes to the guest.
                label: Self.label(keptFrom: current.ownRecord, for: summary),
                username: summary.username,
                userId: summary.userId,
                kind: summary.kind,
                credentials: guest
            )
            switch try await store.write(record, for: sessionId, expecting: current.version) {
            case .committed(let committed):
                return await apply(SessionSnapshot(committed), event: nil)
            case .discarded:
                return try await apply(store.load(sessionId), event: nil)
            }
        }
    }

    /// The session's fields, read from a payload without the network.
    private nonisolated func session(of snapshot: SessionSnapshot) throws -> AuthClientSession {
        switch snapshot.state(engine: engine, challenge: nil) {
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later.")
        case .failed(let error):
            throw error
        case .signedOut, .awaitingChallenge:
            return Self.signedOutSession(sessionId)
        case .guest, .federated, .signedIn:
            break
        }
        guard let payload = snapshot.credentials else {
            return Self.signedOutSession(sessionId)
        }
        let summary = try engine.checkedDescribe(payload)
        let user = summary.user
        let noUser = Self.notSignedIn(sessionId)

        let identityId: Result<String, AuthClientError>
        let awsCredentials: Result<AuthClientAWSCredentials, AuthClientError>
        if configuration.identityPool == nil || summary.kind == .userPoolOnly {
            // A carried session waiting for its identity has not fetched it yet: while its identity step may not
            // be tried again, that step's last failure answers, not "no identity pool".
            let missing = isIdentityPending(snapshot)
                ? identityRetry.blockingError(at: now(), userId: snapshot.ownRecord?.userId) ?? Self.identityNotFetched(sessionId)
                : Self.noIdentityPoolCredentials(sessionId)
            identityId = .failure(missing)
            awsCredentials = .failure(missing)
        } else {
            identityId = summary.identityId.map { .success($0) } ?? .failure(Self.missing("an identity ID", in: sessionId))
            awsCredentials = try engine.checkedAWSCredentials(in: payload).map { .success(AuthClientAWSCredentials($0)) }
                ?? .failure(Self.missing("AWS credentials", in: sessionId))
        }

        let userSub: Result<String, AuthClientError> = user.map { .success($0.userId) } ?? .failure(noUser)
        let tokens: Result<AuthClientUserPoolTokens, AuthClientError>
        if user == nil {
            tokens = .failure(noUser)
        } else {
            tokens = try engine.checkedUserPoolTokens(in: payload).map { .success($0) }
                ?? .failure(Self.missing("user pool tokens", in: sessionId))
        }
        return AuthClientSession(
            identityIdResult: identityId,
            awsCredentialsResult: awsCredentials,
            userSubResult: userSub,
            userPoolTokensResult: tokens
        )
    }

    /// The session's fields when it is a user pool session waiting for its identity (carried forward,
    /// `identityPending`) and holds user pool tokens that need no refresh: the tokens and sub as they are, and
    /// the identity ID and AWS credentials failing with `error`. `nil` for any other session.
    private nonisolated func sessionWithoutIdentity(failingWith error: AuthClientError) async throws -> AuthClientSession? {
        guard let snapshot = await restoredSnapshotIfAny,
              configuration.identityPool != nil,
              let payload = snapshot.credentials,
              try engine.checkedDescribe(payload).kind == .userPoolOnly,
              try !engine.checkedUserPoolTokensNeedRefresh(payload, at: now()) else {
            return nil
        }
        let fields = try session(of: snapshot)
        return AuthClientSession(
            identityIdResult: .failure(error),
            awsCredentialsResult: .failure(error),
            userSubResult: fields.userSubResult,
            userPoolTokensResult: fields.userPoolTokensResult
        )
    }

    /// Every field failing with `error`, for a refresh or guest fetch that failed.
    static func session(failingWith error: AuthClientError) -> AuthClientSession {
        AuthClientSession(
            identityIdResult: .failure(error),
            awsCredentialsResult: .failure(error),
            userSubResult: .failure(error),
            userPoolTokensResult: .failure(error)
        )
    }

    static func signedOutSession(_ sessionId: SessionID) -> AuthClientSession {
        session(failingWith: notSignedIn(sessionId))
    }

    static func noIdentityPoolCredentials(_ sessionId: SessionID) -> AuthClientError {
        .configuration(
            "Session \"\(sessionId)\" has no identity pool credentials: the configuration has no identity pool, or the user signed in to the user pool only.",
            "Configure an identity pool to get AWS credentials and an identity ID."
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
        case .signedOut, .guest, .federated:
            throw AuthClientError.notSignedIn(
                "There is no user signed in to retrieve current user",
                "Call signIn to sign a user in to this session, then call getCurrentUser."
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
    /// The credentials are refreshed first if they need it, through the session's refresh flight, since
    /// Cognito needs a valid access token. The deletion then runs under the record's gate, in an
    /// unstructured task: the caller's cancellation cannot stop it between deleting the user at Cognito
    /// and removing the row, which would leave a row for a user who no longer exists. If Cognito says
    /// the user does not exist, the session is signed out globally, as the plugin does, its row is purged
    /// as for a deletion, and the error is rethrown. The per-user device records are left as the engine leaves them.
    ///
    /// - Throws: `notSignedIn`, `sessionExpired` or `storageUnavailable` as the credential providers do;
    ///   `invalidState` if a different user signed in to the session meanwhile; the engine's mapped
    ///   failure. If the user was deleted but the row could not be removed, the session still reports
    ///   the deletion (signed out, `.userDeleted`), then `storageUnavailable` says so.
    nonisolated func deleteUser() async throws {
        try requireUserPool(for: "delete the user")
        let payload = try await freshPayload(for: .accessToken)
        let principal = try engine.checkedDescribe(payload)
        let deletion = try await Task { [self] in
            try await deleteUnderGate(payload: payload, principal: principal)
        }.value
        if case .userNotFound(let error) = deletion {
            _ = await signOut(global: true, purge: true)
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
