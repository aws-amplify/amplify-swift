//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// What a sign-out was given to show the hosted UI's logout page in.
enum SignOutWindow: Sendable {
    /// No window: `signOut(options:)`, `signOutStoredSession`.
    case none
    /// `signOut(presentationAnchor:options:)`'s window.
    case anchor(EnginePresentationAnchorBox)
}

extension SessionCore {

    /// The first attempt of a sign-out: shows the hosted UI's logout page when the sign-in shared the browser's
    /// cookies and it can, holding the system sheet around it. Later attempts
    /// never show it: `SessionSignOut` calls `engine.revoke(_:global:)` for those.
    ///
    /// | Condition | Lease | Engine | Reported |
    /// |---|---|---|---|
    /// | the sign-in did not share cookies (an API sign-in, an ephemeral hosted UI) | none | `.skip` | as before |
    /// | no window (`signOut(options:)`) | none | `.skip` | `hostedUIError` `.validation(field: "presentationAnchor")`: the one documented difference from the plugin, which shows a window of its own |
    /// | no hosted UI, or no sign-out redirect URI, in the configuration | none | — | throws `SignOutRefusal(noHostedUIForSignOut)`: nothing cleared, the plugin's `.failed` |
    /// | the engine finds no hosted UI or sign-out redirect URI (`HostedUIError.pluginConfiguration`, `.signOutRedirectURI`) | released | `.present` | the same refusal, the engine's error underneath |
    /// | another session holds the sheet | none | — | throws `SignOutRefusal(.browserBusy(holder:))` at once, before anything is stopped: nothing cleared, and this session's passkey registration left running |
    /// | this session's passkey registration holds the sheet, or is still before its sheet | stopped first, then waits up to `passkeySheetClosingTimeout` for its sheet to close | as below | as below; if the sheet does not close in time, the busy row |
    /// | the sheet is busy (another session took it meanwhile, or this session's passkey sheet did not close in time) | none | — | throws `SignOutRefusal(.browserBusy(holder:))`: nothing cleared |
    /// | lease taken | around this attempt | `.present` | the engine's outcome; a page that could not be shown or completed (the window gone, the browser failed) is the engine's `SignOutRefusal`: nothing cleared |
    /// | the user closed the page | released | — | rethrows `.userCancelled`: nothing cleared, unless the session is expired, which reruns `.skip` and reports it |
    /// | `cancelWebUISignIn()` or `resetSystemSheet()` interrupted the lease | released | — | waits for the sign-out's own result: the row above if that closed the page, else what it did (signed out, or its failure reported as the revoke's) |
    /// | the interrupt came before the body began (between the grant and the start; the body is abandoned, never runs) | released | — | the closed-page row, at once: nothing ran |
    /// | the caller's task was cancelled | released | — | the same decision: `CancellationError` if the body never began or closed the page (nothing cleared), else what it did, and the session is cleared |
    ///
    /// **Lock order: record gate → sheet lease.** The sign-out holds this session's record gate, so its refresh
    /// and every other record operation wait behind an open logout page. Nothing holding a lease takes a record
    /// gate: a hosted-UI sign-in's lease covers its engine call only.
    nonisolated func firstSignOutAttempt(
        _ payload: Data,
        global: Bool,
        window: SignOutWindow
    ) async throws -> EngineSignOutOutcome {
        guard (try? engine.checkedSignOutPresentsBrowser(payload)) == true else {
            return try await engine.revoke(payload, global: global)
        }
        #if os(iOS) || os(macOS) || os(visionOS)
        guard case .anchor(let box) = window else {
            return try await skippingHostedUI(payload, global: global, reporting: Self.noSignOutWindow())
        }
        guard configuration.hasHostedUI else {
            // The plugin's `.failed`, with the user still signed in: nothing is revoked or cleared.
            throw SignOutRefusal(error: Self.noHostedUIForSignOut())
        }
        // Another session's sheet refuses the page whatever this session does, so that comes first: a sign-out
        // that does nothing must not stop this session's passkey registration.
        if let holder = await sheetLock.currentHolder, holder != sessionId {
            throw SignOutRefusal(error: Self.signOutBrowserBusy(
                .browserBusy(heldBy: holder, requestedBy: sessionId, reason: .heldByAnotherSession)
            ))
        }
        let engine = engine
        let body = LeaseBodyResult<EngineSignOutOutcome>()
        // A passkey registration of this session holding the sheet would make the page `browserBusy(self)`: it is
        // stopped first, as the sign-out would stop it anyway, and the page waits for its sheet to close. Stopped
        // even if the user then closes the page and stays signed in, or if its sheet does not
        // close within `passkeySheetClosingTimeout`.
        var policy: WebUIOptions.BrowserBusyPolicy = .fail
        if await stopPasskeyRegistrations() {
            // Also for a registration whose lease the lock has granted but whose flow has not attached yet, which
            // the flow's own cancel cannot reach: the lock then refuses it as it attaches.
            await sheetLock.cancel(for: sessionId)
            // Wait only for this session's own closing sheet; another session's is the busy row, at once. Since
            // the check above, another session holds the sheet here only if it took it in between (when this
            // session's sheet closed, or the lock was free): without this guard the page would queue behind it
            // for up to `passkeySheetClosingTimeout`. No unit test reaches that window: nothing between the check
            // and this line can be held from a test without a seam in the sign-out itself, and the fix that
            // removes the window (acquire first) is still open. The own-sheet tests cover the `true` branch.
            if await sheetLock.currentHolder == sessionId {
                policy = .wait(timeout: Self.passkeySheetClosingTimeout)
            }
        }
        do {
            return try await sheetLock.withLease(for: sessionId, policy: policy) { _ in
                // Claimed before anything runs, so an interrupt can tell a body that never started (the lock
                // answers an interrupt between grant and start without running it) from one that did.
                guard body.begin() else {
                    throw CancellationError()
                }
                do {
                    let outcome = try await engine.revoke(payload, global: global, hostedUI: .present(box))
                    body.finish(.success(outcome))
                    return outcome
                } catch {
                    body.finish(.failure(error))
                    throw error
                }
            }
        } catch let error as AuthClientError where error.isBrowserBusy {
            // The user asked for the page and it cannot be shown: they stay signed in.
            throw SignOutRefusal(error: Self.signOutBrowserBusy(error))
        } catch let error as AuthClientError where error.isUserCancelled {
            return try await afterClosedLogout(payload, global: global, error)
        } catch is CancellationError {
            // The caller's own cancellation too: the engine's sign-out runs in a task of its own and may go on
            // revoking, so the record must follow what it did, not the cancellation (verification should-fix).
            return try await afterInterruptedLogout(payload, global: global, body: body, byCaller: Task.isCancelled)
        }
        #else
        return try await skippingHostedUI(payload, global: global, reporting: Self.noSignOutWindow())
        #endif
    }

