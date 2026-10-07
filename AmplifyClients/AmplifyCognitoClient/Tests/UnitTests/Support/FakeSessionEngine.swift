//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The credentials payload the fake engine reads and writes: readable JSON, so a test can build one,
/// store it, and check what the core committed.
struct FakePayload: Codable, Equatable {
    var username: String?
    var userId: String?
    var kind: String
    var version: Int
    /// Whether the fake reports these credentials as needing a refresh.
    var stale: Bool
    /// Whether the payload holds AWS credentials.
    var aws: Bool
    /// The identity pool identity, if the payload names one.
    var identityId: String? = nil
    /// Whether the fake reports the user pool tokens themselves as needing a refresh (`nil`: no).
    var tokensStale: Bool? = nil
    /// Whether the credentials came from a hosted-UI sign-in that shared the browser's cookies, so signing
    /// out presents the logout page (`nil`: no).
    var hostedUIShared: Bool? = nil
    /// The user pool refresh token, if a test needs one other than the default `refresh-<username>` (a rotation).
    var refreshToken: String? = nil

    static func signedIn(
        _ username: String = "alice",
        userId: String? = nil,
        kind: SessionKind = .userPoolAndIdentityPool,
        version: Int = 1,
        stale: Bool = false,
        identityId: String? = nil
    ) -> FakePayload {
        FakePayload(
            username: username,
            userId: userId ?? "sub-\(username)",
            kind: kind.storedValue,
            version: version,
            stale: stale,
            aws: kind != .userPoolOnly,
            identityId: identityId
        )
    }

    static func guest(version: Int = 1, stale: Bool = false, identityId: String? = nil) -> FakePayload {
        FakePayload(
            username: nil,
            userId: nil,
            kind: SessionKind.guest.storedValue,
            version: version,
            stale: stale,
            aws: true,
            identityId: identityId
        )
    }

    /// A federated identity: no user pool user, the identity and its AWS credentials.
    static func federated(identityId: String? = "us-east-1:federated", version: Int = 1, stale: Bool = false) -> FakePayload {
        FakePayload(
            username: nil,
            userId: nil,
            kind: SessionKind.federated.storedValue,
            version: version,
            stale: stale,
            aws: true,
            identityId: identityId
        )
    }

    var data: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(self)
        } catch {
            preconditionFailure("fake payload failed to encode: \(error)")
        }
    }

    static func decode(_ data: Data) -> FakePayload? {
        try? JSONDecoder().decode(FakePayload.self, from: data)
    }

    /// The payload after a refresh: one version on, and fresh.
    var refreshed: FakePayload {
        var next = self
        next.version += 1
        next.stale = false
        return next
    }

    /// The session record a sign-in by this payload's user would commit.
    func record(label: String? = nil, includeUserId: Bool = true) -> SessionRecord {
        SessionRecord(
            label: label,
            username: username,
            userId: includeUserId ? userId : nil,
            kind: SessionKind(storedValue: kind) ?? .signedOut,
            credentials: data
        )
    }

    /// The AWS credentials the fake vends for this payload.
    var awsCredentials: CognitoAWSCredentials {
        CognitoAWSCredentials(
            accessKeyId: "AKID-\(username ?? "guest")-v\(version)",
            secretAccessKey: "secret-v\(version)",
            sessionToken: "session-v\(version)",
            expiration: Date(timeIntervalSince1970: 1_790_003_600)
        )
    }

    /// The access token the fake vends for this payload.
    var accessToken: String? {
        guard let username, kind != SessionKind.guest.storedValue, kind != SessionKind.federated.storedValue else {
            return nil
        }
        return "access-\(username)-v\(version)"
    }

    /// The user pool tokens the fake vends for this payload.
    var userPoolTokens: AuthClientUserPoolTokens? {
        guard let username, let accessToken else {
            return nil
        }
        return AuthClientUserPoolTokens(
            idToken: "id-\(username)-v\(version)",
            accessToken: accessToken,
            refreshToken: "refresh-\(username)-v\(version)"
        )
    }
}

enum FakeEngineError: Error, Equatable {
    case unreadablePayload
    case notScripted(String)
}

