//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

extension SessionCore {

    /// What a caller wants out of the credentials, which decides what counts as "usable".
    enum CredentialPurpose: Sendable {
        case awsCredentials
        case accessToken
    }

    // MARK: Provider entry points

    /// The session's AWS credentials, refreshed first if they need it.
    ///
    /// Fails rather than falls back: a signed-out session throws `notSignedIn` and never fetches guest
    /// credentials. A guest session vends its guest credentials, because the session *is* guest.
    ///
    /// - Throws: `CredentialsError.notConfigured` if the session has no identity pool, or holds only user
    ///   pool tokens; otherwise `AuthClientError` (`notSignedIn`, `sessionExpired`, `storageUnavailable`,
    ///   or `unknown`). A session carried forward from a previous configuration, waiting for its identity, throws
    ///   its identity step's last failure while that step may not be tried again.
    nonisolated func resolveAWSCredentials() async throws -> CognitoAWSCredentials {
        guard configuration.identityPool != nil else {
            throw Self.notConfigured("AWS credentials", missing: "an identity pool")
        }
        let payload = try await freshPayload(for: .awsCredentials)
        guard let credentials = try engine.checkedAWSCredentials(in: payload) else {
            throw AuthClientError.unknown(
                "Session \"\(sessionId)\" holds no AWS credentials.",
                "Sign the session out and sign in again."
            )
        }
        return credentials
    }

    /// The session's user pool access token, refreshed first if it needs it.
    ///
    /// - Throws: `CredentialsError.notConfigured` if the session has no user pool; otherwise
    ///   `AuthClientError` (`notSignedIn` for a signed-out or guest session, `sessionExpired`,
    ///   `storageUnavailable`, or `unknown`).
    nonisolated func accessToken() async throws -> String {
        guard configuration.userPool != nil else {
            throw Self.notConfigured("an access token", missing: "a user pool")
        }
        let payload = try await freshPayload(for: .accessToken)
        guard let token = try engine.checkedAccessToken(in: payload) else {
            // A federated session is signed in, through an identity pool, but has no user pool tokens.
            // Not "signed out", whose disposition would have a consumer discard its buffered work: this
            // session cannot provide a token at all.
            if try engine.checkedDescribe(payload).kind == .federated {
                throw Self.notConfigured("an access token", missing: "user pool sign-in (it is federated)")
            }
            throw Self.notSignedIn(sessionId)
        }
        return token
    }

    /// The payload to read credentials from: restored, checked usable for `purpose`, and refreshed
    /// through the session's single refresh flight if it needs it.
    nonisolated func freshPayload(for purpose: CredentialPurpose) async throws -> Data {
        _ = try await restoredSnapshot()
        try await rereadIfExpired()
        let payload = try await usableCredentials(for: purpose)
        // Only AWS credentials wait for a pending identity: an access token needs none.
        let identity = purpose == .awsCredentials
        guard try await needsRefresh(payload, of: identity ? restoredSnapshotIfAny : nil) else {
            // A carried session waiting for its identity, whose identity step may not be tried again yet: its
            // last failure answers, not "no AWS credentials".
            if identity, let blocked = await identityBlocked(payload) {
                throw blocked
            }
            return payload
        }
        do {
            _ = try await refreshFlight.run { [self] in
                try await refreshOnce(force: false)
            }
        } catch let failure as IdentityStepFailure {
            // The refresh stored new user pool tokens and then failed the identity step. An access token needs no
            // identity: hand out the refreshed one.
            if purpose == .accessToken, let payload = try? await usableCredentials(for: .accessToken),
               try !engine.checkedUserPoolTokensNeedRefresh(payload, at: now()) {
                return payload
            }
            throw failure.error
        }
        let refreshed = try await usableCredentials(for: purpose)
        // What the flight left may be a re-read record rather than this refresh's result. Never hand out
        // credentials that are still expired: the provider contract is currently-valid credentials.
        guard try await !needsRefresh(refreshed, of: identity ? restoredSnapshotIfAny : nil) else {
            throw AuthClientError.unknown(
                "Session \"\(sessionId)\"'s credentials could not be refreshed.",
                "Retry the operation."
            )
        }
        return refreshed
    }

    /// An expired session re-reads its record before failing, so a fresh sign-in stored by another
    /// process — an app extension sharing the access group — is picked up rather than ignored for the
    /// rest of this session's life. New credentials clear the expiry (see `apply`).
    nonisolated func rereadIfExpired() async throws {
        guard await isExpired else {
            return
        }
        try await withRecord { [self] store in
            let current = try await store.load(sessionId)
            if await current.credentials != restoredSnapshotIfAny?.credentials {
                await apply(current, event: nil)
            }
        }
    }

