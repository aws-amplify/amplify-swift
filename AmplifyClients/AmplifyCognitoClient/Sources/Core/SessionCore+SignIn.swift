//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// **Ordering.** A session's sign-in steps — `signIn`, `confirmSignIn` — each run the refusal check, the
/// engine step, the challenge mirror and the commit under the session's `signInLock`, one at a time.
/// So a second sign-in waits for the first, then decides afresh: it is refused if the first
/// signed the session in. What does not take the lock — sign-out, purge, deletion — moves the sign-in
/// epoch instead, and a step whose epoch moved neither commits nor publishes its challenge.
/// They also move the session-ending count, so a sign-in still queued for the lock when they ran never
/// starts.
///
/// **Known limit: the epoch and the count are per process.** They see only this
/// process's sign-outs, purges and deletions. If another process sharing the access group (an app
/// extension) signs the session out or purges it while a sign-in is in flight here, the commit still
/// lands: its write is `.discarded`, the re-read finds a signed-out or absent row, and the commit writes again, as
/// designed. The record gate's compare-before-write is the only cross-process protection, and it guards
/// the record, not the intent: the other process's sign-out is followed by this process's sign-in.
extension SessionCore {

    // MARK: Sign-in

    /// Starts a sign-in on this session.
    ///
    /// **The refusal is per session.** It throws `invalidState` only when *this* session is signed in, and
    /// its refresh token is not known to be dead: another session's user never blocks it. A guest session
    /// signs in, and hands the engine its guest payload so the user keeps the identity. A session waiting
    /// on a challenge signs in afresh: the engine supersedes the pending attempt.
    ///
    /// The network step runs outside the record's gate, so a slow sign-in never blocks another handle's
    /// restore. Its result is then committed under the gate by `commitSignIn`. The step and the commit
    /// run together in one unstructured task, so the caller's cancellation reaches neither: a sign-in that
    /// succeeded at Cognito is never dropped on the floor. A caller cancelled while it still waits for the
    /// session's sign-in lock stops waiting (`CancellationError`) and its step never starts; once the step
    /// has started, a cancelled caller still waits for the step and its commit, and may return successfully
    /// with `Task.isCancelled` true.
    ///
    /// **WebAuthn.** `presentationAnchor` is the window a passkey sheet
    /// attaches to, from the anchored overload; without one, a WebAuthn first factor is refused before
    /// anything is sent, and a WebAuthn step Cognito starts on its own fails without presenting. With one,
    /// the step runs its ceremony under the sheet lease, and the caller's cancellation stops it.
    ///
    /// - Throws: `validation` for an empty username, and (`field: "presentationAnchor"`) for a WebAuthn first
    ///   factor without an anchor; `configuration` without a user pool;
    ///   `storageUnavailable` if storage could not be read, which is never reported as signed out; the
    ///   record's own error if it is unreadable; otherwise the engine's mapped failure.
    nonisolated func signIn(
        username: String,
        password: String?,
        options: AuthClientSignInOptions,
        presentationAnchor: EnginePresentationAnchorBox? = nil
    ) async throws -> AuthClientSignInResult {
        guard !username.isEmpty else {
            throw AuthClientError.validation(
                field: "username",
                "Username is required to signIn",
                "Make sure that a valid username is passed during signIn"
            )
        }
        try requireUserPool(for: "sign in")
        if presentationAnchor == nil, Self.asksForWebAuthn(options.authFlowType) {
            throw Self.presentationAnchorRequired()
        }
        _ = try await restoredSnapshot()
        let engine = engine
        let endings = await sessionEndings
        let step: @Sendable (EngineCeremonyContext?) async throws -> AuthClientSignInResult = { [self] webAuthn in
            let request = EngineSignInRequest(
                username: username,
                password: password,
                authFlowType: options.authFlowType,
                clientMetadata: options.clientMetadata,
                webAuthn: webAuthn
            )
            return try await withSignInLock(endedSince: endings) { [self] in
                let (base, guestPayload, epoch) = try await signInBase()
                return try await runStep(base: base, epoch: epoch, superseding: true) {
                    try await engine.signIn(request, current: guestPayload, epoch: epoch)
                }
            }
        }
        guard let presentationAnchor else {
            return try await step(nil)
        }
        return try await withSheetCeremony(anchor: presentationAnchor, step)
    }