/// Wraps an error a `confirmSignIn` script throws to say it is retryable, as a wrong code is: the fake
/// keeps the pending attempt, and rethrows `error`.
struct FakeRetryable: Error {
    let error: Error
}

/// A scripted `SessionEngine`: counts every call, lets a test script each network operation, and can hold
/// a refresh or a sign-in open on a `Gate` until the test opens it.
///
/// Its pending sign-in follows the seam's contract: a sign-in that reaches a challenge is retained; a new
/// sign-in supersedes it; `.done` or a failure clears it, except a `FakeRetryable` failure of
/// `confirmSignIn`; `confirmSignIn` with nothing pending throws `invalidState`; and a step held by
/// `holdSignIns(on:)` throws `CancellationError` when released if `cancelPendingSignIn` ran meanwhile.
/// A step held inside a script instead returns whatever the script returns, which models an engine that
/// had already finished when the cancel arrived.
final class FakeSessionEngine: SessionEngine, @unchecked Sendable {

    typealias SignInScript = @Sendable (EngineSignInRequest, Data?) async throws -> EngineStepResult
    typealias ConfirmScript = @Sendable (EngineConfirmSignInRequest) async throws -> EngineStepResult
    typealias WebUIScript = @Sendable (EngineWebUISignInRequest, Data?) async throws -> EngineStepResult

    let context: SessionEngineContext

    // `@unchecked Sendable`: every property below is only touched while holding `lock`.
    private let lock = NSLock()
    private var refreshScript: (@Sendable (Data) async throws -> Data)?
    private var revokeScript: (@Sendable (Data, Bool, EngineHostedUISignOut) async throws -> EngineSignOutOutcome)?
    private var signInScript: SignInScript?
    private var confirmScript: ConfirmScript?
    private var guestScript: (@Sendable (Data?) async throws -> Data)?
    private var deleteScript: (@Sendable (Data) async throws -> Void)?
    private var refreshLatch: Gate?
    private var signInLatch: Gate?
    private var signInsHonourCancellation = false
    private var afterCancel: AfterCancel = .throwPromptly

    /// What a step held by `holdSignIns(on:)` does when `cancelPendingSignIn` ran while it was held: the
    /// two answers the seam allows.
    enum AfterCancel {
        /// Still waiting on Cognito: throw `CancellationError`.
        case throwPromptly
        /// Cognito had already issued the tokens: return them, for the core to refuse and revoke.
        case returnIssuedTokens
    }
    private var challenge: AuthClientSignInStep?
    /// The core's epoch of the pending attempt, and the epoch the latest cancel ended everything below.
    private var attemptEpoch: UInt64 = 0
    private var latestCancelBefore: UInt64 = 0
    private var attemptUsername: String?
    /// The guest payload the pending attempt keeps the identity of.
    private var attemptGuest: Data?
    /// The window the pending attempt's sign-in was given, which a `"WEB_AUTHN"` answer without one uses.
    private var attemptWebAuthnAnchor: EnginePresentationAnchorBox?
    /// The ceremony contexts of the sign-in steps in flight, by epoch: what `cancelPendingSignIn` stops, as
    /// the live engine stops its step's ceremony.
    private var stepCeremonies: [(id: UInt64, epoch: UInt64, context: EngineCeremonyContext)] = []
    private var nextStepCeremonyId: UInt64 = 0
    /// What the fake's ceremony body does, inside the runner: returns the credential's data by default.
    private var ceremonyBody: (@Sendable (EnginePresentationAnchorBox?) async throws -> Data)?
    private var ceremonyAnchors: [EnginePresentationAnchorBox?] = []
    private var challengeReadHook: (@Sendable () async -> Void)?
    /// The pending attempt's Cognito session: a new one for every challenge a step stops on, kept across a wrong
    /// answer, as Cognito's is.
    private var challengeSession: String?
    private var sessionCount = 0
    /// What `pendingChallengeState` answers instead of the saved form of the pending step, when scripted.
    private var stateOverride: ChallengeRecord.State??
    /// Whether `resumeSignIn` refuses every record, as a build that cannot resume it does.
    private var refusesResumes = false
    private var resumes: [(state: ChallengeRecord.State, epoch: UInt64)] = []
    private var refreshed: [Data] = []
    private var refreshForces: [Bool] = []
    private var revoked: [(payload: Data, global: Bool, hostedUI: EngineHostedUISignOut)] = []
    private var webUISignIns: [(request: EngineWebUISignInRequest, current: Data?, epoch: UInt64)] = []
    private var webUIScript: WebUIScript?
    #if os(iOS) || os(macOS) || os(visionOS)
    private var webUIBrowser: FakeBrowser?
    #endif
    private var cancelLatch: Gate?
    private var signIns: [(request: EngineSignInRequest, current: Data?)] = []
    private var confirms: [EngineConfirmSignInRequest] = []
    private var confirmCurrents: [Data?] = []
    private var deletes: [Data] = []
    private var describes = 0
    private var cancels = 0
    private var supersedes = 0
    private var guestFetches = 0
    private var accountOperations: [FakeAccountOperationCall] = []
    private var accountOperationScripts: [FakeAccountOperation: FakeAccountOperationScript] = [:]
    /// The user an `autoSignIn` signs in by default: the last one signed up or confirmed.
    private var signedUpUsername: String?
    /// Moves on every sign-up or confirmation that starts; only the newest one's result sets
    /// `signedUpUsername`, as the live engine's `endSignUpStep` rule.
    private var signUpTicket: UInt64 = 0