    /// Whether `payload` must be refreshed before it is used: its credentials need it (the engine's test),
    /// or it is `snapshot`'s credentials and the record was carried forward from a previous configuration
    /// without an identity (`SessionRecord.identityPending`, `SessionRecordStore+CopyForward.swift`), and its
    /// identity step may be tried now (`PendingIdentityRetry`). The engine's refresh of user-pool-only
    /// credentials with an identity pool configured fetches the identity and its AWS credentials, so the
    /// identity is obtained on first use, never at restore. Pass `nil` for `snapshot` when the caller wants no
    /// identity (an access token).
    nonisolated func needsRefresh(_ payload: Data, of snapshot: SessionSnapshot?) throws -> Bool {
        if try engine.checkedNeedsRefresh(payload, at: now()) {
            return true
        }
        guard let snapshot, snapshot.credentials == payload else {
            return false
        }
        return isIdentityPending(snapshot) && mayRetryIdentity(for: snapshot)
    }

    /// Whether `snapshot` is a record carried forward without an identity, in a configuration that has an
    /// identity pool to fetch one from.
    nonisolated func isIdentityPending(_ snapshot: SessionSnapshot) -> Bool {
        configuration.identityPool != nil && snapshot.ownRecord?.identityPending == true
    }

    /// Whether a waiting record may try its identity step now: not within `PendingIdentityRetry.interval` of a
    /// transient failure, so a throttled `GetId` does not spend (and, with rotation, rotate) a refresh token per
    /// call, and not after a known refusal in this process.
    nonisolated func mayRetryIdentity(for snapshot: SessionSnapshot) -> Bool {
        identityRetry.blockingError(at: now(), userId: snapshot.ownRecord?.userId) == nil
    }

    /// The error that answers for the identity of the session holding `payload`, if it is a carried session
    /// waiting for its identity whose identity step may not be tried now: the step's last failure.
    nonisolated func identityBlocked(_ payload: Data) async -> AuthClientError? {
        guard let snapshot = await restoredSnapshotIfAny, snapshot.credentials == payload, isIdentityPending(snapshot) else {
            return nil
        }
        return identityRetry.blockingError(at: now(), userId: snapshot.ownRecord?.userId)
    }

    /// The in-memory payload, if the session's state allows `purpose`.
    func usableCredentials(for purpose: CredentialPurpose) throws -> Data {
        if pendingChallenge != nil {
            throw Self.notSignedIn(sessionId)
        }
        if isExpired {
            throw Self.sessionExpired(sessionId)
        }
        guard let snapshot = restoredSnapshotIfAny else {
            throw Self.notSignedIn(sessionId)
        }
        switch snapshot.state(engine: engine, challenge: nil) {
        case .signedOut, .awaitingChallenge:
            throw Self.notSignedIn(sessionId)
        case .failed(let error):
            throw error
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later.")
        case .guest:
            if purpose == .accessToken {
                throw Self.notSignedIn(sessionId)
            }
        case .federated:
            // Usable for AWS credentials. For an access token, `accessToken()` answers `notConfigured` (a
            // federated session has no user pool tokens) and the signed-in operations `notSignedIn`.
            break
        case .signedIn:
            // A record carried forward without its identity (`identityPending`) is refreshed first, which
            // fetches it; only a user-pool-only session that stays one is a misconfiguration here.
            if purpose == .awsCredentials, !isIdentityPending(snapshot),
               (try? snapshot.summary(engine: engine))??.kind == .userPoolOnly {
                throw Self.notConfigured("AWS credentials", missing: "identity pool credentials")
            }
        }
        guard let payload = snapshot.credentials else {
            throw Self.notSignedIn(sessionId)
        }
        return payload
    }

    // MARK: Refresh