    /// Answers the challenge this session's sign-in is waiting on.
    ///
    /// A `"WEB_AUTHN"` answer runs the passkey ceremony over `presentationAnchor`, else over the window the
    /// sign-in was given. Every confirmation carries a ceremony context of its
    /// own, so the caller's cancellation stops a ceremony it starts, whichever window it uses.
    ///
    /// - Throws: `validation` for an empty response, and (`field: "presentationAnchor"`) for a `"WEB_AUTHN"`
    ///   answer with no window at all, which keeps the challenge; `invalidState` if no sign-in is in progress
    ///   on this session; `challengeExpired` if Cognito's challenge session has expired, so sign-in must
    ///   restart; otherwise the engine's mapped failure. After a retryable failure (a wrong code) the
    ///   challenge is still pending, and the state still reports it.
    nonisolated func confirmSignIn(
        challengeResponse: String,
        options: AuthClientConfirmSignInOptions,
        presentationAnchor: EnginePresentationAnchorBox? = nil
    ) async throws -> AuthClientSignInResult {
        guard !challengeResponse.isEmpty else {
            throw AuthClientError.validation(
                field: "challengeResponse",
                "challengeResponse is required to confirmSignIn",
                "Make sure that a valid challenge response is passed for confirmSignIn"
            )
        }
        try requireUserPool(for: "confirm a sign-in")
        _ = try await restoredSnapshot()
        let userAttributes = Dictionary(
            options.userAttributes.map { ($0.key.cognitoName, $0.value) },
            uniquingKeysWith: { _, last in last }
        )
        let engine = engine
        let endings = await sessionEndings
        return try await withSheetCeremony(anchor: presentationAnchor) { [self] webAuthn in
            let request = EngineConfirmSignInRequest(
                challengeResponse: challengeResponse,
                userAttributes: userAttributes,
                clientMetadata: options.clientMetadata,
                friendlyDeviceName: options.friendlyDeviceName,
                webAuthn: webAuthn
            )
            return try await withSignInLock(endedSince: endings) { [self] in
                let (base, guestPayload, epoch) = await confirmationBase()
                try await Self.validate(challengeResponse, for: pendingChallenge)
                return try await runStep(base: base, epoch: epoch) {
                    try await engine.confirmSignIn(request, current: guestPayload, epoch: epoch)
                }
            }
        }
    }

    /// Signs in the user this session's sign-up left ready for it.
    ///
    /// A sign-in step, run as `signIn` runs one, under `signInLock`, with the plugin's order of checks
    /// (`AWSAuthAutoSignInTask.swift:71-92`):
    /// 1. no auto-sign-in session in the engine: "Not in a signed up state…", before anything else, so a
    ///    signed-in session gets this error and a pending sign-in is kept;
    /// 2. this session signed in: the plugin's "There is already a user in signedIn state…";
    /// 3. otherwise it supersedes a pending sign-in (the plugin cancels one), keeps a guest's identity, and
    ///    is committed by `commitSignIn`.
    ///
    /// The auto-sign-in session is the engine's, so it is this session's only.
    ///
    /// - Throws: `configuration` without a user pool; `invalidState` as above; otherwise as `signIn`.
    nonisolated func autoSignIn() async throws -> AuthClientSignInResult {
        try requireUserPool(for: "sign in automatically")
        _ = try await restoredSnapshot()
        let engine = engine
        let endings = await sessionEndings
        return try await withSignInLock(endedSince: endings) { [self] in
            guard await engine.hasAutoSignInSession else {
                throw Self.notSignedUp()
            }
            let (base, guestPayload, epoch) = try await signInBase()
            return try await runStep(base: base, epoch: epoch, superseding: true) {
                try await engine.autoSignIn(current: guestPayload, epoch: epoch)
            }
        }
    }

    /// Runs one sign-in step under the session's `signInLock`.
    ///
    /// The lock is taken in the **caller's** task, so a caller cancelled while it waits leaves the queue
    /// and its step never starts: nothing has been sent to Cognito yet. Once the lock is held, the step
    /// and its commit run in an unstructured task, out of the caller's reach, and the lock is held
    /// until that task ends. A sign-in queued before a sign-out, purge or deletion that has since ended
    /// the session never runs either: `endings` is the session-ending count taken before queueing.
    nonisolated func withSignInLock(
        endedSince endings: UInt64,
        _ body: @escaping @Sendable () async throws -> AuthClientSignInResult
    ) async throws -> AuthClientSignInResult {
        try await signInLock.withLock { [self] in
            guard await sessionEndings == endings else {
                throw Self.signInCancelled()
            }
            return try await Task { try await body() }.value
        }
    }