    /// How long a sign-out's logout page waits for the passkey sheet it closed to go.
    static let passkeySheetClosingTimeout: TimeInterval = 10

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The lease was interrupted: by the caller's cancellation, or by `cancelWebUISignIn()` or `resetSystemSheet()`,
    /// which also dismisses the page. The sign-out may already be past the page, revoking, so what it
    /// did is its own result, which comes once the page is gone.
    ///
    /// | The body | Caller cancelled | Otherwise |
    /// |---|---|---|
    /// | never started (the interrupt came between the grant and the start) | `CancellationError`, nothing cleared | the closed-page row |
    /// | ended with the page closed (`.userCancelled`, `CancellationError`) | `CancellationError`, nothing cleared | the closed-page row |
    /// | signed out | its outcome: the session is cleared | the same |
    /// | refused (the page could not be shown or completed, `SignOutRefusal`) | the refusal: nothing cleared, `.failed` | the same |
    /// | failed otherwise | its failure, as the revoke's: the session is cleared | the same |
    ///
    /// A body that never started is abandoned under the claim's lock, so it can no longer start: waiting for it
    /// would wait forever while this sign-out holds the record gate (verification blocker).
    private nonisolated func afterInterruptedLogout(
        _ payload: Data,
        global: Bool,
        body: LeaseBodyResult<EngineSignOutOutcome>,
        byCaller: Bool
    ) async throws -> EngineSignOutOutcome {
        let closedPage: AuthClientError
        if body.abandonIfNotBegun() {
            closedPage = Self.logoutClosed()
        } else {
            switch await body.value {
            case .success(let outcome):
                return outcome
            case .failure(let error as AuthClientError) where error.isUserCancelled:
                closedPage = error
            case .failure(is CancellationError):
                closedPage = Self.logoutClosed()
            case .failure(let error):
                // A `SignOutRefusal` stops the sign-out with nothing cleared (`SessionSignOut.run()` rethrows it,
                // `.failed`); any other failure is reported as the revoke's, and the session is cleared.
                throw error
            }
        }
        if byCaller {
            throw CancellationError()
        }
        return try await afterClosedLogout(payload, global: global, closedPage)
    }
    #endif