    /// One refresh, under the record's gate. The engine proposes the refreshed payload; the core commits
    /// it through the commit guard.
    ///
    /// 1. Re-read first. If another handle or process already refreshed — or signed out — adopt that.
    /// 2. Otherwise refresh and write expecting the generation just read. A lost race (`.discarded`) is
    ///    answered by re-reading. If the re-read record's credentials changed, it is newer: adopt it,
    ///    **never** write over it, which would restore a refresh token the server has already rotated
    ///    away. If only its metadata moved (a label), rebase: write the refreshed credentials onto the
    ///    fresh record, keeping its label, so the refreshed tokens are not thrown away. At most
    ///    `maximumRecordWriteAttempts` writes.
    /// 3. `refreshTokenReused` means another writer used the token: re-read and adopt if that left fresh
    ///    credentials, else fail as retryable. Never signed out. A second reuse in a row, at least
    ///    `RefreshTokenReuse.minimumGap` after the first, whose re-read record's credentials are still exactly
    ///    the ones sent, means nobody else refreshed: the token is dead (a record rolled forward over a token
    ///    the plugin rotated away), so, as for step 4, `sessionExpired`.
    /// 4. `refreshTokenInvalid` means the session needs a fresh sign-in — unless another writer has
    ///    meanwhile stored different credentials (with rotation, a refresh racing another process's can be
    ///    told its token is invalid), so re-read first, as for reuse, and adopt them if so. Otherwise send
    ///    `.sessionExpired` and throw it. The record is kept, and the state stays signed in as its user.
    ///
    /// **A refresh that cannot be saved throws the storage error**; it never hands out tokens storage does
    /// not hold. Known limit: with rotation, the retry then uses a refresh token the server may already
    /// have retired, and the session may need a fresh sign-in.
    ///
    /// With `force` (`fetchAuthSession(options: .init(forceRefresh: true))`) step 1 still re-reads, but
    /// refreshes whatever credentials the record holds, needed or not.
    nonisolated func refreshOnce(force: Bool) async throws -> SessionSnapshot {
        try await withRecord { [self] store in
            let current = try await store.load(sessionId)
            guard let payload = current.credentials, try force || needsRefresh(payload, of: current) else {
                return await apply(current, event: nil)
            }

            let refreshed: Data
            do {
                // Forced when the caller forced it, or when the user pool tokens expire by this core's
                // clock, the one `needsRefresh` just used; otherwise the engine refreshes only the AWS
                // credentials.
                let forceTokens = try force || engine.checkedUserPoolTokensNeedRefresh(payload, at: now())
                refreshed = try await engine.refresh(payload, force: forceTokens)
            } catch SessionEngineError.refreshedThenFailed(let stored, let failure) {
                return try await keepRefreshedTokens(stored, failure: failure, over: current, replacing: payload, store: store)
            } catch SessionEngineError.refreshTokenReused {
                let reread = try await store.load(sessionId)
                if let fresh = reread.credentials, try !needsRefresh(fresh, of: reread) {
                    refreshTokenReuse.reset()
                    return await apply(reread, event: nil)
                }
                // Nobody saved a refresh. Once, another writer may still be saving the one that used the token (an
                // extension suspended between Cognito's answer and its keychain write). Again, at least
                // `RefreshTokenReuse.minimumGap` later, with the record's credentials still exactly the ones sent,
                // nobody did: the token is dead (a record rolled forward over a rotated token), and the session needs
                // a fresh sign-in.
                if reread.credentials == payload, refreshTokenReuse.repeated(payload, at: now()) {
                    await markExpired()
                    throw Self.sessionExpired(sessionId)
                }
                throw AuthClientError.unknown(
                    "Session \"\(sessionId)\"'s refresh token was used by another writer, and no refreshed credentials were saved.",
                    "Retry the operation.",
                    SessionEngineError.refreshTokenReused
                )
            } catch SessionEngineError.refreshTokenInvalid {
                let reread = try await store.load(sessionId)
                if reread.credentials != payload {
                    return await apply(reread, event: nil)
                }
                await markExpired()
                throw Self.sessionExpired(sessionId)
            } catch {
                throw Self.engineFailure(error)
            }

            refreshTokenReuse.reset()
            return try await commitRefresh(refreshed, over: current, replacing: payload, store: store).snapshot
        }
    }