    init(context: SessionEngineContext) {
        self.context = context
    }

    // MARK: Scripting

    /// Replaces the default refresh (one version on, fresh) with `script`.
    func scriptRefresh(_ script: @escaping @Sendable (Data) async throws -> Data) {
        withLock { refreshScript = script }
    }

    /// Replaces the default revoke (complete) with a script that either throws or completes.
    func scriptRevoke(_ script: @escaping @Sendable (Data) async throws -> Void) {
        withLock {
            revokeScript = { payload, _, _ in
                try await script(payload)
                return .complete
            }
        }
    }

    /// Replaces the default revoke (complete) with a script that reports server-side failures.
    func scriptRevokeOutcome(_ script: @escaping @Sendable (Data, Bool) async throws -> EngineSignOutOutcome) {
        withLock { revokeScript = { payload, global, _ in try await script(payload, global) } }
    }

    /// Replaces the default revoke (complete) with a script that also sees the hosted-UI plan.
    func scriptHostedUIRevoke(_ script: @escaping @Sendable (Data, Bool, EngineHostedUISignOut) async throws -> EngineSignOutOutcome) {
        withLock { revokeScript = script }
    }

    /// Replaces the default hosted-UI sign-in (done at once, as `web-user`) with `script`.
    func scriptWebUISignIn(_ script: @escaping WebUIScript) {
        withLock { webUIScript = script }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Shows every hosted-UI sign-in in `browser`, which the test ends. Wins over `scriptWebUISignIn`.
    func showWebUISignIns(in browser: FakeBrowser?) {
        withLock { webUIBrowser = browser }
    }
    #endif

    /// Replaces the default sign-in (done, as the request's user) with `script`.
    func scriptSignIn(_ script: @escaping SignInScript) {
        withLock { signInScript = script }
    }

    /// Replaces the default confirmation (done, as the pending sign-in's user) with `script`.
    func scriptConfirmSignIn(_ script: @escaping ConfirmScript) {
        withLock { confirmScript = script }
    }

    /// Replaces the default guest fetch (a fresh guest payload) with `script`.
    func scriptGuestCredentials(_ script: @escaping @Sendable (Data?) async throws -> Data) {
        withLock { guestScript = script }
    }

    /// Replaces the default user deletion (success) with `script`.
    func scriptDeleteUser(_ script: @escaping @Sendable (Data) async throws -> Void) {
        withLock { deleteScript = script }
    }

    /// Holds every refresh on `latch` until it is opened. Each held refresh counts as one arrival.
    func holdRefreshes(on latch: Gate) {
        withLock { refreshLatch = latch }
    }

    /// Holds every `signIn` and `confirmSignIn` on `latch`, after superseding and before the script runs.
    ///
    /// With `honouringCancellation`, a held step whose task was cancelled meanwhile throws
    /// `CancellationError` when released, as a live engine awaiting its state machine may: the mode that
    /// shows whether a caller's cancellation reaches the engine step.
    func holdSignIns(on latch: Gate, honouringCancellation: Bool = false, afterCancel: AfterCancel = .throwPromptly) {
        withLock {
            signInLatch = latch
            signInsHonourCancellation = honouringCancellation
            self.afterCancel = afterCancel
        }
    }

    func setPendingChallenge(_ step: AuthClientSignInStep?) {
        withLock { challenge = step }
    }

    /// Runs `hook` during every read of `pendingChallenge`, after the value is taken and before it is
    /// returned, so a test can act while a reader is suspended on it.
    func duringPendingChallengeRead(_ hook: (@Sendable () async -> Void)?) {
        withLock { challengeReadHook = hook }
    }

    // MARK: Counters

    var refreshCalls: [Data] {
        withLock { refreshed }
    }

    /// The `force` flag of each refresh, in order.
    var refreshForceFlags: [Bool] {
        withLock { refreshForces }
    }

    var revokeCalls: [Data] {
        withLock { revoked.map(\.payload) }
    }

    /// The `global` flag of each revoke, in order.
    var revokeHostedUIPlans: [EngineHostedUISignOut] {
        withLock { revoked.map(\.hostedUI) }
    }

    var webUISignInCalls: [(request: EngineWebUISignInRequest, current: Data?, epoch: UInt64)] {
        withLock { webUISignIns }
    }

    var revokeGlobalFlags: [Bool] {
        withLock { revoked.map(\.global) }
    }

    var signInCalls: [(request: EngineSignInRequest, current: Data?)] {
        withLock { signIns }
    }

    var confirmSignInCalls: [EngineConfirmSignInRequest] {
        withLock { confirms }
    }

    /// The `current` guest payload each confirmation was given.
    var confirmSignInCurrents: [Data?] {
        withLock { confirmCurrents }
    }

    var deleteUserCalls: [Data] {
        withLock { deletes }
    }

    var describeCount: Int {
        withLock { describes }
    }

    var cancelPendingSignInCount: Int {
        withLock { cancels }
    }

    /// How many sign-ins found an attempt pending and superseded it.
    var supersededCount: Int {
        withLock { supersedes }
    }

    var guestFetchCount: Int {
        withLock { guestFetches }
    }

    // MARK: SessionEngine

    func describe(_ payload: Data) throws -> CredentialSummary {
        withLock { describes += 1 }
        guard let decoded = FakePayload.decode(payload), let kind = SessionKind(storedValue: decoded.kind) else {
            throw FakeEngineError.unreadablePayload
        }
        return CredentialSummary(kind: kind, username: decoded.username, userId: decoded.userId, identityId: decoded.identityId)
    }

    /// Two `FakePayload`s hold the same credentials when they decode equal, however their keys were ordered, as the
    /// live engine compares decoded `AmplifyCredentials`. Anything else is compared byte for byte.
    func sameCredentials(_ lhs: Data, _ rhs: Data) -> Bool {
        if let lhs = FakePayload.decode(lhs), let rhs = FakePayload.decode(rhs) {
            return lhs == rhs
        }
        return lhs == rhs
    }

    func awsCredentials(in payload: Data) throws -> CognitoAWSCredentials? {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.aws ? decoded.awsCredentials : nil
    }

    func accessToken(in payload: Data) throws -> String? {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.accessToken
    }

    func userPoolTokens(in payload: Data) throws -> AuthClientUserPoolTokens? {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.userPoolTokens
    }

    func needsRefresh(_ payload: Data, at now: Date) throws -> Bool {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.stale
    }

    func userPoolTokensNeedRefresh(_ payload: Data, at now: Date) throws -> Bool {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.tokensStale ?? false
    }

    func signIn(_ request: EngineSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        let (script, latch, honours, started) = withLock { () -> (SignInScript?, Gate?, Bool, Int) in
            signIns.append((request, current))
            if challenge != nil {
                // A new sign-in supersedes the pending one.
                challenge = nil
                supersedes += 1
            }
            attemptEpoch = epoch
            attemptUsername = request.username
            attemptGuest = current
            attemptWebAuthnAnchor = request.webAuthn?.anchor
            return (signInScript, signInLatch, signInsHonourCancellation, cancels)
        }
        let ceremony = registerStepCeremony(request.webAuthn, epoch: epoch)
        defer { endStepCeremony(ceremony) }
        if let latch {
            await latch.pass()
            try checkStillWanted(since: started, epoch: epoch, honouringCancellation: honours)
        }
        return try await settle(retryable: false) {
            if let script {
                return try await script(request, current)
            }
            return .done(payload: Self.signedIn(request.username, keepingIdentityOf: current).data)
        }
    }

    /// The default completed sign-in: the user, keeping a guest payload's identity, as the live engine's
    /// identity pool step does.
    static func signedIn(_ username: String, keepingIdentityOf guest: Data?) -> FakePayload {
        FakePayload.signedIn(username, identityId: guest.flatMap(FakePayload.decode)?.identityId)
    }

    func confirmSignIn(_ request: EngineConfirmSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        let (pending, username, guest, script, latch, honours, started) = withLock {
            () -> (Bool, String?, Data?, ConfirmScript?, Gate?, Bool, Int) in
            confirms.append(request)
            confirmCurrents.append(current)
            if current != nil {
                attemptGuest = current
            }
            return (challenge != nil, attemptUsername, attemptGuest, confirmScript, signInLatch, signInsHonourCancellation, cancels)
        }
        guard pending else {
            throw AuthClientError.invalidState(
                "There is no sign-in in progress for this session",
                "Call signIn first."
            )
        }
        // The live engine's rule: a WebAuthn selection with no window at all is refused before anything is
        // sent, and the challenge is kept.
        let (step, anchor) = withLock { (challenge, request.webAuthn?.anchor ?? attemptWebAuthnAnchor) }
        if anchor == nil, let step, LiveSignInSteps.selectsWebAuthn(request.challengeResponse, at: step) {
            throw SessionCore.presentationAnchorRequired()
        }
        let ceremony = registerStepCeremony(request.webAuthn, epoch: epoch)
        defer { endStepCeremony(ceremony) }
        if let latch {
            await latch.pass()
            try checkStillWanted(since: started, epoch: epoch, honouringCancellation: honours)
        }
        return try await settle(retryable: true) {
            if let script {
                return try await script(request)
            }
            return .done(payload: Self.signedIn(username ?? "alice", keepingIdentityOf: guest).data)
        }
    }

    /// After a held step is released: the seam's contract makes a step throw once `cancelPendingSignIn`
    /// has run, and the cancellation-honouring mode makes it throw when its task was cancelled.
    /// Only a cancel for a later epoch than the step's counts, as in the live engine.
    private func checkStillWanted(since started: Int, epoch: UInt64, honouringCancellation honours: Bool) throws {
        let (cancelled, mode) = withLock { (cancels != started && latestCancelBefore > epoch, afterCancel) }
        if cancelled, mode == .returnIssuedTokens {
            return
        }
        if cancelled || (honours && Task.isCancelled) {
            withLock { challenge = nil }
            throw CancellationError()
        }
    }

    /// Applies a sign-in step's result to the pending attempt, per the seam's contract.
    private func settle(
        retryable: Bool,
        _ body: () async throws -> EngineStepResult
    ) async throws -> EngineStepResult {
        do {
            let result = try await body()
            withLock {
                switch result {
                case .challenge(let step):
                    challenge = step
                    // Never the session a resumed attempt holds: a new challenge is Cognito's new session.
                    var next: String
                    repeat {
                        sessionCount += 1
                        next = "fake-session-\(sessionCount)"
                    } while next == challengeSession
                    challengeSession = next
                case .done:
                    challenge = nil
                }
            }
            return result
        } catch let error as FakeRetryable where retryable {
            throw error.error
        } catch let error as AuthClientError where retryable && error.isValidation {
            // The contract: an answer rejected as invalid keeps the attempt.
            throw error
        } catch let error as FakeRetryable {
            withLock { challenge = nil }
            throw error.error
        } catch {
            withLock { challenge = nil }
            throw error
        }
    }

    func refresh(_ payload: Data, force: Bool) async throws -> Data {
        let (script, latch) = withLock { () -> ((@Sendable (Data) async throws -> Data)?, Gate?) in
            refreshed.append(payload)
            refreshForces.append(force)
            return (refreshScript, refreshLatch)
        }
        if let latch {
            await latch.pass()
        }
        if let script {
            return try await script(payload)
        }
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.refreshed.data
    }

    func fetchGuestCredentials(current: Data?) async throws -> Data {
        let script = withLock { () -> (@Sendable (Data?) async throws -> Data)? in
            guestFetches += 1
            return guestScript
        }
        if let script {
            return try await script(current)
        }
        return FakePayload.guest(identityId: "us-east-1:guest").data
    }

    func revoke(_ payload: Data, global: Bool, hostedUI: EngineHostedUISignOut) async throws -> EngineSignOutOutcome {
        let script = withLock { () -> (@Sendable (Data, Bool, EngineHostedUISignOut) async throws -> EngineSignOutOutcome)? in
            revoked.append((payload, global, hostedUI))
            return revokeScript
        }
        return try await script?(payload, global, hostedUI) ?? .complete
    }

    func signOutPresentsBrowser(_ payload: Data) throws -> Bool {
        guard let decoded = FakePayload.decode(payload) else {
            throw FakeEngineError.unreadablePayload
        }
        return decoded.hostedUIShared ?? false
    }

    /// Supersedes a pending sign-in, as `signIn` does, then answers from the browser, the script, or, by
    /// default, `.done` as `web-user`, keeping a guest's identity, the payload marked as sharing the browser's
    /// cookies when the request did not prefer an ephemeral session.
    func signInWithWebUI(_ request: EngineWebUISignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        let script = withLock { () -> WebUIScript? in
            webUISignIns.append((request, current, epoch))
            if challenge != nil {
                challenge = nil
                supersedes += 1
            }
            attemptEpoch = epoch
            return webUIScript
        }
        var payload = Self.signedIn("web-user", keepingIdentityOf: current)
        payload.hostedUIShared = request.options.prefersEphemeralSession ? nil : true
        let result = EngineStepResult.done(payload: payload.data)
        #if os(iOS) || os(macOS) || os(visionOS)
        if let browser = withLock({ webUIBrowser }) {
            return try await browser.show(request, answering: result)
        }
        #endif
        if let script {
            return try await script(request, current)
        }
        return result
    }

    func deleteUser(_ payload: Data) async throws {
        let script = withLock { () -> (@Sendable (Data) async throws -> Void)? in
            deletes.append(payload)
            return deleteScript
        }
        try await script?(payload)
    }

    var pendingChallenge: AuthClientSignInStep? {
        get async {
            let (value, hook) = withLock { (challenge, challengeReadHook) }
            await hook?()
            return value
        }
    }

    /// The pending step's saved form, as the live engine saves it (`ChallengeRecord.State.fake`), with the
    /// attempt's username and Cognito session; or what `scriptPendingChallengeState` set.
    var pendingChallengeState: ChallengeRecord.State? {
        get async {
            withLock {
                if let stateOverride {
                    return stateOverride
                }
                guard let challenge else {
                    return nil
                }
                return .fake(challenge, session: challengeSession ?? "fake-session", username: attemptUsername ?? "alice")
            }
        }
    }

    /// Resumes a saved sign-in as the pending attempt of `epoch`, as the live engine does: refused while one is
    /// pending, and when `refuseResumes` was called.
    func resumeSignIn(from state: ChallengeRecord.State, epoch: UInt64) async -> AuthClientSignInStep? {
        withLock {
            resumes.append((state, epoch))
            guard challenge == nil, !refusesResumes, let step = state.fakeResumedStep else {
                return nil
            }
            challenge = step
            challengeSession = state.session
            attemptEpoch = epoch
            attemptUsername = state.fakeUsername
            return step
        }
    }

    /// Makes `pendingChallengeState` answer `state` (`nil`: nothing saveable) whatever is pending; `.none` undoes it.
    func scriptPendingChallengeState(_ state: ChallengeRecord.State??) {
        withLock { stateOverride = state }
    }

    /// Makes `resumeSignIn` refuse every record.
    func refuseResumes() {
        withLock { refusesResumes = true }
    }

    /// Every `resumeSignIn` call, in order.
    var resumeCalls: [(state: ChallengeRecord.State, epoch: UInt64)] {
        withLock { resumes }
    }

    /// Holds every `cancelPendingSignIn` on `latch` before it takes effect: the moment between the core moving
    /// its epoch and the engine hearing of it.
    func holdCancels(on latch: Gate?) {
        withLock { cancelLatch = latch }
    }

    func cancelPendingSignIn(before epoch: UInt64) async {
        if let latch = withLock({ cancelLatch }) {
            await latch.pass()
        }
        let ceremonies = withLock { () -> [EngineCeremonyContext] in
            cancels += 1
            latestCancelBefore = epoch
            let ceremonies = stepCeremonies.filter { $0.epoch < epoch }.map(\.context)
            guard attemptEpoch < epoch else {
                return ceremonies
            }
            challenge = nil
            attemptUsername = nil
            attemptWebAuthnAnchor = nil
            return ceremonies
        }
        // As the live engine: a step's ceremony runs where cancelling the step does not reach it.
        for context in ceremonies {
            context.cancel()
        }
    }

    // MARK: WebAuthn ceremonies

    /// Replaces the default ceremony body (the credential's data, at once) with `body`, which gets the
    /// window the ceremony was run over. `runCeremony(_:anchor:)` and associate run it inside the runner.
    func scriptCeremonyBody(_ body: @escaping @Sendable (EnginePresentationAnchorBox?) async throws -> Data) {
        withLock { ceremonyBody = body }
    }

    /// The window of every ceremony body the fake ran, in order.
    var ceremonyAnchorCalls: [EnginePresentationAnchorBox?] {
        withLock { ceremonyAnchors }
    }

    /// The window a confirmation's ceremony uses: its own, else the pending attempt's sign-in's.
    func webAuthnAnchor(for request: EngineConfirmSignInRequest) -> EnginePresentationAnchorBox? {
        withLock { request.webAuthn?.anchor ?? attemptWebAuthnAnchor }
    }

    /// Runs one ceremony where the live engine does: through the context's runner (the sheet lease), with
    /// the scripted body inside it. With no window the live engine refuses before the runner, and so does
    /// this.
    func runCeremony(_ context: EngineCeremonyContext?, anchor: EnginePresentationAnchorBox?) async throws -> Data {
        guard let context, let anchor else {
            throw SessionCore.presentationAnchorRequired()
        }
        let body = withLock { ceremonyBody }
        return try await context.ceremony { [self] in
            withLock { ceremonyAnchors.append(anchor) }
            return try await body?(anchor) ?? Data("credential".utf8)
        }
    }

    private func registerStepCeremony(_ context: EngineCeremonyContext?, epoch: UInt64) -> UInt64? {
        guard let context else {
            return nil
        }
        return withLock {
            nextStepCeremonyId += 1
            stepCeremonies.append((nextStepCeremonyId, epoch, context))
            return nextStepCeremonyId
        }
    }

    private func endStepCeremony(_ id: UInt64?) {
        guard let id else {
            return
        }
        withLock { stepCeremonies.removeAll { $0.id == id } }
    }

    // MARK: Account operations (`FakeSessionEngine+AccountOperations.swift`)

    /// Every account-operation call, in order.
    var accountOperationCalls: [FakeAccountOperationCall] {
        withLock { accountOperations }
    }

    /// Replaces the default result of `operation` with `script`, which returns the operation's result type
    /// (or throws).
    func scriptAccountOperation(_ operation: FakeAccountOperation, _ script: @escaping FakeAccountOperationScript) {
        withLock { accountOperationScripts[operation] = script }
    }

    /// Records `call`, then runs its script, else returns `defaultResult`.
    ///
    /// Every sign-up or confirmation moves the sign-up state, as the seam's contract says: it ends any earlier
    /// auto-sign-in session when it starts, and only a `.completeAutoSignIn` result of the newest one started
    /// leaves a new one.
    func recordAccountOperation<Result: Sendable>(_ call: FakeAccountOperationCall, default defaultResult: @autoclosure () -> Result) async throws -> Result {
        let (script, ticket) = withLock { () -> (FakeAccountOperationScript?, UInt64) in
            accountOperations.append(call)
            switch call {
            case .signUp, .confirmSignUp:
                signedUpUsername = nil
                signUpTicket += 1
            default:
                break
            }
            return (accountOperationScripts[call.operation], signUpTicket)
        }
        let typed: Result
        if let script {
            let result = try await script(call)
            guard let value = result as? Result else {
                preconditionFailure("the \(call.operation) script returned \(type(of: result)), not \(Result.self)")
            }
            typed = value
        } else {
            typed = defaultResult()
        }
        if let signUp = typed as? AuthClientSignUpResult, case .completeAutoSignIn = signUp.nextStep {
            let username: String?
            switch call {
            case .signUp(let request):
                username = request.username
            case .confirmSignUp(let request):
                username = request.username
            default:
                username = nil
            }
            withLock {
                if let username, ticket == signUpTicket {
                    signedUpUsername = username
                }
            }
        }
        return typed
    }

    /// Whether the last sign-up or confirmation left an auto-sign-in session. Only a later sign-up or
    /// confirmation clears it: not a completed `autoSignIn`, not a sign-out, not `cancelPendingSignIn`.
    var hasAutoSignInSession: Bool {
        get async { withLock { signedUpUsername != nil } }
    }

    /// A sign-in step like `signIn`: with no auto-sign-in session it throws the plugin's `invalidState`
    /// before superseding anything; otherwise it supersedes a pending sign-in, is held by
    /// `holdSignIns(on:)` like `signIn`, and follows the same contract. By default `.done` as the user who
    /// signed up, keeping a guest's identity.
    func autoSignIn(current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        let (username, latch, honours, started) = withLock { () -> (String?, Gate?, Bool, Int) in
            guard let signedUpUsername else {
                return (nil, nil, false, cancels)
            }
            if challenge != nil {
                challenge = nil
                supersedes += 1
            }
            attemptEpoch = epoch
            attemptGuest = current
            attemptUsername = signedUpUsername
            return (signedUpUsername, signInLatch, signInsHonourCancellation, cancels)
        }
        guard let username else {
            withLock { accountOperations.append(.autoSignIn(current: current, epoch: epoch)) }
            throw SessionCore.notSignedUp()
        }
        if let latch {
            await latch.pass()
            try checkStillWanted(since: started, epoch: epoch, honouringCancellation: honours)
        }
        return try await settle(retryable: false) {
            try await recordAccountOperation(
                .autoSignIn(current: current, epoch: epoch),
                default: EngineStepResult.done(payload: Self.signedIn(username, keepingIdentityOf: current).data)
            )
        }
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

extension AuthClientError {

    var isValidation: Bool {
        if case .validation = self {
            return true
        }
        return false
    }
}

/// A scripted `SessionRevoker` for the static sign-out path.
final class FakeRevoker: SessionRevoker, @unchecked Sendable {

    private let lock = NSLock()
    private var calls: [Data] = []
    private var script: (@Sendable (Data) throws -> EngineSignOutOutcome)?

    var revokeCalls: [Data] {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    /// Replaces the default revoke (complete) with a script that either throws or completes.
    func scriptRevoke(_ script: @escaping @Sendable (Data) throws -> Void) {
        scriptRevokeOutcome { payload in
            try script(payload)
            return .complete
        }
    }

    func scriptRevokeOutcome(_ script: @escaping @Sendable (Data) throws -> EngineSignOutOutcome) {
        lock.lock()
        defer { lock.unlock() }
        self.script = script
    }

    func revoke(_ payload: Data) async throws -> EngineSignOutOutcome {
        try record(payload)?(payload) ?? .complete
    }

    func signOutPresentsBrowser(_ payload: Data) -> Bool {
        FakePayload.decode(payload)?.hostedUIShared ?? false
    }

    private func record(_ payload: Data) -> (@Sendable (Data) throws -> EngineSignOutOutcome)? {
        lock.lock()
        defer { lock.unlock() }
        calls.append(payload)
        return script
    }
}