    /// The user closed the logout page: they stay signed in, as with the plugin. Unless the session is expired
    /// (the plugin's #3956 behaviour, keyed there on `isRefreshTokenExpired`): its tokens are dead anyway, so it
    /// signs out without the page and reports the cookie left behind.
    private nonisolated func afterClosedLogout(_ payload: Data, global: Bool, _ error: AuthClientError) async throws -> EngineSignOutOutcome {
        guard await isExpired else {
            throw error
        }
        return try await skippingHostedUI(payload, global: global, reporting: error)
    }

    private nonisolated func skippingHostedUI(
        _ payload: Data,
        global: Bool,
        reporting error: AuthClientError
    ) async throws -> EngineSignOutOutcome {
        var outcome = try await engine.revoke(payload, global: global)
        outcome.hostedUIError = outcome.hostedUIError ?? error
        return outcome
    }

    // MARK: Errors

    /// The hosted UI's cookie could not be cleared: no window was given to show its logout page in.
    static func noSignOutWindow() -> AuthClientError {
        .validation(
            field: "presentationAnchor",
            "The session was signed out, but not from the hosted UI: its sign-in shared the browser's cookies, and "
                + "no window was given to show the hosted UI's sign-out in, so the browser still holds its sign-in.",
            "Sign out with signOut(presentationAnchor:options:). Until then, sign in to the hosted UI with "
                + "prompt: [.login] or prefersEphemeralSession: true, or it may sign the same user in again."
        )
    }

    /// The hosted UI's sign-out cannot run: the configuration has no hosted UI, or no sign-out redirect URI. The
    /// sign-out is `.failed` and the session stays signed in, as with the plugin. One value whether the core
    /// or the engine finds it; the engine's own error, when it found it, is `underlying`.
    static func noHostedUIForSignOut(_ underlying: Error? = nil) -> AuthClientError {
        .configuration(
            "The session is still signed in: its sign-in shared the browser's cookies, and the configuration has no "
                + "hosted UI, with a sign-out redirect URI, to sign it out of.",
            "Add the hosted UI (oauth) settings, with a sign-out redirect URI, to the configuration, then sign out "
                + "again. To sign out on this device only, leaving the browser's sign-in, call signOut(options:).",
            underlying
        )
    }

    /// The sheet lock's `browserBusy`, with a suggestion for a sign-out: the lock's own suggestions name
    /// `whenBrowserBusy`, which `AuthClientSignOutOptions` does not have. The holder and description are kept.
    static func signOutBrowserBusy(_ busy: AuthClientError) -> AuthClientError {
        guard case .browserBusy(let holder, let description, _, let underlying) = busy else {
            return busy
        }
        return .browserBusy(holder: holder, description, signOutBrowserBusySuggestion, underlying)
    }

    static let signOutBrowserBusySuggestion =
        "Retry the sign-out when the other sheet has closed; the session is still signed in."

    static func logoutClosed() -> AuthClientError {
        .userCancelled(
            "The hosted UI's sign-out page was closed before it finished.",
            "Sign out again to clear the browser's sign-in."
        )
    }
}

#if os(iOS) || os(macOS) || os(visionOS)
extension SessionCore {

    // MARK: Sign-in

