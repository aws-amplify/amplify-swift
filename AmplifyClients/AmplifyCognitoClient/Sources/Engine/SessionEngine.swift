//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// The Cognito protocol logic of one session: what the session core calls to sign in, refresh, revoke
/// and read a credentials payload.
///
/// **The engine proposes, the core commits.** The engine receives the current credentials payload and
/// returns the next one. It never persists session credentials: the core does the commit-guarded write,
/// handles a discarded write, and publishes state and events. That keeps the commit guard, single-flight,
/// the per-record gate and event emission in one place. The engine does own the protocol, and the
/// per-user device and advanced-security records, which it keeps at the plugin's per-user keys.
///
/// One instance per `SessionCore`, made while the registry lock is held, so its `init` must be cheap and
/// must do no I/O. It may hold in-memory multi-step sign-in state. The core's `deinit` cannot `await`,
/// so the engine must need no async teardown: any internal task is cancelled from its own `deinit`.
///
/// Its public-facing values are client-owned types (`AuthClientSignInStep`, `AuthClientError`), because
/// the client does not depend on Amplify core.
///
/// **Error contract.**
/// - The pure methods may throw any error: a payload they cannot read is an ordinary outcome. The core
///   calls them through the `checked…` wrappers below, which pass `AuthClientError` and `CredentialsError`
///   through and wrap anything else in `AuthClientError.unknown`, with the engine's error as its
///   underlying error. So no engine error type ever reaches a public API.
/// - The network methods throw `SessionEngineError` for the cases the core must tell apart
///   (`refreshTokenReused`, `refreshTokenInvalid`, `notSignedIn`, `service`), `AuthClientError` for
///   anything already mapped, and `CancellationError` when cancelled. The core maps anything else to
///   `AuthClientError.unknown`.
protocol SessionEngine: Sendable {

    // MARK: Pure: no network, no storage. Used by restore, state projection and adoption.

    /// Who and what a credentials payload holds.
    func describe(_ payload: Data) throws -> CredentialSummary

    /// The AWS credentials in a payload, or `nil` if it holds none.
    func awsCredentials(in payload: Data) throws -> CognitoAWSCredentials?

    /// The user pool access token in a payload, or `nil` if it holds none.
    func accessToken(in payload: Data) throws -> String?

    /// The user pool tokens in a payload, or `nil` if it holds none.
    func userPoolTokens(in payload: Data) throws -> AuthClientUserPoolTokens?

    /// Whether a payload's credentials are expired, or about to be, at `now`, by the engine's skew.
    func needsRefresh(_ payload: Data, at now: Date) throws -> Bool

    /// Whether a payload's user pool tokens, alone, are expired or about to be at `now`, by the same skew:
    /// what the core forces a refresh for, by its own clock (`false` for a payload with no tokens).
    func userPoolTokensNeedRefresh(_ payload: Data, at now: Date) throws -> Bool

    /// Whether signing a payload's user out presents the browser, to clear the hosted UI's cookie: only after a
    /// hosted-UI sign-in that shared the browser's cookies (`SignedInData.signOutPresentsBrowser`). What the core
    /// decides a sign-out's browser lease from. `false` for a payload with no
    /// user pool sign-in.
    func signOutPresentsBrowser(_ payload: Data) throws -> Bool

    // MARK: Network