    /// The engine stored new tokens (a rotated refresh token), then failed a later step (`refreshedThenFailed`):
    /// keeps them, under the same guard as a successful refresh, so the next refresh does not send the retired
    /// token, then fails as the refresh did. Never a refresh-token failure underneath: the engine writes new
    /// tokens only after the user pool accepted the refresh token, so the failure is a later step's (`service`).
    ///
    /// A carried session waiting for its identity keeps waiting, in the record, as the plugin keeps retrying
    /// across launches; in this process a known refusal stops further attempts, and a transient failure delays
    /// the next by `PendingIdentityRetry.interval` (a cancellation does neither). Either way no call spends a user
    /// pool refresh on it every time. If the commit lost to another writer whose record is complete (not waiting
    /// for an identity), that record is the answer.
    private nonisolated func keepRefreshedTokens(
        _ stored: Data,
        failure: Error,
        over current: SessionSnapshot,
        replacing payload: Data,
        store: SessionRecordIO
    ) async throws -> SessionSnapshot {
        assert({
            switch failure {
            case SessionEngineError.refreshTokenInvalid, SessionEngineError.refreshTokenReused: return false
            default: return true
            }
        }(), "refreshedThenFailed wrapped a refresh-token failure")
        let error = Self.engineFailure(failure)
        let pending = current.ownRecord?.identityPending == true
        refreshTokenReuse.reset()
        let result = try await commitRefresh(stored, over: current, replacing: payload, store: store, keepingIdentityPending: pending)
        if case .adopted(let adopted) = result, adopted.credentials != nil, adopted.ownRecord?.identityPending != true {
            return adopted
        }
        guard pending else {
            throw error
        }
        if !Self.isCancellation(error) {
            identityRetry.failed(
                Self.identityStepError(error),
                at: now(),
                transient: Self.isTransient(error),
                userId: current.ownRecord?.userId
            )
        }
        throw IdentityStepFailure(error: error)
    }

    /// What a refresh's commit left: its own record, or another writer's newer one, adopted.
    enum RefreshCommit {
        case committed(SessionSnapshot)
        case adopted(SessionSnapshot)

        var snapshot: SessionSnapshot {
            switch self {
            case .committed(let snapshot), .adopted(let snapshot):
                return snapshot
            }
        }
    }

    /// Commits a refreshed payload through the commit guard, under the record's gate (step 2 above): a lost
    /// race whose re-read record holds different credentials is adopted, never overwritten; one whose
    /// credentials did not change is rebased onto, keeping its label.
    private nonisolated func commitRefresh(
        _ refreshed: Data,
        over current: SessionSnapshot,
        replacing payload: Data,
        store: SessionRecordIO,
        keepingIdentityPending: Bool = false
    ) async throws -> RefreshCommit {
        let summary = try engine.checkedDescribe(refreshed)
        var record = SessionRecord(
            label: current.ownRecord?.label,
            username: summary.username,
            userId: summary.userId,
            kind: summary.kind,
            credentials: refreshed,
            // Still waiting for its identity only if this refresh did not fetch one.
            identityPending: keepingIdentityPending && current.ownRecord?.identityPending == true && summary.kind == .userPoolOnly
        )
        var base = current
        for _ in 1 ... Self.maximumRecordWriteAttempts {
            switch try await store.write(record, for: sessionId, expecting: base.generation) {
            case .committed(let envelope):
                return await .committed(apply(SessionSnapshot(envelope), event: nil))
            case .discarded:
                let reread = try await store.load(sessionId)
                guard reread.credentials == payload else {
                    return await .adopted(apply(reread, event: nil))
                }
                base = reread
                record.label = reread.ownRecord?.label
            }
        }
        throw Self.contended("refresh")
    }

    // MARK: Errors

    /// Whether an identity-step failure may succeed on a later try. Only known refusals that repeat are
    /// permanent: `.notAuthorized` (an identity pool that does not federate the user pool), `.invalidParameter`,
    /// `.resourceNotFound` and `.configuration`. Everything else is transient: a 5xx, a service error with no code,
    /// `.unknown`, the network, throttling, storage, a cancellation, and every other `AuthClientError` category.
    static func isTransient(_ error: Error) -> Bool {
        guard let error = error as? AuthClientError else {
            return true
        }
        switch error {
        case .notAuthorized, .configuration:
            return false
        case .service(let code, _, _, _):
            return ![.invalidParameter, .resourceNotFound].contains(code)
        default:
            return true
        }
    }

    /// An identity-step failure as the error the identity fields and AWS credentials report.
    static func identityStepError(_ error: Error) -> AuthClientError {
        (error as? AuthClientError) ?? .unknown("The identity pool step failed.", "Retry the operation.", error)
    }