    /// Signs this session in through the hosted UI.
    ///
    /// A sign-in step, run as `signIn` runs one: under the session's `signInLock`, refused when this session is
    /// signed in, a guest's identity kept, committed by `commitSignIn`. A password sign-in waiting on a
    /// challenge is cancelled first, so the state stops reporting it.
    ///
    /// **The sheet lease wraps exactly the engine call**: the authorize URL, the browser, the code exchange and
    /// the identity checks. The commit, the state and `.signedIn` come after the lease is released, so a
    /// sign-in the caller saw as cancelled never signs the session in, and nothing holding the lease takes a
    /// record gate. A `.done` that arrives after an interrupt is revoked, not committed: the hosted UI's tokens
    /// come from the token endpoint, which no issued-token tap watches.
    ///
    /// **Cancellation.** The caller's task is watched here, where it runs: `withSignInLock` runs the step in a
    /// task of its own, which the caller's cancellation never reaches. Its handler cancels the task the lease
    /// runs in, which dismisses the browser, and the step checks it before the lease. A sign-out, purge or
    /// deletion stops the flow it registered, by epoch, so an earlier ending never stops a later flow. A
    /// `CancellationError` from the lease is then reported by what caused it:
    ///
    /// | Cause | Throws |
    /// |---|---|
    /// | a sign-out, purge or deletion of this session (the epoch moved) | the sign-in-cancelled `invalidState` |
    /// | the calling task was cancelled | `CancellationError` |
    /// | `cancelWebUISignIn()`, `resetSystemSheet()` | `.userCancelled` |
    ///
    /// **A sign-out during the code exchange** stops the engine's machine, which then drops the token
    /// response. The engine shows the exchange's refresh token to the operation's issued-token tap first
    /// (`HostedUIEnvironment.issuedRefreshTokenObserver`), and the tap of a cancelled operation revokes it, once.
    nonisolated func signInWithWebUI(anchor: EnginePresentationAnchorBox, options: WebUIOptions) async throws -> AuthClientSignInResult {
        try requireUserPool(for: "sign in with the hosted UI")
        guard configuration.hasHostedUI else {
            throw LiveSessionEngine.hostedUINotConfigured()
        }
        _ = try await restoredSnapshot()
        guard await beginWebUISignIn() else {
            throw AuthClientError.browserBusy(heldBy: sessionId, requestedBy: sessionId, reason: .alreadyInFlight)
        }
        let caller = SystemSheetFlow()
        let outcome: Result<AuthClientSignInResult, Error>
        do {
            outcome = try await .success(withTaskCancellationHandler {
                try await webUISignInStep(anchor: anchor, options: options, caller: caller)
            } onCancel: {
                // Cancels the task the lease runs in, which interrupts it (or ends its wait for the sheet),
                // and stops a step that has not reached the lease yet.
                caller.cancel()
            })
        } catch {
            outcome = .failure(error)
        }
        await endWebUISignIn()
        switch outcome {
        case .success(let result):
            return result
        case .failure(is CancellationError):
            if Task.isCancelled {
                throw CancellationError()
            }
            throw Self.webUISignInCancelled()
        case .failure(let error as AuthClientError):
            if Task.isCancelled, error.isBrowserBusy {
                // Refused a sheet the caller had already given up on: the cancellation is the answer.
                throw CancellationError()
            }
            throw Self.namingHolder(error, subjects: caller.subjects)
        case .failure(let error):
            throw error
        }
    }

    /// The sign-in step, under the session's sign-in lock, with the lease around the engine call.
    private nonisolated func webUISignInStep(
        anchor: EnginePresentationAnchorBox,
        options: WebUIOptions,
        caller: SystemSheetFlow
    ) async throws -> AuthClientSignInResult {
        let engine = engine
        let lock = sheetLock
        let sessionId = sessionId
        let endings = await sessionEndings
        return try await withSignInLock(endedSince: endings) { [self] in
            // The step runs in a task of its own, which the caller's cancellation does not reach: check it.
            guard !caller.isCancelled else {
                throw CancellationError()
            }
            let (base, guestPayload, epoch) = try await signInBase()
            // Again before ending a pending password challenge: a caller that has given up must not cost the
            // session its challenge.
            guard !caller.isCancelled else {
                throw CancellationError()
            }
            try await cancelPendingChallenge(before: epoch)
            let (identity, subjects) = try await identityPolicy(for: options.identityExpectation)
            caller.record(subjects)
            let request = EngineWebUISignInRequest(
                anchor: anchor,
                options: EngineWebUIOptions(options, nonce: Self.flowNonce(options.nonce)),
                identity: identity
            )
            return try await runStep(base: base, epoch: epoch, superseding: true) {
                // Tokens the body got after its caller was answered are revoked by whichever of the two comes
                // second: the lock discards a result produced after an interrupt, even one the body
                // had already returned when the interrupt landed.
                let claim = LateSignInClaim()
                // A sign-out, purge or deletion from here on stops this flow, and only this one.
                guard await registerWebUIFlow(epoch: epoch, cancel: { caller.cancel(.sessionEnded) }) else {
                    throw CancellationError()
                }
                defer {
                    // Fire-and-forget on purpose: `defer` cannot await, and a late unregister is harmless. It is
                    // keyed by epoch, so it never removes a later flow's registration, and a stale registration
                    // only lets a later ending cancel a flow that has already ended.
                    Task { await self.unregisterWebUIFlow(epoch: epoch) }
                }
                do {
                    return try await caller.run {
                        try await lock.withLease(for: sessionId, policy: options.whenBrowserBusy) { _ in
                            // An ending that landed while this waited for the sheet: show nothing.
                            guard await self.signInEpoch == epoch else {
                                throw CancellationError()
                            }
                            let step = try await engine.signInWithWebUI(request, current: guestPayload, epoch: epoch)
                            if case .done(let payload) = step, !claim.offer(payload) {
                                // Interrupted: nobody will commit these tokens, so revoke them.
                                Self.revokeOrphaned(payload, engine: engine)
                                throw CancellationError()
                            }
                            return step
                        }
                    }
                } catch is CancellationError {
                    if let payload = claim.close() {
                        Self.revokeOrphaned(payload, engine: engine)
                    }
                    throw CancellationError()
                }
            }
        }
    }