    /// Starts a sign-in. A sign-in already pending on this engine is cancelled first: a new sign-in
    /// supersedes it. `current` is the session's guest payload, if it is a guest, so the signed-in
    /// credentials keep its identity; otherwise `nil`.
    ///
    /// Whether the session may sign in at all (it must not already be signed in) is the core's decision,
    /// not the engine's: the engine does not know the session's record.
    ///
    /// The core calls `signIn` and `confirmSignIn` from an unstructured task, so a caller's cancellation
    /// never reaches them: Cognito may already have issued tokens. Only `cancelPendingSignIn` stops one.
    ///
    /// **WebAuthn.** `request.webAuthn` is the call's window and
    /// sheet-lease runner. A WebAuthn step runs its ceremony through that runner, over that window, from the
    /// engine's ceremony site, and `cancelPendingSignIn` stops it through
    /// `EngineCeremonyContext.cancel`. With no window (the core refuses a WebAuthn first factor without one
    /// before calling, so this is Cognito starting a WebAuthn step on its own), the step throws
    /// `.validation(field: "presentationAnchor")`, presents nothing, and drops the attempt. A failed WebAuthn
    /// step always drops the attempt.
    ///
    /// - Returns: `.done` with the payload to commit, or `.challenge` with the step the sign-in now waits
    ///   on, which `pendingChallenge` then reports.
    /// - Throws: the mapped failure. A failed sign-in leaves nothing pending.
    ///
    /// `epoch` is the core's sign-in epoch for this attempt: `cancelPendingSignIn(before:)` ends only what
    /// began before the epoch it names.
    func signIn(_ request: EngineSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult

    /// Answers the pending sign-in's challenge.
    ///
    /// **Which failures keep the attempt** (ported from the plugin's
    /// `AWSAuthConfirmSignInTask.swift:95-190`). The attempt is kept, and `pendingChallenge` still reports its step, so the user can retry:
    /// - an answer the retained machine records as an error **inside** the challenge or the TOTP setup
    ///   (`resolvingChallenge(.error)`, `resolvingTOTPSetup(.error)`): a wrong code, an invalid new
    ///   password, a failed TOTP verification, whatever the mapped error;
    /// - an answer rejected before it is sent: `validation` (the core already checks an empty answer, and
    ///   an MFA or first-factor selection that names no type, with the plugin's strings).
    ///
    /// The plugin also retries a failed WebAuthn step (`signingInWithWebAuthn(.error)`). The client does not:
    /// a failed WebAuthn step drops the attempt, and the user signs in again.
    ///
    /// **WebAuthn.** A `"WEB_AUTHN"` answer to a first-factor selection runs its ceremony over
    /// `request.webAuthn`'s window, else over the window the sign-in was given, through this call's runner.
    /// With neither window it throws `.validation(field: "presentationAnchor")` before
    /// anything is sent, and keeps the attempt.
    ///
    /// The attempt is dropped, and `pendingChallenge` becomes `nil`:
    /// - `challengeExpired`, when Cognito's challenge session has expired;
    /// - an SRP or migrate-auth step that failed (`signingInWithSRP(.error)`,
    ///   `signingInViaMigrateAuth(.error)`): `invalidState("Cannot use confirmSignIn in the current state.
    ///   Call signIn to start the sign-in again.", …)` (the plugin's message, naming the client's calls);
    /// - any other retained state: `invalidState("There is no sign-in in progress for this session", …)`,
    ///   also thrown when nothing is pending;
    /// - `CancellationError`, once `cancelPendingSignIn` has run.
    ///
    /// If the retained machine has already reached signed in (the plugin's keychain-reconcile branch), the
    /// answer is not sent and the result is `.done` with the attempt's payload.
    ///
    /// `current` is the session's guest payload now, if it is a guest, else `nil`. The session may have
    /// become a guest while the sign-in waited on its challenge (`fetchAuthSession` on a signed-out
    /// session); the attempt then uses this payload in place of the one `signIn` was given, so the
    /// signed-in credentials keep the guest's identity ID (design §4.4).
    ///
    /// `epoch` is the core's sign-in epoch now. The engine answers only an attempt of that same epoch: an
    /// attempt from an earlier one belongs to a sign-in a sign-out has ended, so it is stopped and the call
    /// throws `invalidState("There is no sign-in in progress for this session", …)`.
    func confirmSignIn(_ request: EngineConfirmSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult

    /// Refreshes a payload's credentials and returns the refreshed payload.
    ///
    /// With `force`, the user pool tokens are refreshed whatever their expiry. The core forces it when the
    /// caller did, or when the tokens expire by the core's own clock (`userPoolTokensNeedRefresh`), so the
    /// choice uses the same clock as `needsRefresh`.
    /// Without, the engine refreshes only what is stale, as the plugin's unforced fetch does: AWS credentials
    /// alone when the user pool tokens are still valid, so a retry after an identity pool failure does not
    /// spend (and, with rotation, rotate) the refresh token again.
    ///
    /// - Throws: `SessionEngineError.refreshTokenReused` for Cognito's `RefreshTokenReuseException`, and
    ///   `SessionEngineError.refreshTokenInvalid` for an expired or revoked refresh token, never folded
    ///   into a generic error: the core treats them in opposite ways. When the refresh stored new
    ///   credentials before it failed, the failure arrives wrapped in `refreshedThenFailed(payload:error:)`.
    func refresh(_ payload: Data, force: Bool) async throws -> Data

    /// Fetches unauthenticated identity pool credentials.
    ///
    /// - Throws: `SessionEngineError.notSignedIn` when the identity pool does not allow guest access.
    func fetchGuestCredentials(current: Data?) async throws -> Data

    /// Revokes a payload's tokens, and with `global`, signs the user out of every device first.
    ///
    /// Never clears anything: the core clears the record. Server-side failures are **returned** in the
    /// outcome, because sign-out continues locally past them, as the plugin's does. A thrown error is a
    /// failure to run the sign-out at all; the core still clears locally, and reports it as the revoke
    /// failure.
    ///
    /// **After a failed global sign-out, `RevokeToken` is not called**, as in the plugin
    /// (`SignOutGlobally.invokeNextStep` → `.globalSignOutError`). The outcome then has
    /// `globalSignOutError` set to the real, mapped `GlobalSignOut` error, and `revokeError` **`nil`**:
    /// the plugin's placeholder revoke error (`BuildRevokeTokenError`'s `.service("", "", nil)`) never
    /// crosses the seam. The core reports that as `.partial` with only the global failure; the refresh
    /// token then stays valid until it expires, which the global failure already implies.
    ///
    /// **The hosted UI's sign-out.** With `.skip` no browser is shown,
    /// whatever the sign-in was. With `.present(anchor)`, after a sign-in that shared the browser's cookies,
    /// the logout page is shown in the anchor's window first, with the sign-in's own cookie jar:
    /// - the user closing it throws `AuthClientError.userCancelled`, with nothing revoked;
    /// - any other failure of the browser step (the window gone, a failed start, a bad redirect URI) reruns
    ///   the sign-out with `.skip` and returns that failure, mapped, as `hostedUIError`.
    /// `.present` for a sign-in that did not share cookies shows nothing, as `.skip`.
    func revoke(_ payload: Data, global: Bool, hostedUI: EngineHostedUISignOut) async throws -> EngineSignOutOutcome

    /// Deletes the signed-in user. Clears nothing: the core removes the session's record.
    ///
    /// - Throws: the mapped failure; `AuthClientError.service(.userNotFound, ...)` when the user no longer
    ///   exists, which the core answers with a global sign-out.
    func deleteUser(_ payload: Data) async throws

    /// Signs in through the hosted UI: a sign-in step, run as `signIn` runs
    /// one. It supersedes a pending sign-in, `current` is the guest payload to keep the identity of, and
    /// `epoch` is the core's sign-in epoch for this attempt. `cancelPendingSignIn(before:)` ends it, and so
    /// does cancelling the calling task; either dismisses the browser.
    ///
    /// The whole round trip runs here: the authorize URL, the browser in `request.anchor`'s window, the
    /// `state` check, the code exchange, and the identity checks of `request.identity` (the token claims are
    /// always verified). It returns `.done` with the payload to commit, and commits nothing itself.
    ///
    /// - Throws: `.validation(field: "presentationAnchor")` if the window has gone, before anything is shown;
    ///   `.configuration` without a hosted UI; `.userCancelled` when the user closes the browser;
    ///   `.unexpectedIdentity` for an unmet expectation; `.service` for a response that could not be verified
    ///   and for the engine's other hosted-UI failures; `CancellationError` once cancelled.
    func signInWithWebUI(_ request: EngineWebUISignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult

    // MARK: Multi-step state, in memory, and saved as the challenge record

    var pendingChallenge: AuthClientSignInStep? { get async }

    /// The pending attempt in its saved form, for the core to write as the session's challenge record; `nil` when
    /// nothing is pending, or the attempt waits in a state `confirmSignIn` does not answer or that cannot be saved
    /// (`confirmSignUp`, `resetPassword`). Never holds a password.
    var pendingChallengeState: ChallengeRecord.State? { get async }

    /// Makes a saved sign-in the pending attempt of `epoch`, as it was when the app was closed: what a restore does
    /// with the session's challenge record. `pendingChallenge` then reports the returned step, and `confirmSignIn`
    /// answers it as if the app had never closed. An expired challenge session fails that answer with
    /// `challengeExpired`, which drops the attempt, as it does for one that never closed.
    ///
    /// - Returns: The step, or `nil` if the record cannot be resumed (a spelling this build does not know, no user
    ///   pool), or an attempt or a step is already live, which is newer. Nothing is pending then that was not before.
    func resumeSignIn(from state: ChallengeRecord.State, epoch: UInt64) async -> AuthClientSignInStep?

    /// Drops the pending sign-in, and ends a `signIn` or `confirmSignIn` still in flight.
    /// It **must not wait for that step to finish**: it runs under the record gate, which the step's
    /// commit needs. The step in flight then either
    /// - **throws** `CancellationError` promptly, if it is still waiting on Cognito; or
    /// - **returns `.done`** with the tokens, if Cognito had already issued them when the cancel arrived.
    ///   The core refuses to commit a step that returns after a cancel, and revokes its tokens, so returning
    ///   them is what keeps a valid refresh token from being orphaned; dropping them would leak it.
    ///
    /// It never returns a `.challenge` after a cancel. It keeps the auto-sign-in session (see "Sign-up").
    ///
    /// The core calls it for this process's sign-outs, purges and deletions only. The core's refusal to
    /// commit after a cancel is per process too: see the ordering note in
    /// `SessionCore+SignIn.swift`.
    ///
    /// Only a step or attempt whose epoch is below `epoch` is ended: the core moves its epoch, then cancels,
    /// and a sign-in that began in between, with the new epoch, is left to run.
    func cancelPendingSignIn(before epoch: UInt64) async

    // MARK: Account operations
    //
    // Same error contract as the network methods above. The user-pool calls get no payload: they act on a
    // username, whether or not the session is signed in. The signed-in calls get the session's payload,
    // already restored and refreshed by the core through its single refresh flight. They **must use the
    // payload's access token as it is and never refresh**: a refresh here would bypass the core's flight
    // and commit guard, and could rotate a refresh token the record still holds. They never write the
    // session record, and must not disturb a pending sign-in. A rejected token surfaces as Cognito's mapped
    // answer (`notAuthorized`), never as `SessionEngineError.refreshTokenInvalid`, which only `refresh`
    // throws.

    // Sign-up
    //
    // **The sign-up state** is the plugin's one `SignUpState`, kept by the engine, so it is per session ID,
    // and in memory, so it lasts as long as the session core does (a handle must stay alive between
    // `confirmSignUp` and `autoSignIn`). As in the plugin:
    // - **every** sign-up and confirmation moves it, whatever its outcome: in progress when it starts, then
    //   waiting for confirmation (`.confirmUser`), signed up (`.done`, `.completeAutoSignIn`, a confirmation)
    //   or failed. So a later sign-up or confirmation replaces what an earlier one left, and `autoSignIn`
    //   never signs in an earlier user (`SignUpState+Resolver`; `AWSAuthAutoSignInTask` refuses any state but
    //   `signedUp`). Of concurrent ones, the one started last decides;
    // - the **auto-sign-in session** is a signed-up state with Cognito's session (`.completeAutoSignIn`). The
    //   plugin also runs `autoSignIn` from a signed-up state without one (a `.done` sign-up), and sends
    //   `USER_AUTH` with no session; the client refuses it with "Not in a signed up state…" instead;
    // - it **survives** a sign-in, a completed `autoSignIn`, a sign-out, a purge and `cancelPendingSignIn`,
    //   so a second `autoSignIn` reaches Cognito again, which answers `notAuthorized` for the spent session
    //   (AS-3);
    // - `confirmSignUp` sends the Cognito session of a sign-up waiting for confirmation (or of a failed
    //   confirmation) only when its username matches (`AWSAuthConfirmSignUpTask`); otherwise, and while
    //   another step is in progress, it confirms without one.

    func signUp(_ request: EngineSignUpRequest) async throws -> AuthClientSignUpResult

    func confirmSignUp(_ request: EngineConfirmSignUpRequest) async throws -> AuthClientSignUpResult

    func resendSignUpCode(username: String, clientMetadata: [String: String]) async throws -> AuthClientCodeDeliveryDetails

    /// Whether this engine's sign-up state is signed up with an auto-sign-in session. The core reads it
    /// **before** any other check on `autoSignIn`, as the plugin checks its sign-up state first
    /// (`AWSAuthAutoSignInTask.swift:71-92`): with none, `autoSignIn` throws "Not in a signed up state…"
    /// whether or not the session is signed in, and a pending sign-in is left as it is.
    var hasAutoSignInSession: Bool { get async }

    /// Signs in with the auto-sign-in session. A sign-in step like `signIn`: it supersedes a pending sign-in
    /// (the live engine's `beginSignIn(epoch:)` preamble, then `run(epoch:on:_:)`), `current` is the guest
    /// payload to keep the identity of, `epoch` is the core's sign-in epoch for this attempt, as for `signIn`,
    /// and the core commits `.done` under the same rules. Called only after `hasAutoSignInSession` answered
    /// `true` and the session was found not signed in. Keeps the auto-sign-in session whatever the outcome.
    ///
    /// - Throws: `invalidState` with the plugin's "Not in a signed up state…" strings if the auto-sign-in
    ///   session is gone by the time the engine reads it (a sign-up or confirmation started after the core's
    ///   check), having ended any pending sign-in from before `epoch`, which `confirmSignIn` at this epoch could
    ///   not answer; Cognito's mapped answer otherwise, `notAuthorized` for a spent session.
    func autoSignIn(current: Data?, epoch: UInt64) async throws -> EngineStepResult

    // Password reset

    func resetPassword(username: String, clientMetadata: [String: String]) async throws -> AuthClientResetPasswordResult

    func confirmResetPassword(_ request: EngineConfirmResetPasswordRequest) async throws

    // Attributes and password change

    func fetchUserAttributes(_ payload: Data) async throws -> [AuthClientUserAttribute]

    func updateUserAttributes(
        _ payload: Data,
        attributes: [AuthClientUserAttribute],
        clientMetadata: [String: String]
    ) async throws -> [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult]

    func sendVerificationCode(
        _ payload: Data,
        attributeKey: AuthClientUserAttributeKey,
        clientMetadata: [String: String]
    ) async throws -> AuthClientCodeDeliveryDetails

    func confirmUserAttribute(_ payload: Data, attributeKey: AuthClientUserAttributeKey, confirmationCode: String) async throws

    func changePassword(_ payload: Data, oldPassword: String, newPassword: String) async throws

    // MFA

    func setUpTOTP(_ payload: Data) async throws -> AuthClientTOTPSetupDetails

    func verifyTOTPSetup(_ payload: Data, code: String, friendlyDeviceName: String?) async throws

    func fetchMFAPreference(_ payload: Data) async throws -> AuthClientUserMFAPreference

    func updateMFAPreference(
        _ payload: Data,
        sms: AuthClientMFAPreference?,
        totp: AuthClientMFAPreference?,
        email: AuthClientMFAPreference?
    ) async throws

    // Devices. The per-user device records stay the engine's.

    func fetchDevices(_ payload: Data) async throws -> [AuthClientDevice]

    func rememberDevice(_ payload: Data) async throws

    /// - Parameter deviceId: The device to forget; `nil` for this device.
    func forgetDevice(_ payload: Data, deviceId: String?) async throws

    // Federation

    /// Exchanges a provider token for identity pool credentials, and returns the federated payload for the
    /// core to commit. `current` is the session's payload, if any. Clearing a federation needs no engine
    /// call: the core clears the record.
    func federateToIdentityPool(_ request: EngineFederationRequest, current: Data?) async throws -> Data

    // WebAuthn

    /// Registers a passkey for the signed-in user. The ceremony runs through `context.ceremony`, so the
    /// sheet lease is held around it.
    func associateWebAuthnCredential(_ payload: Data, context: EngineCeremonyContext) async throws

    func listWebAuthnCredentials(_ payload: Data, pageSize: Int, nextToken: String?) async throws -> EngineWebAuthnCredentialPage

    func deleteWebAuthnCredential(_ payload: Data, credentialId: String) async throws
}

extension SessionEngine {

    // The pure reads, with any engine error wrapped per the error contract.

    func checkedDescribe(_ payload: Data) throws -> CredentialSummary {
        try Self.checked("the saved credentials") { try describe(payload) }
    }

    func checkedAWSCredentials(in payload: Data) throws -> CognitoAWSCredentials? {
        try Self.checked("the AWS credentials") { try awsCredentials(in: payload) }
    }

    func checkedAccessToken(in payload: Data) throws -> String? {
        try Self.checked("the access token") { try accessToken(in: payload) }
    }

    func checkedUserPoolTokens(in payload: Data) throws -> AuthClientUserPoolTokens? {
        try Self.checked("the user pool tokens") { try userPoolTokens(in: payload) }
    }

    func checkedNeedsRefresh(_ payload: Data, at now: Date) throws -> Bool {
        try Self.checked("the credentials' expiry") { try needsRefresh(payload, at: now) }
    }

    func checkedUserPoolTokensNeedRefresh(_ payload: Data, at now: Date) throws -> Bool {
        try Self.checked("the user pool tokens' expiry") { try userPoolTokensNeedRefresh(payload, at: now) }
    }

    func checkedSignOutPresentsBrowser(_ payload: Data) throws -> Bool {
        try Self.checked("the hosted UI sign-in") { try signOutPresentsBrowser(payload) }
    }

    /// The sign-out of every caller without a window: no browser (`.skip`).
    func revoke(_ payload: Data, global: Bool) async throws -> EngineSignOutOutcome {
        try await revoke(payload, global: global, hostedUI: .skip)
    }

    private static func checked<T>(_ what: String, _ body: () throws -> T) throws -> T {
        do {
            return try body()
        } catch let error as AuthClientError {
            throw error
        } catch let error as CredentialsError {
            throw error
        } catch {
            throw AuthClientError.unknown(
                "This session's saved credentials could not be read (\(what)).",
                "Sign the session out and sign in again.",
                error
            )
        }
    }
}

/// What a credentials payload holds, read without the network.
struct CredentialSummary: Sendable, Equatable {
    let kind: SessionKind
    let username: String?
    let userId: String?
    /// The identity pool identity, for payloads that have one. What tells two user-less (guest or
    /// federated) payloads apart.
    var identityId: String?

    /// The signed-in user, when the payload names one completely.
    var user: AuthClientUser? {
        guard let username, let userId else {
            return nil
        }
        return AuthClientUser(username: username, userId: userId)
    }

    /// Whether `other` is provably the same principal: the same user by `sub` when both know it, else by
    /// username, else the same identity pool identity. Anything else — including two payloads with no
    /// user and no identity to compare, which may be two different guests — is **not** the same.
    ///
    /// Used to tell a refresh by another writer (the same principal, new tokens) apart from a different
    /// principal signing in to the same session ID, which a sign-out must never erase. When in doubt it
    /// answers no, which leaves the other session signed in and reports it: the safe direction.
    func isSamePrincipal(as other: CredentialSummary) -> Bool {
        if let userId, let otherUserId = other.userId {
            return userId == otherUserId
        }
        if let username, let otherUsername = other.username {
            return username == otherUsername
        }
        if let identityId, let otherIdentityId = other.identityId {
            return identityId == otherIdentityId
        }
        return false
    }
}

/// The result of one sign-in step.
enum EngineStepResult: Sendable, Equatable {
    /// Sign-in completed; the core commits this payload.
    case done(payload: Data)
    /// Sign-in waits on the user.
    case challenge(AuthClientSignInStep)
}

/// A sign-in request, as the engine receives it.
struct EngineSignInRequest: Sendable, Equatable {
    let username: String
    /// `nil` for a passwordless `userAuth` first factor.
    let password: String?
    /// `nil` uses the configuration's flow (`userSRP`).
    let authFlowType: AuthClientAuthFlowType?
    let clientMetadata: [String: String]
    /// The window and sheet-lease runner for a WebAuthn step, from the anchored `signIn` overload; `nil` from
    /// the anchor-less one, where a WebAuthn step is refused without presenting.
    var webAuthn: EngineCeremonyContext?
}

/// A challenge response, as the engine receives it.
struct EngineConfirmSignInRequest: Sendable, Equatable {
    let challengeResponse: String
    /// Cognito attribute names (`email`, `custom:team`, ...), mapped from `AuthClientUserAttributeKey`.
    /// Unprefixed: the engine adds the `userAttributes.` prefix `RespondToAuthChallenge` expects, as the
    /// plugin's confirm task does.
    let userAttributes: [String: String]
    let clientMetadata: [String: String]
    /// The device name for a TOTP setup.
    let friendlyDeviceName: String?
    /// This call's sheet-lease runner, and its window (`nil` from the anchor-less overload: a `"WEB_AUTHN"`
    /// answer then uses the sign-in's). The core sets it on every confirmation, on the platforms with a
    /// passkey sheet, so a ceremony always runs under this call's runner and cancellation.
    var webAuthn: EngineCeremonyContext?
}

/// What a sign-out achieved server-side. Sign-out continues locally past both failures.
struct EngineSignOutOutcome: Sendable, Equatable {
    /// Revoking the refresh token failed. `nil` when it succeeded, and when it was not attempted because
    /// the global sign-out failed first: never a placeholder error.
    var revokeError: AuthClientError?
    /// The global sign-out failed: the real error. Only ever set when a global sign-out was asked for.
    var globalSignOutError: AuthClientError?
    /// The hosted UI's sign-out did not run, so its cookie survives in the browser:
    /// the lease was busy, there was no window or no hosted UI configuration, or the browser failed.
    /// A device-side failure, reported beside the server-side ones.
    var hostedUIError: AuthClientError?

    static let complete = EngineSignOutOutcome()

    var isComplete: Bool {
        revokeError == nil && globalSignOutError == nil && hostedUIError == nil
    }

    /// Keeps the first failure of each kind across attempts.
    mutating func merge(_ other: EngineSignOutOutcome) {
        revokeError = revokeError ?? other.revokeError
        globalSignOutError = globalSignOutError ?? other.globalSignOutError
        hostedUIError = hostedUIError ?? other.hostedUIError
    }

    /// The public partial result, or `nil` if nothing failed.
    var partial: AuthClientPartialSignOut? {
        isComplete ? nil : publicForm
    }

    /// The first failure of any kind: what a sign-out that could not finish carries as its underlying error.
    var firstError: AuthClientError? {
        revokeError ?? globalSignOutError ?? hostedUIError
    }

    private var publicForm: AuthClientPartialSignOut {
        AuthClientPartialSignOut(revokeError: revokeError, globalSignOutError: globalSignOutError, hostedUIError: hostedUIError)
    }

    /// Errors compare as `AuthClientPartialSignOut` compares them.
    static func == (lhs: EngineSignOutOutcome, rhs: EngineSignOutOutcome) -> Bool {
        lhs.publicForm == rhs.publicForm
    }
}

/// Engine failures the core must tell apart. Everything else arrives already mapped to
/// `AuthClientError`.
enum SessionEngineError: Error, Sendable {
    /// `RefreshTokenReuseException`: another writer already used this refresh token. Re-read storage;
    /// never signed out.
    case refreshTokenReused
    /// The refresh token expired or was revoked: the session needs a fresh sign-in.
    case refreshTokenInvalid
    case notSignedIn
    case service(AuthClientError)
    /// The refresh stored new credentials, then failed: with refresh-token rotation, the user pool refresh
    /// retired the old refresh token before the identity pool step failed. The core commits `payload`, under
    /// the same guard as a successful refresh, then fails with `error`, so the next refresh uses the new
    /// token instead of the retired one.
    indirect case refreshedThenFailed(payload: Data, error: SessionEngineError)
}

/// What an engine is built with.
struct SessionEngineContext: Sendable {
    let sessionId: SessionID
    let configuration: AuthClientConfiguration
    /// The engine keeps device and advanced-security records at the plugin's per-user keys.
    let namespace: SessionStorageNamespace
    /// The same SDK clients the escape hatches return.
    let clients: CognitoServiceClients
}

/// Revokes a stored session's tokens when no live session core holds it. Stateless, and never global.
/// Reports server-side failures as the engine's `revoke` does. It has no window, so it never shows the hosted
/// UI's sign-out.
protocol SessionRevoker: Sendable {
    func revoke(_ payload: Data) async throws -> EngineSignOutOutcome

    /// The engine's `signOutPresentsBrowser`: whether a sign-out given a window would have shown the browser.
    func signOutPresentsBrowser(_ payload: Data) -> Bool
}