    /// Whether a failure is a cancellation: a `CancellationError`, or an error the engine reports for one (a
    /// service call cancelled mid-flight). A cancellation says nothing about the identity pool, so it starts no
    /// back-off.
    static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? AuthClientError)?.underlyingError is CancellationError
    }

    static func notSignedIn(_ sessionId: SessionID) -> AuthClientError {
        .notSignedIn(
            "Session \"\(sessionId)\" is not signed in.",
            "Sign in to this session first. A signed-out session never falls back to guest credentials."
        )
    }

    static func sessionExpired(_ sessionId: SessionID) -> AuthClientError {
        .sessionExpired(
            "Session \"\(sessionId)\"'s refresh token has expired or been revoked.",
            "Sign in to this session again. Other sessions are unaffected.",
            SessionEngineError.refreshTokenInvalid
        )
    }

    static func notConfigured(_ what: String, missing: String) -> CredentialsError {
        .notConfigured(
            "This session cannot provide \(what): it has no \(missing).",
            "Configure \(missing) for this client, or ask a different provider."
        )
    }

    static func engineFailure(_ error: Error) -> Error {
        switch error {
        case is AuthClientError, is CredentialsError, is CancellationError:
            return error
        case SessionEngineError.service(let error):
            return error
        case SessionEngineError.notSignedIn:
            return AuthClientError.notSignedIn("The session is not signed in.", "Sign in first.", error)
        default:
            return AuthClientError.unknown("The session's credentials could not be refreshed.", "Retry the operation.", error)
        }
    }
}

/// A refresh of a carried session waiting for its identity stored new user pool tokens, then failed the identity
/// step with `error`: callers that need no identity (an access token, a session's token fields) can still use the
/// tokens.
struct IdentityStepFailure: Error {
    let error: Error
}

/// When a carried session waiting for its identity may try the identity step again: not within `interval` of a
/// transient failure, and not after a known refusal. In memory, per record for the process, shared by every core of
/// it (`SessionRecordGates.memory`): the record keeps waiting, so a new process tries at once, as the plugin retries on
/// every launch. Until then the last failure answers for the identity.
final class PendingIdentityRetry: @unchecked Sendable {
    static let interval: TimeInterval = 30

    // `@unchecked Sendable`: every property is only touched while holding `lock`.
    private let lock = NSLock()
    private var notBefore: Date?
    private var refused = false
    private var lastError: AuthClientError?
    private var userId: String?

    /// The identity step failed with `error` for the user `userId`: for good (`transient: false`), or for `interval`.
    func failed(_ error: AuthClientError, at now: Date, transient: Bool, userId: String?) {
        lock.withLock {
            if self.userId != userId {
                refused = false
                notBefore = nil
            }
            self.userId = userId
            lastError = error
            if transient {
                notBefore = now.addingTimeInterval(Self.interval)
            } else {
                refused = true
            }
        }
    }

    /// Forgets every failure: the session was signed out or purged.
    func reset() {
        lock.withLock {
            notBefore = nil
            refused = false
            lastError = nil
            userId = nil
        }
    }

    /// The last failure, while the identity step may not be tried again for `userId`; `nil` once it may, or for another
    /// user than the one that failed (a later session carried into this record).
    func blockingError(at now: Date, userId: String?) -> AuthClientError? {
        lock.withLock {
            guard lastError != nil, self.userId == userId else {
                return nil
            }
            if refused {
                return lastError
            }
            guard let notBefore, now < notBefore else {
                return nil
            }
            return lastError
        }
    }
}

/// Whether a refresh was told its refresh token was reused while the record's credentials were still exactly the ones
/// it sent, twice in a row, the second at least `minimumGap` after the first. Per record, for the process
/// (`SessionRecordGates.memory`).
final class RefreshTokenReuse: @unchecked Sendable {
    /// How long another writer has to save the refresh that used the token before a repeat counts: an app extension
    /// suspended between Cognito's answer and its keychain write, and an app retrying at once, must not read as a
    /// dead token.
    static let minimumGap: TimeInterval = 30

    // `@unchecked Sendable`: `first` is only touched while holding `lock`.
    private let lock = NSLock()
    private var first: (payload: Data, at: Date)?

    /// Records a reuse of `payload` with the record unchanged at `now`; `true` if an earlier one of the same payload
    /// was at least `minimumGap` before. A repeat sooner than that is not counted, and keeps the first's time.
    func repeated(_ payload: Data, at now: Date) -> Bool {
        lock.withLock {
            guard let first, first.payload == payload else {
                self.first = (payload, now)
                return false
            }
            guard now.timeIntervalSince(first.at) >= Self.minimumGap else {
                return false
            }
            self.first = nil
            return true
        }
    }

    func reset() {
        lock.withLock { first = nil }
    }
}