    /// The plugin's two checks before an answer is sent (`AWSAuthConfirmSignInTask.swift:167-190`). The
    /// strings name the client's types, and the MFA selection's names all three values it accepts (the
    /// plugin's leaves out `EMAIL_OTP`). A failure keeps the attempt: nothing reached the engine.
    static func validate(_ response: String, for step: AuthClientSignInStep?) throws {
        switch step {
        case .continueSignInWithMFASelection:
            let names = ["SMS_MFA", "SOFTWARE_TOKEN_MFA", "EMAIL_OTP"]
            guard names.contains(where: { response.caseInsensitiveCompare($0) == .orderedSame }) else {
                throw AuthClientError.validation(
                    field: "challengeResponse",
                    "challengeResponse for MFA selection can only be SMS_MFA, SOFTWARE_TOKEN_MFA or EMAIL_OTP.",
                    """
                    Make sure that a valid challenge response is passed for confirmSignIn.
                    Try using `AuthClientMFAType.<type>.challengeResponse` as the challenge response.
                    """
                )
            }
        case .continueSignInWithFirstFactorSelection:
            guard ["PASSWORD", "PASSWORD_SRP", "SMS_OTP", "EMAIL_OTP", "WEB_AUTHN"].contains(response) else {
                throw AuthClientError.validation(
                    field: "challengeResponse",
                    "challengeResponse for factor selection can only be one of the `AuthClientFactorType` values.",
                    """
                    Make sure that a valid challenge response is passed for confirmSignIn.
                    Try using `AuthClientFactorType.<type>.challengeResponse` as the challenge response.
                    """
                )
            }
        default:
            return
        }
    }