    /// The nonce a flow sends: the caller's, unless it is missing or empty, else a minted one.
    static func flowNonce(_ callers: String?) -> String {
        guard let callers, !callers.isEmpty else {
            return mintNonce()
        }
        return callers
    }

    /// Revokes tokens nobody will commit, best effort, from a task of its own, and does not wait for it.
    ///
    /// Never from the calling task: it is the interrupted lease's, and a cancelled task's events are dropped by the
    /// engine's state machine (`StateMachine.send`), so a revoke sent from it would never reach Cognito. And not
    /// awaited: the caller's `CancellationError` or `.userCancelled` answers at once, and the sheet is not held
    /// through a network round trip.
    static func revokeOrphaned(_ payload: Data, engine: any SessionEngine) {
        Task { _ = try? await engine.revoke(payload, global: false) }
    }

    /// Stops this session's browser sign-in, if it holds or is queued for the system sheet.
    nonisolated func cancelWebUISignIn() async {
        await sheetLock.cancel(for: sessionId)
    }

    /// A password sign-in waiting on a challenge, ended before the hosted UI starts (as the
    /// plugin's `HostedUISignInHelper.isValidState` sends `.cancelSignIn`), so the state reports the session
    /// signed out, not the stale challenge, while the browser is up.
    private nonisolated func cancelPendingChallenge(before epoch: UInt64) async throws {
        guard await pendingChallenge != nil else {
            return
        }
        await engine.cancelPendingSignIn(before: epoch)
        await setPendingChallenge(nil, ifEpoch: epoch)
    }

    /// The engine's identity policy for an expectation, and, for `.distinctFromOtherSessions`, which session
    /// holds each excluded user (for the error's description).
    ///
    /// The excluded users are the other signed-in sessions' of this configuration: their records' user IDs,
    /// read through `describe` where a record has none, and always for `.default`, the plugin's record.
    /// This session's own user is never excluded.
    nonisolated func identityPolicy(
        for expectation: WebUIOptions.IdentityExpectation
    ) async throws -> (EngineIdentityPolicy, [String: SessionID]) {
        switch expectation {
        case .none:
            return (.none, [:])
        case .matches(let identity):
            return (EngineIdentityPolicy(expectedIdentity: identity), [:])
        case .distinctFromOtherSessions:
            let engine = engine
            let io = SessionRecordIO(store: store, queue: SessionRecordIO.listingQueue)
            // `.default`'s login as its restore would read it, after the Auth plugin's configuration-change rule.
            let userIds = try await io.signedInUserIds(describe: { try? engine.describe($0) }, pluginConfiguration: pluginConfiguration)
            var holders: [String: SessionID] = [:]
            for (holder, userId) in userIds.sorted(by: { $0.key.stringValue < $1.key.stringValue })
                where holder != sessionId && holders[userId] == nil {
                holders[userId] = holder
            }
            return (EngineIdentityPolicy(excludedSubjects: Set(holders.keys)), holders)
        }
    }

