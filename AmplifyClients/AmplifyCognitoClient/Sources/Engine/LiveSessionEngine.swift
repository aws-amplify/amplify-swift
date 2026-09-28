//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// The session engine over the real Cognito engine (`InternalAWSCognitoAuth`), one per session core.
///
/// **Payload in, payload out.** Every operation gets a fresh pair of state machines, seeded with the payload
/// it was handed and configured in memory; the engine never keeps a copy of the session's
/// credentials between operations. It keeps exactly two things between calls, both in memory and both this
/// session's only:
/// - a sign-in stopped on a challenge: its machine is retained as the pending attempt until the sign-in
///   completes, fails terminally, is superseded or is cancelled;
/// - the sign-up state (`signUpState`), the plugin's one `SignUpState`: every sign-up and confirmation
///   moves it, `confirmSignUp` reads the session of a sign-up waiting for confirmation from it, and
///   `autoSignIn` accepts only its `signedUp` case. Unlike the attempt it survives a completed `autoSignIn`, a
///   sign-in, a sign-out and `cancelPendingSignIn`, as the plugin's does.
///
/// **What is serialized.** The core already runs one sign-in step at a time per session (its `signInLock`).
/// The actor records the pending attempt and the step in flight; `cancelPendingSignIn` cancels the step in
/// flight without waiting for it, and a step that ends after a cancel never becomes
/// the pending attempt. The session operations (`refresh`, `fetchGuestCredentials`, `revoke`,
/// `deleteUser`) are `nonisolated`: each builds its own machines, touches no actor state, and so never
/// disturbs a pending challenge; the core's gates and flights serialize them against each other.
///
/// `init` builds `EngineResources` only: pure values and the SDK clients the core already made. No I/O, no
/// `await`, so it is safe under the registry lock. Nothing needs async teardown: a step in flight is an
/// unstructured task the engine awaits, so the engine outlives it.
actor LiveSessionEngine: SessionEngine {

    nonisolated let resources: EngineResources

    /// The sign-in waiting on a challenge, if any.
    private var attempt: SignInAttempt?
    /// How many cancels ran, and the epoch the latest one was for: what a new sign-in checks after its own
    /// suspension, so a cancel meant for it is not absorbed.
    private var cancelCount: UInt64 = 0
    private var latestCancelBefore: UInt64 = 0
    /// The sign-in step in flight, and its operation, so `cancelPendingSignIn` can end the task and stop the
    /// machine (a first `signIn` step is not the pending attempt yet).
    private var inFlight: InFlightStep?
    private var nextStepId: UInt64 = 0
    /// Told of every step's operation a cancel stopped. For tests.
    private let onStepCancelled: (@Sendable (EngineOperation) -> Void)?
    /// Awaited while a cancel stops a step, after the step's task is cancelled and before its machine is.
    /// For tests: the moment the cancelled step can finish and settle its tap.
    private let whileStopping: (@Sendable () async -> Void)?
    /// What presents a passkey sheet: the platform's, unless a test replaces it.
    nonisolated let webAuthnCeremonies: LiveWebAuthnCeremonies

    /// A sign-in step in flight: its task, and the operation whose machine it drives.
    private struct InFlightStep {
        let id: UInt64
        /// The core's sign-in epoch the step belongs to.
        let epoch: UInt64
        let task: Task<SignInStepOutcome, Error>
        let operation: EngineOperation
        /// The step's ceremony context, which `cancelPendingSignIn` stops: a ceremony runs in an effect task
        /// that cancelling `task` does not reach.
        let webAuthn: EngineCeremonyContext?
    }
    /// The plugin's `SignUpState` for this session. Moved only through `beginSignUpStep(_:)` and
    /// `endSignUpStep(_:_:)`.
    private(set) var signUpState = LiveSignUpState.none
    /// Moves on every sign-up or confirmation that starts, so only the newest one's end moves `signUpState`.
    private var signUpTicket: UInt64 = 0

    init(context: SessionEngineContext) {
        self.init(resources: EngineResources(context: context))
    }

    init(
        resources: EngineResources,
        onStepCancelled: (@Sendable (EngineOperation) -> Void)? = nil,
        whileStopping: (@Sendable () async -> Void)? = nil,
        webAuthnCeremonies: LiveWebAuthnCeremonies = .platform
    ) {
        self.resources = resources
        self.onStepCancelled = onStepCancelled
        self.whileStopping = whileStopping
        self.webAuthnCeremonies = webAuthnCeremonies
    }

    // MARK: Pure: no network, no storage, no actor hop

    nonisolated func describe(_ payload: Data) throws -> CredentialSummary {
        try CredentialSummary(Self.credentials(in: payload))
    }

    nonisolated func awsCredentials(in payload: Data) throws -> CognitoAWSCredentials? {
        try Self.credentials(in: payload).awsCredentials.map(CognitoAWSCredentials.init)
    }

    nonisolated func accessToken(in payload: Data) throws -> String? {
        try Self.credentials(in: payload).userPoolTokens?.accessToken
    }

    nonisolated func userPoolTokens(in payload: Data) throws -> AuthClientUserPoolTokens? {
        try Self.credentials(in: payload).userPoolTokens.map(AuthClientUserPoolTokens.init)
    }

    /// `!areValid(at: now)`, the plugin's refresh test (`FetchAuthSessionOperationHelper`): no credentials,
    /// or any token or AWS credential expiring within the engine's two-minute buffer of `now`, or a token
    /// whose claims cannot be read. For a user-pool-only payload only its tokens count, as in the plugin: a
    /// refresh that stored rotated tokens and then failed its identity pool step stores
    /// `userPoolAndIdentityPool(new tokens, old identity, old AWS credentials)`, whose old credentials this
    /// already flags.
    nonisolated func needsRefresh(_ payload: Data, at now: Date) throws -> Bool {
        try !Self.credentials(in: payload).areValid(at: now)
    }

    nonisolated func userPoolTokensNeedRefresh(_ payload: Data, at now: Date) throws -> Bool {
        try Self.credentials(in: payload).userPoolTokens?
            .doesExpire(in: AmplifyCredentials.expiryBufferInSeconds, at: now) ?? false
    }

    /// A payload's credentials, decoded as the plugin's store decodes them.
    static func credentials(in payload: Data) throws -> AmplifyCredentials {
        try CredentialSlot.decode(payload)
    }

    // MARK: Sign-in

    func signIn(_ request: EngineSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try requireUserPool()
        try await beginSignIn(epoch: epoch)
        let operation = try resources.makeOperation(seed: current.flatMap(Self.guestSeed))
        let anchor = request.webAuthn?.anchor
        operation.webAuthnSignIn.ceremony = webAuthnCeremonies.signInCeremony(request.webAuthn, anchor: anchor)
        let resources = resources
        return try await run(epoch: epoch, on: operation, webAuthn: request.webAuthn, keepingAnchor: anchor) {
            try await LiveSignInSteps.signIn(request, on: operation, resources: resources)
        }
    }

    func confirmSignIn(_ request: EngineConfirmSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try requireUserPool()
        guard let attempt else {
            throw LiveSignInSteps.noSignInInProgress()
        }
        // An attempt from an earlier epoch belongs to a sign-in the core has since ended (a sign-out whose
        // cancel has not reached the engine yet): never answer it under the newer epoch, where the core's
        // commit check would let it sign the session in behind the sign-out.
        guard attempt.epoch == epoch else {
            self.attempt = nil
            await stop(nil, attempt)
            throw LiveSignInSteps.noSignInInProgress()
        }
        // A passkey sheet uses this call's window, else the sign-in's. A WebAuthn
        // selection with neither is refused before anything is sent, and the challenge is kept.
        let anchor = request.webAuthn?.anchor ?? attempt.webAuthnAnchor
        if anchor == nil, LiveSignInSteps.selectsWebAuthn(request.challengeResponse, at: attempt.step) {
            throw SessionCore.presentationAnchorRequired()
        }
        // The session became a guest while the sign-in waited: the attempt continues from the
        // guest's payload rather than the one it started with.
        if let guest = try current.flatMap(Self.guestSeed) {
            try attempt.operation.slot.reseed(CredentialSlot.decode(guest))
        }
        attempt.operation.webAuthnSignIn.ceremony = webAuthnCeremonies.signInCeremony(request.webAuthn, anchor: anchor)
        return try await run(epoch: epoch, on: attempt.operation, webAuthn: request.webAuthn, keepingAnchor: anchor) {
            try await LiveSignInSteps.confirm(request, attempt: attempt)
        }
    }

    var pendingChallenge: AuthClientSignInStep? {
        attempt?.step
    }

    // MARK: The challenge record (`ChallengeRecord+Engine.swift` says which states are saved)

    var pendingChallengeState: ChallengeRecord.State? {
        get async {
            guard let attempt else {
                return nil
            }
            return await ChallengeRecord.State(attempt.operation.authMachine.currentState)
        }
    }

    /// A fresh operation whose machine starts in the saved state, made the pending attempt of `epoch`. It is never
    /// configured (configuring would sign the machine out, and the challenge state cannot be reached by events), so
    /// its credential machine is primed instead. Refused while an attempt or a step is live: those are newer.
    func resumeSignIn(from state: ChallengeRecord.State, epoch: UInt64) async -> AuthClientSignInStep? {
        guard attempt == nil, inFlight == nil, resources.authConfiguration.getUserPoolConfiguration() != nil,
              let (machineState, step) = state.resumedState,
              let operation = try? resources.makeOperation(seed: nil, resuming: machineState) else {
            return nil
        }
        await operation.primeCredentialStore()
        // Again after the suspension: a sign-in that started meanwhile owns the session.
        guard attempt == nil, inFlight == nil else {
            return nil
        }
        attempt = SignInAttempt(operation: operation, step: step, epoch: epoch)
        return step
    }

    /// Every new sign-in's preamble (the password sign-in here, the sign-up's auto sign-in in its extension):
    /// supersedes the pending attempt and any step in flight (`AWSAuthSignInTask.validateCurrentState`), and
    /// throws `CancellationError` if a cancel for `epoch` arrived while they were being stopped, rather than
    /// absorbing it.
    func beginSignIn(epoch: UInt64) async throws {
        let cancelsBefore = cancelCount
        let (stopped, dropped) = take(before: .max)
        await stop(stopped, dropped)
        if cancelCount != cancelsBefore, latestCancelBefore > epoch {
            throw CancellationError()
        }
    }

    /// Ends the step in flight and the pending attempt, but only those the core started before `epoch`: a
    /// sign-out moves the core's epoch and then cancels, and a sign-in started in between, with the new
    /// epoch, is not the one it ends.
    func cancelPendingSignIn(before epoch: UInt64) async {
        cancelCount &+= 1
        latestCancelBefore = max(latestCancelBefore, epoch)
        let (stopped, dropped) = take(before: epoch)
        await stop(stopped, dropped)
    }

    /// Starts a sign-up or confirmation: the sign-up state becomes `.inProgress(data)`, as the plugin's moves to
    /// `initiatingSignUp` / `confirmingSignUp` when the event is sent.
    ///
    /// - Returns: the step's ticket, for `endSignUpStep(_:_:)`.
    func beginSignUpStep(_ data: SignUpEventData) -> UInt64 {
        signUpTicket += 1
        signUpState = .inProgress(data)
        return signUpTicket
    }

    /// Ends a sign-up or confirmation with the state it reached, unless a newer one started meanwhile: the
    /// plugin's one machine ends in the state of the last event it resolved.
    func endSignUpStep(_ ticket: UInt64, _ state: LiveSignUpState) {
        guard ticket == signUpTicket else {
            return
        }
        signUpState = state
    }

    /// Runs one sign-in step as an unstructured task, so `cancelPendingSignIn` can end it, and records what
    /// it reached, unless a cancel or a newer sign-in stopped it meanwhile. `operation` is built before the
    /// call, so a cancel can reach its machine from the start. Internal, for every sign-in step, the sign-up
    /// extension's included.
    ///
    /// - Parameters:
    ///   - webAuthn: the step's ceremony context, stopped with the step by `cancelPendingSignIn`.
    ///   - keepingAnchor: the window a challenge this step stops on keeps, for a later `"WEB_AUTHN"` answer.
    func run(
        epoch: UInt64,
        on operation: EngineOperation,
        webAuthn: EngineCeremonyContext? = nil,
        keepingAnchor anchor: EnginePresentationAnchorBox? = nil,
        _ body: @escaping @Sendable () async throws -> SignInStepOutcome
    ) async throws -> EngineStepResult {
        nextStepId &+= 1
        let id = nextStepId
        let seenBefore = operation.tokenTap.seenCount
        let task = Task { try await body() }
        inFlight = InFlightStep(id: id, epoch: epoch, task: task, operation: operation, webAuthn: webAuthn)
        let result = await task.result
        let handedBack = Self.refreshToken(handedBackBy: result)
        if Self.dropsItsOperation(result) {
            // A failed step's tokens are nobody's: a hosted-UI response the identity check refused reported its
            // refresh token to the tap and then threw, with nothing in `issued`.
            operation.tokenTap.cancel()
        } else if case .failure = result {
            // A failure that keeps the attempt keeps the tap open for the next answer, but what this step was
            // issued (an answer with a refresh token and no ID or access token) is not committed either.
            operation.tokenTap.revokeSeen(since: seenBefore, except: handedBack, revokingWith: resources.services.userPool)
        }
        operation.tokenTap.settle(handedBack: handedBack, revokingWith: resources.services.userPool)
        // Only a cancel or a newer sign-in (`take`) clears or replaces `inFlight` while the step runs.
        let isCurrent = inFlight?.id == id
        if isCurrent {
            inFlight = nil
        }
        switch result {
        case .success(.done(let payload)):
            if isCurrent {
                attempt = nil
            }
            return .done(payload: payload)
        case .success(.challenge(let step, let operation)):
            guard isCurrent else {
                // Never a challenge after a cancel: the machine is dropped.
                await LiveSignInSteps.cancelIfSigningIn(operation)
                throw CancellationError()
            }
            attempt = SignInAttempt(operation: operation, step: step, epoch: epoch, webAuthnAnchor: anchor)
            return .challenge(step)
        case .failure(let failure as SignInStepFailure):
            if isCurrent, !failure.keepsAttempt {
                attempt = nil
            }
            if let issued = failure.issued {
                // Best effort: the sign-in failed, but Cognito issued a refresh token that nothing holds. From a
                // task of its own: the caller's may be cancelled (an interrupted hosted-UI lease), and a cancelled
                // task's events never reach the machine.
                await Task { _ = try? await self.revoke(issued, global: false) }.value
            }
            throw failure.error
        case .failure(let error):
            if isCurrent {
                attempt = nil
            }
            throw error
        }
    }

    /// The refresh token a step's result hands back for someone to revoke: a `.done` payload's (the core
    /// revokes one returned after a cancel) or a failure's issued tokens' (`run` revokes them).
    static func refreshToken(handedBackBy result: Result<SignInStepOutcome, Error>) -> String? {
        let payload: Data?
        switch result {
        case .success(.done(let done)):
            payload = done
        case .failure(let failure as SignInStepFailure):
            payload = failure.issued
        case .success(.challenge), .failure:
            payload = nil
        }
        return payload.flatMap { try? credentials(in: $0).userPoolTokens?.refreshToken }
    }

    /// Whether a step's result ends its operation: any failure but one that keeps the pending attempt, whose
    /// operation answers the challenge again.
    static func dropsItsOperation(_ result: Result<SignInStepOutcome, Error>) -> Bool {
        switch result {
        case .success:
            return false
        case .failure(let failure as SignInStepFailure):
            return !failure.keepsAttempt
        case .failure:
            return true
        }
    }

    /// Takes the step in flight and the pending attempt the core started before `epoch`, with no suspension:
    /// what a new sign-in (`.max`: everything) or a cancel ends.
    private func take(before epoch: UInt64) -> (InFlightStep?, SignInAttempt?) {
        var stopped: InFlightStep?
        if let step = inFlight, step.epoch < epoch {
            stopped = step
            inFlight = nil
        }
        var dropped: SignInAttempt?
        if let pending = attempt, pending.epoch < epoch {
            dropped = pending
            attempt = nil
        }
        return (stopped, dropped)
    }

    /// Ends the step in flight and stops the machines, without waiting for Cognito.
    ///
    /// Each machine is stopped here, from the actor, not only from inside the cancelled step: a first
    /// `signIn` step is not the pending attempt yet, and a cancelled task cannot send to a machine.
    /// Each operation's tap then revokes whatever refresh token a call still in flight returns.
    private func stop(_ stopped: InFlightStep?, _ dropped: SignInAttempt?) async {
        if let stopped {
            // Marked before the task is cancelled, with no suspension between: the cancelled step may finish,
            // and `run` settle its tap, as soon as this actor suspends, and a tap settled unmarked would never
            // revoke the token a call in flight returns. The tap is settled when
            // the step ends, in `run`, once it is known which token the step hands back.
            stopped.operation.tokenTap.cancel()
            stopped.task.cancel()
            // A passkey ceremony runs in an effect task, out of the step task's reach: stopped explicitly,
            // which closes its sheet (the kept controller) and ends the lease.
            stopped.webAuthn?.cancel()
            onStepCancelled?(stopped.operation)
            await whileStopping?()
            await LiveSignInSteps.cancelIfSigningIn(stopped.operation)
        }
        if let dropped {
            // A confirmation in flight runs on the attempt's own operation: its step, stopped above, hands
            // back what it hands back, and `run` settles the tap then. Settling here too would revoke the
            // tokens the core also revokes.
            guard dropped.operation.tokenTap !== stopped?.operation.tokenTap else {
                return
            }
            await LiveSignInSteps.cancelIfSigningIn(dropped.operation)
            // A pending attempt with no step in flight has nothing to hand back.
            dropped.operation.tokenTap.cancel()
            dropped.operation.tokenTap.settle(handedBack: nil, revokingWith: resources.services.userPool)
        }
    }

    /// `current` as a sign-in's seed: the session's guest payload, so the sign-in starts from the guest's
    /// credentials, as the plugin's does. Anything else starts from no credentials.
    static func guestSeed(_ current: Data) throws -> Data? {
        if case .identityPoolOnly = try credentials(in: current) {
            return current
        }
        return nil
    }

    // MARK: Configuration guards

    /// What keeps `AuthEnvironment`'s `fatalError`s unreachable: no user-pool event without a user pool, and
    /// no identity-pool event without an identity pool.
    nonisolated func requireUserPool() throws {
        guard resources.authConfiguration.getUserPoolConfiguration() != nil else {
            throw AuthClientError.configuration(
                "Could not find user pool configuration",
                "Add a user pool to AuthClientConfiguration."
            )
        }
    }

    nonisolated func requireIdentityPool() throws {
        guard resources.authConfiguration.getIdentityPoolConfiguration() != nil else {
            throw AuthClientError.configuration(
                "Could not find identity pool configuration",
                "Add an identity pool to AuthClientConfiguration."
            )
        }
    }
}