    /// Whether a sign-in asks for a WebAuthn first factor, which needs a presentation anchor: without one it
    /// is refused before anything is sent (`presentationAnchorRequired()`).
    static func asksForWebAuthn(_ flow: AuthClientAuthFlowType?) -> Bool {
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *), case .userAuth(.webAuthn?) = flow {
            return true
        }
        #endif
        return false
    }

    /// The snapshot a confirmation commits against, the guest payload the attempt should now keep the
    /// identity of (the session may have become a guest since `signIn`), and the attempt's epoch.
    private func confirmationBase() -> (SessionSnapshot, Data?, UInt64) {
        let snapshot = restoredSnapshotIfAny ?? .absent
        let isGuest = snapshot.state(engine: engine, challenge: nil) == .guest
        return (snapshot, isGuest ? snapshot.credentials : nil, signInEpoch)
    }

    /// The snapshot a sign-in commits against, the guest payload to seed it with, and its attempt's
    /// epoch; or the refusal. One actor call, so the refusal and the new epoch see the same state.
    func signInBase() throws -> (SessionSnapshot, Data?, UInt64) {
        guard let snapshot = restoredSnapshotIfAny else {
            // `restoredSnapshot()` returned, so a snapshot is installed; nothing ever removes one.
            throw AuthClientError.unknown("The session could not be restored.", "Retry the operation.")
        }
        switch snapshot.state(engine: engine, challenge: nil) {
        case .signedIn where !isExpired:
            throw AuthClientError.invalidState(
                "There is already a user in signedIn state. SignOut the user first before calling signIn",
                "Operation performed is not a valid operation for the current auth state"
            )
        case .guest:
            return (snapshot, snapshot.credentials, beginSignInAttempt())
        case .federated:
            // The plugin's sign-in waits for a state it never reaches here; the client says why instead.
            throw AuthClientError.invalidState(
                "Session \"\(sessionId)\" is federated to the identity pool, so a user cannot sign in to it.",
                "Call clearFederationToIdentityPool() first, or sign in to another session."
            )
        case .signedIn, .signedOut, .awaitingChallenge:
            // An expired session signs in again: that is how its user recovers.
            return (snapshot, nil, beginSignInAttempt())
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .failed(let error):
            throw error
        }
    }

    /// Runs one engine step, then publishes its challenge or commits its payload. Always called inside
    /// an unstructured task, so no caller's cancellation reaches the step or the commit.
    ///
    /// The session's challenge record follows the engine's attempt (`SessionCore+ChallengeRecord.swift`): written
    /// when the step stops on a challenge, kept when a wrong answer keeps the attempt, deleted when the attempt
    /// ends. With `superseding` (a new sign-in, not an answer), the record of the attempt it supersedes is deleted
    /// before the step starts.
    nonisolated func runStep(
        base: SessionSnapshot,
        epoch: UInt64,
        superseding: Bool = false,
        _ step: @Sendable () async throws -> EngineStepResult
    ) async throws -> AuthClientSignInResult {
        if superseding {
            await deleteChallengeRecord(epoch: epoch)
        }
        let result: EngineStepResult
        do {
            result = try await step()
        } catch {
            if await signInEpoch != epoch {
                // Cancelled by a sign-out, purge or deletion, which the caller did not cause itself. If the
                // engine kept an attempt anyway (a retryable failure reported after the cancel), end it, so
                // no hidden attempt can be confirmed later.
                await engine.cancelPendingSignIn(before: epoch &+ 1)
                throw Self.signInCancelled()
            }
            await syncPendingChallenge(epoch: epoch)
            if await engine.pendingChallenge == nil {
                // The failure ended the attempt (anything but a wrong answer): so does its record.
                await deleteChallengeRecord(epoch: epoch)
            }
            throw Self.signInFailure(error)
        }
        switch result {
        case .challenge(let step):
            await syncPendingChallenge(epoch: epoch)
            guard await signInEpoch == epoch else {
                // A sign-out, purge or deletion landed before the engine started this step, so the engine
                // kept the challenge: end it, or it could be confirmed later, behind the sign-out, and would
                // hold the password in memory.
                await engine.cancelPendingSignIn(before: epoch &+ 1)
                throw Self.signInCancelled()
            }
            await saveChallengeRecord(epoch: epoch)
            return AuthClientSignInResult(nextStep: step)
        case .done(let payload):
            do {
                try await commitSignIn(payload, base: base, epoch: epoch)
            } catch {
                // Cognito issued these tokens, and nothing holds them now: revoke them, best effort, so no
                // valid refresh token is orphaned. The engine dropped its attempt on `.done`, so the mirror
                // follows it, and no stale challenge stays on screen.
                _ = try? await engine.revoke(payload, global: false)
                await syncPendingChallenge(epoch: epoch)
                await deleteChallengeRecord(epoch: epoch)
                throw error
            }
            return AuthClientSignInResult(nextStep: .done)
        }
    }

    /// Mirrors the engine's pending challenge into the session's state. The engine is the source of
    /// truth: a retryable failure keeps its attempt, anything else clears it. Dropped if the attempt's
    /// epoch moved while the engine was read: a sign-out or purge has since cleared the challenge, and
    /// must not see it come back.
    private nonisolated func syncPendingChallenge(epoch: UInt64) async {
        let pending = await engine.pendingChallenge
        await setPendingChallenge(pending, ifEpoch: epoch)
    }

    /// Commits a completed sign-in's payload under the record's gate, expecting the generation the
    /// sign-in started from.
    ///
    /// When the record moved meanwhile (`.discarded`) it re-reads, then:
    /// - **absent, signed out, or guest:** writes again against the new generation;
    /// - **the same principal:** writes ours. Both token sets are the same user's, and ours is the one
    ///   the caller asked for. Once ours is committed, the replaced tokens are revoked, best effort;
    /// - **a different principal, or credentials that cannot be described:** does not overwrite, and throws
    ///   `invalidState`. The other user stays signed in.
    ///
    /// At most `maximumRecordWriteAttempts` writes, then `storageUnavailable(.interrupted)`. Sends
    /// `.signedIn` and clears the pending challenge on commit. Whenever it throws, the caller revokes the
    /// fresh tokens, best effort, and re-mirrors the challenge.
    ///
    /// **A sign-in the session has since cancelled never commits.** If the attempt's epoch
    /// moved — a sign-out, purge or deletion ran after the step began — it writes nothing and throws
    /// `invalidState`. Checked under the gate, where every canceller
    /// moves the epoch, so no sign-out can land between the check and the write.
    nonisolated func commitSignIn(_ payload: Data, base: SessionSnapshot, epoch: UInt64) async throws {
        let summary = try engine.checkedDescribe(payload)
        let replaced = try await withRecord { [self] store -> Data? in
            guard await signInEpoch == epoch else {
                throw Self.signInCancelled()
            }
            var current = base
            // The same user's credentials another writer stored meanwhile, which ours replace.
            var replaced: Data?
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                let record = SessionRecord(
                    label: Self.label(keptFrom: current.ownRecord, for: summary),
                    username: summary.username,
                    userId: summary.userId,
                    kind: summary.kind,
                    credentials: payload
                )
                if case .committed(let envelope) = try await store.write(record, for: sessionId, expecting: current.generation) {
                    // The sign-in is complete, so its challenge record goes, under the same gate. Best effort: a
                    // record left beside a signed-in session is deleted by the next restore, never resumed.
                    await deleteChallengeRecord(in: store)
                    await apply(SessionSnapshot(envelope), challenge: .set(nil), event: .signedIn)
                    return replaced
                }
                let reread = try await store.load(sessionId)
                if try holdsAnotherPrincipal(reread, than: summary) {
                    await apply(reread, challenge: .set(nil), event: nil)
                    throw AuthClientError.invalidState(
                        "Another sign-in completed for this session while this one was in progress",
                        "The other user is still signed in to this session. Sign them out first, then sign in again."
                    )
                }
                if let held = reread.credentials, held != payload, (try? reread.summary(engine: engine))??.user != nil {
                    replaced = held
                }
                current = reread
            }
            throw Self.contended("sign-in")
        }
        if let replaced {
            // The sign-in ours replaced is the same user's, and its tokens now have no holder in
            // storage. Revoke them, best effort, so no valid refresh token is orphaned. A process still
            // holding them in memory finds them dead on its next refresh, re-reads, and adopts ours.
            _ = try? await engine.revoke(replaced, global: false)
        }
    }

    /// The label a sign-in's record keeps from the record it replaces.
    ///
    /// A label names the user it was set for. It is kept when the replaced record names no user (absent,
    /// a guest, a signed-out row that never had one) or the same user, and cleared when it names someone
    /// else: a different user signing in over an expired session, or over a signed-out row left by
    /// another user.
    static func label(keptFrom replaced: SessionRecord?, for signedIn: CredentialSummary) -> String? {
        guard let replaced, let label = replaced.label else {
            return nil
        }
        guard replaced.username != nil || replaced.userId != nil else {
            return label
        }
        let previous = CredentialSummary(kind: replaced.kind, username: replaced.username, userId: replaced.userId)
        return previous.isSamePrincipal(as: signedIn) ? label : nil
    }

    /// Whether a re-read record holds someone the committing sign-in must not overwrite.
    private nonisolated func holdsAnotherPrincipal(_ snapshot: SessionSnapshot, than signedIn: CredentialSummary) throws -> Bool {
        if case .unreadable = snapshot.source {
            // Never overwritten by the store either; nothing shows it is ours.
            return true
        }
        let held: CredentialSummary?
        do {
            held = try snapshot.summary(engine: engine)
        } catch {
            return true
        }
        guard let held, held.kind != .signedOut, held.kind != .guest else {
            return false
        }
        return !held.isSamePrincipal(as: signedIn)
    }

    // MARK: Helpers

    nonisolated func requireUserPool(for operation: String) throws {
        guard configuration.userPool != nil else {
            throw AuthClientError.configuration(
                "This session cannot \(operation): the configuration has no user pool.",
                "Add a user pool to the configuration (the auth section of amplify_outputs.json)."
            )
        }
    }

    /// The plugin's `autoSignIn` refusal when there is no sign-up to complete, string for string.
    static func notSignedUp() -> AuthClientError {
        .invalidState(
            "Not in a signed up state. Please call signUp() and confirmSignUp() before calling autoSignIn()",
            "Operation performed is not a valid operation for the current auth state"
        )
    }

    static func signInCancelled() -> AuthClientError {
        .invalidState(
            "The sign-in was cancelled: the session was signed out, purged or deleted while it was in progress.",
            "Sign in again."
        )
    }

    /// Maps an engine failure from a sign-in step onto the public errors.
    static func signInFailure(_ error: Error) -> Error {
        switch error {
        case is AuthClientError, is CancellationError:
            return error
        case SessionEngineError.service(let error):
            return error
        case SessionEngineError.notSignedIn:
            return AuthClientError.notSignedIn("The session is not signed in.", "Sign in first.", error)
        default:
            return AuthClientError.unknown("The sign-in could not be completed.", "Retry the sign-in.", error)
        }
    }
}