    /// `.unexpectedIdentity` for a user signed in to another session, with a description naming that session.
    /// Every other error is returned as it is.
    static func namingHolder(_ error: AuthClientError, subjects: [String: SessionID]) -> AuthClientError {
        guard case .unexpectedIdentity(let expected, let returned, _, let suggestion, let underlying) = error,
              expected == nil,
              let holder = subjects[returned.userId] else {
            return error
        }
        return .unexpectedIdentity(
            expected: nil,
            returned: returned,
            "The hosted UI sign-in returned the user who is signed in to session \"\(holder)\", so nobody was signed in.",
            suggestion,
            underlying
        )
    }

    /// A nonce for one flow: 32 random bytes, base64url without padding.
    static func mintNonce() -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0 ..< 32).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func webUISignInCancelled() -> AuthClientError {
        .userCancelled(
            "The hosted UI sign-in was cancelled before it finished.",
            "Sign in again when the user is ready."
        )
    }
}

#endif

// Declared on every platform, though its users (the sign-out's hosted-UI step and `afterInterruptedLogout`) are
// guarded to the platforms with a hosted UI; an unguarded type with guarded users compiles everywhere.
/// A lease body's own result, for a caller the lock answered early (an interrupt) that must still learn what the
/// body did; and whether the body started at all, as a claim: the body begins, or the caller abandons it, never
/// both.
final class LeaseBodyResult<Value: Sendable>: @unchecked Sendable {

    // `@unchecked Sendable`: every property is only touched while holding `lock`.
    private let lock = NSLock()
    private var result: Result<Value, Error>?
    private var waiters: [CheckedContinuation<Result<Value, Error>, Never>] = []
    private var begun = false
    private var abandoned = false

    /// The body's first step. `false` if the caller has abandoned it: the body must not run.
    func begin() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !abandoned else {
            return false
        }
        begun = true
        return true
    }

    /// The interrupted caller's first step. `true` if the body had not begun, which it now never will: there is no
    /// result to wait for. `false` if it had begun: its result will come.
    func abandonIfNotBegun() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !begun else {
            return false
        }
        abandoned = true
        return true
    }

    /// Records the body's result, once; later calls are ignored.
    func finish(_ result: Result<Value, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let waiting = waiters
        waiters = []
        lock.unlock()
        for waiter in waiting {
            waiter.resume(returning: result)
        }
    }

    /// Waits for the body's result.
    var value: Result<Value, Error> {
        get async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if let result {
                    lock.unlock()
                    continuation.resume(returning: result)
                    return
                }
                waiters.append(continuation)
                lock.unlock()
            }
        }
    }
}

#if os(iOS) || os(macOS) || os(visionOS)
/// The tokens a hosted-UI sign-in's lease body got, and whether its caller still wants them.
///
/// The body offers its payload; the caller, answered with `CancellationError` by an interrupt, closes the claim.
/// Whichever comes second revokes: a body offering to a closed claim, or a caller closing one that holds a
/// payload. So tokens issued around an interrupt are revoked exactly once, whichever order the two land in.
final class LateSignInClaim: @unchecked Sendable {

    // `@unchecked Sendable`: both are only touched while holding `lock`.
    private let lock = NSLock()
    private var offered: Data?
    private var closed = false

    /// Hands `payload` to the caller. `false` if the caller has already given up: the body revokes it.
    func offer(_ payload: Data) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !closed else {
            return false
        }
        offered = payload
        return true
    }

    /// The caller gives up. Returns the payload already offered, for the caller to revoke.
    func close() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        closed = true
        let payload = offered
        offered = nil
        return payload
    }
}

#endif

extension AuthClientConfiguration {

    /// Whether the configuration has a hosted UI the engine can use: `auth.oauth` with a sign-in and a sign-out
    /// redirect URI (the engine's `hostedUIConfig`).
    var hasHostedUI: Bool {
        guard let oauth = userPool?.oauth else {
            return false
        }
        return !oauth.redirectSignInURIs.isEmpty && !oauth.redirectSignOutURIs.isEmpty
    }
}

extension AuthClientError {

    var isBrowserBusy: Bool {
        if case .browserBusy = self {
            return true
        }
        return false
    }
}
