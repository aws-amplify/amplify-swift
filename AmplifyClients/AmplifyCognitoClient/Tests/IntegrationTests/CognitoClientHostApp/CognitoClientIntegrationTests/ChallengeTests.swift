//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Sign-in challenges over the live engine: dave's new-password challenge (P-3), and
/// TOTP MFA for fresh users enrolled per test (instead of carol, P-2, whose codes concurrent runs would
/// share). The pending challenge lives in memory, per session.
final class ChallengeTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
    }

    /// A user created by an administrator sets a new password to finish signing in (CH-1;
    /// the plugin's `testNewPasswordRequired`, which runs when its credentials file lists FORCE_CHANGE_PASSWORD
    /// users).
    ///
    /// The user is the first of the default credentials file's `new_password_required_usernames` still in
    /// `FORCE_CHANGE_PASSWORD`, as the plugin's test takes it: each is used once, and another run against the
    /// same backend (the plugin's suite, or this one) may take one at any time.
    /// - A candidate whose temporary password is refused (`.notAuthorized`) is skipped if Cognito no longer
    ///   holds it in `FORCE_CHANGE_PASSWORD` (used up); if it still does, the temporary password is wrong and
    ///   the test fails saying so.
    /// - A candidate whose new password is refused (`.notAuthorized`, or `.challengeExpired`: Cognito's
    ///   "Invalid session for the user") is skipped only if it then refuses the temporary password too:
    ///   another run finished its challenge first. Otherwise the error is rethrown.
    /// - The test fails when none is left. Each attempt has its own state-stream subscription, so an earlier
    ///   attempt's states cannot satisfy a later one's wait.
    /// As the plugin's test does, the confirmation also sets an email, which a backend whose new-password
    /// challenge requires it needs and any other accepts.
    ///
    /// - Given: the new-password users and their temporary password, from the credentials file
    /// - When:
    ///    - the first one still in `FORCE_CHANGE_PASSWORD` signs in with the temporary password
    ///    - and confirms with a new password of this run's
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithNewPassword`, the state is `.awaitingChallenge` with
    ///      that step, and the state stream published it
    ///    - the confirmation returns `.done`, and the state is `.signedIn` as that user
    ///
    func testNewPasswordRequiredChallenge() async throws {
        let (candidates, temporary) = try IntegrationTestEnvironment.credentials().requireNewPasswordUsers()
        let raw = try SandboxPools.pool(.standard)
        let sessionId = try makeSessionID("new-password")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))

        for username in candidates {
            let states = StreamRecorder(client.listenToSessionStateChanges())
            let result: AuthClientSignInResult
            do {
                result = try await client.signIn(username: username, password: temporary.value)
            } catch let error as AuthClientError where error.kind == .notAuthorized {
                guard await !PerRunUsers.stillAwaitsANewPassword(username, on: raw) else {
                    return XCTFail(PerRunUsers.wrongTemporaryPassword)
                }
                // Used up, by an earlier run or by one running now.
                continue
            }

            XCTAssertTrue(result.nextStep.isNewPassword, result.nextStep.caseName)
            guard result.nextStep.isNewPassword else {
                return
            }
            let pending = await client.currentSessionState()
            XCTAssertTrue(pending.pendingStep?.isNewPassword == true, pending.redactedDescription)
            try await states.waitUntil("the state stream to publish the new-password step") {
                $0.contains { $0.pendingStep?.isNewPassword == true }
            }

            let newPassword = SandboxSignUp.freshPassword()
            PerRunUsers.newPasswordAttempt = TestUser(username: username, password: newPassword)
            let confirmed: AuthClientSignInResult
            do {
                confirmed = try await client.confirmSignIn(
                    challengeResponse: newPassword,
                    options: .init(userAttributes: [AuthClientUserAttribute(.email, value: "\(username)@\(SandboxSignUp.emailDomain)")])
                )
            } catch let error as AuthClientError where [.notAuthorized, .challengeExpired].contains(error.kind) {
                // Possibly another run set this user's password between the sign-in and the answer: only if
                // the user now refuses the temporary password.
                guard try await PerRunUsers.refusesTemporaryPassword(username, temporary, on: raw) else {
                    throw error
                }
                continue
            }

            XCTAssertStep(confirmed.nextStep, .done)
            let user = try await client.getCurrentUser()
            XCTAssertTrue(user.username.lowercased() == username.lowercased(), "signed in as another user")
            let signedIn = await client.currentSessionState()
            XCTAssertState(signedIn, .signedIn(user))
            return
        }
        XCTFail("""
        None of the \(candidates.count) new-password users in \(IntegrationTestEnvironment.credentialsResource).json \
        is still in FORCE_CHANGE_PASSWORD: each is used once, so the backend must reset them (or list new ones) \
        before the next run.
        """)
    }

    /// A TOTP-enrolled user answers the MFA challenge with a code (CH-2).
    ///
    /// - Given: a fresh user, TOTP enrolled and preferred, on a pool with optional MFA
    /// - When:
    ///    - the user signs in with the password
    ///    - and confirms with a fresh code from the secret
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithTOTPCode`, and the state waits on that step
    ///    - the confirmation returns `.done`, and the state is `.signedIn(user)`
    ///
    func testTOTPMFAChallenge() async throws {
        let totpUser = try await makeTOTPUser()
        let client = try makeClient("totp", pool: Self.pool)

        let result = try await client.signIn(username: totpUser.username, password: totpUser.password)

        XCTAssertStep(result.nextStep, .confirmSignInWithTOTPCode)
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let code = try await TOTP.freshCode(secret: totpUser.secret)
        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertTrue(user.username == totpUser.username, "signed in as another user")
        let signedIn = await client.currentSessionState()
        XCTAssertState(signedIn, .signedIn(user))
    }

    /// A pending challenge belongs to its session: another session signing in does not disturb it
    /// (CH-3).
    ///
    /// - Given: a fresh TOTP user waiting on the TOTP challenge on session A, and a second fresh user
    ///   without MFA on the same pool, so both sessions share one configuration and one namespace
    /// - When:
    ///    - the second user signs in on session B, and completes
    ///    - then A confirms with a fresh code
    /// - Then:
    ///    - B is signed in as the second user while A still waits on `.confirmSignInWithTOTPCode`
    ///    - A's confirmation returns `.done`, and A is signed in as the TOTP user; B is unchanged
    ///
    func testPendingChallengeIsPerSession() async throws {
        let totpUser = try await makeTOTPUser()
        let other = try await makeFreshUser(on: Self.pool).testUser
        let totpClient = try makeClient("totp", pool: Self.pool)
        let otherClient = try makeClient("other", pool: Self.pool)
        let challenge = try await totpClient.signIn(username: totpUser.username, password: totpUser.password)
        XCTAssertStep(challenge.nextStep, .confirmSignInWithTOTPCode)

        let otherResult = try await otherClient.signIn(username: other.username, password: other.password)

        XCTAssertStep(otherResult.nextStep, .done)
        let otherUser = try await otherClient.getCurrentUser()
        XCTAssertTrue(otherUser.username == other.username, "B signed in as another user")
        let otherState = await otherClient.currentSessionState()
        XCTAssertState(otherState, .signedIn(otherUser))
        let stillPending = await totpClient.currentSessionState()
        XCTAssertState(stillPending, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let code = try await TOTP.freshCode(secret: totpUser.secret)
        let confirmed = try await totpClient.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        let signedInUser = try await totpClient.getCurrentUser()
        XCTAssertTrue(signedInUser.username == totpUser.username, "signed in as another user")
        let totpState = await totpClient.currentSessionState()
        XCTAssertState(totpState, .signedIn(signedInUser))
        let otherAfter = await otherClient.currentSessionState()
        XCTAssertState(otherAfter, .signedIn(otherUser))
    }

    /// A new sign-in on a session waiting on a challenge supersedes the challenge (CH-4).
    ///
    /// - Given: a fresh TOTP user waiting on the TOTP challenge on session A, the recorder installed, and
    ///   a second fresh user without MFA on the same pool
    /// - When:
    ///    - the second user signs in on A
    ///    - then A is asked to confirm the first user's challenge
    /// - Then:
    ///    - the second sign-in returns `.done`, and A is signed in as the second user
    ///    - the confirmation throws `.invalidState` without a request to Cognito, and A is unchanged
    ///
    func testNewSignInSupersedesThePendingChallenge() async throws {
        let totpUser = try await makeTOTPUser()
        let other = try await makeFreshUser(on: Self.pool).testUser
        let recorder = RecordingHTTPClient()
        let client = try makeClient("supersede", pool: Self.pool, configureUserPoolClient: recorder.configureUserPoolClient)
        let challenge = try await client.signIn(username: totpUser.username, password: totpUser.password)
        XCTAssertStep(challenge.nextStep, .confirmSignInWithTOTPCode)

        let result = try await client.signIn(username: other.username, password: other.password)

        XCTAssertStep(result.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertTrue(user.username == other.username, "signed in as another user")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
        recorder.reset()
        // Any six digits: the confirmation must be refused before it reaches Cognito.
        let error = await Expect.authClientError("confirming a superseded challenge") {
            try await client.confirmSignIn(challengeResponse: "000000")
        }
        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(recorder.operations, [], "the refusal sends nothing")
        let after = await client.currentSessionState()
        XCTAssertState(after, .signedIn(user))
    }

    /// A wrong TOTP code fails but keeps the challenge, so the user can retry (CH-5).
    ///
    /// - Given: a fresh TOTP user waiting on the TOTP challenge
    /// - When:
    ///    - the user confirms with a code no nearby step produces
    ///    - then with a fresh, right code
    /// - Then:
    ///    - the wrong code throws `.service(.codeMismatch)`, and the state still waits on
    ///      `.confirmSignInWithTOTPCode`
    ///    - the right code returns `.done`, and the state is `.signedIn(user)`
    ///
    func testWrongTOTPCodeKeepsTheChallenge() async throws {
        let totpUser = try await makeTOTPUser()
        let client = try makeClient("totp", pool: Self.pool)
        let challenge = try await client.signIn(username: totpUser.username, password: totpUser.password)
        XCTAssertStep(challenge.nextStep, .confirmSignInWithTOTPCode)

        let wrongCode = try TOTP.wrongCode(secret: totpUser.secret)
        let error = await Expect.authClientError("confirming a wrong code") {
            try await client.confirmSignIn(challengeResponse: wrongCode)
        }

        XCTAssertEqual(error?.kind, .service(.codeMismatch), "\(String(describing: error?.kind))")
        let stillPending = await client.currentSessionState()
        XCTAssertState(stillPending, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let code = try await TOTP.freshCode(secret: totpUser.secret)
        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertTrue(user.username == totpUser.username, "signed in as another user")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
    }

    /// An answer after Cognito's challenge session has expired reports `challengeExpired`
    /// (CH-6). Deliberately slow: it waits out the app client's 3-minute challenge-session
    /// validity.
    ///
    /// - Given: a fresh TOTP user waiting on the TOTP challenge
    /// - When:
    ///    - more than 3 minutes pass
    ///    - the user confirms with a fresh, right code
    /// - Then:
    ///    - the confirmation throws `AuthClientError.challengeExpired`
    ///    - the state no longer waits on the challenge: it is `.signedOut`, and a retry of the
    ///      confirmation is refused with `.invalidState`
    ///
    func testExpiredChallengeReportsChallengeExpired() async throws {
        let totpUser = try await makeTOTPUser()
        let client = try makeClient("totp", pool: Self.pool)
        let challenge = try await client.signIn(username: totpUser.username, password: totpUser.password)
        XCTAssertStep(challenge.nextStep, .confirmSignInWithTOTPCode)

        // Past the app client's default challenge-session validity (3 minutes). A precondition, not an
        // assertion on timing.
        try await Task.sleep(nanoseconds: 190 * 1_000_000_000)
        let code = try await TOTP.freshCode(secret: totpUser.secret)
        let error = await Expect.authClientError("confirming an expired challenge") {
            try await client.confirmSignIn(challengeResponse: code)
        }

        XCTAssertEqual(error?.kind, .challengeExpired, "\(String(describing: error?.kind))")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
        let retry = await Expect.authClientError("confirming after the challenge was dropped") {
            try await client.confirmSignIn(challengeResponse: code)
        }
        XCTAssertEqual(retry?.kind, .invalidState)
    }

    // MARK: - Fresh TOTP users

    /// The pool the TOTP rows use: U-DEF, the plugin's default backend (self sign-up, MFA optional with
    /// TOTP, devices tracked and always remembered, so the client also confirms a device on sign-in).
    private static let pool = SandboxPool.standard

    /// A fresh user with TOTP enrolled and preferred, and its secret.
    ///
    /// Signed up for the test and deleted at teardown, instead of the shared carol: two runs at once would
    /// otherwise answer carol's challenge with codes from the same 30-second step, and Cognito accepts each
    /// step's code only once.
    private func makeTOTPUser() async throws -> (username: String, password: String, secret: TOTPSecret) {
        let user = try await makeFreshUser(on: Self.pool)
        let pool = try SandboxPools.pool(Self.pool)
        let tokens = try await pool.signIn(user)
        let secret = try await pool.enrollTOTP(user, accessToken: XCTUnwrap(tokens.accessToken))
        return (user.username, user.password ?? "", secret)
    }
}
