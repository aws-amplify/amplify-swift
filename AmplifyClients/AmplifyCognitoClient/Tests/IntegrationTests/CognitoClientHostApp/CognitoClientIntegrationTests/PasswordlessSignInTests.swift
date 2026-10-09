//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AuthenticationServices
import XCTest

/// Choice-based sign-in (`USER_AUTH`) through the client (PL-1 … PL-23):
/// the plugin's `PasswordlessTests/PasswordlessSignInTests`, one test per plugin method, with the
/// plugin's method names.
///
/// U-PL (`SandboxPool.passwordless`) allows the first factors `PASSWORD`, `EMAIL_OTP` and `SMS_OTP`
/// (with `PASSWORD_SRP`, which Cognito offers alongside `PASSWORD`), and hands every code to the code
/// sink (P-5c) through its custom senders, so nothing is delivered. Each test signs up its own user with a
/// password, an `@example.com` email and a fictional `+1 555` number, all verified by the pre-sign-up
/// trigger; the plugin confirms its sign-up with a code instead, which this pool's trigger makes
/// unnecessary.
///
/// PL-11 (`testSignInWithUnsupportedPreference_givenValidUser_expectSelectChallenge`, a WebAuthn
/// preference) goes through the anchored `signIn` overload: the
/// anchor-less one refuses a WebAuthn first factor before anything is sent. U-PL offers no `WEB_AUTHN`, so
/// Cognito answers with the selection and no passkey sheet is involved.
///
/// Request checks read `RecordingHTTPClient.answered`, so an attempt the SDK sent again after a lost
/// connection is counted once. No code, password, username or sub is printed: codes and users are
/// compared with booleans, and steps and states print their case names only.
final class PasswordlessSignInTests: ClientIntegrationTestCase {

    private static let pool = SandboxPool.passwordless

    private var sink: CodeSink!

    override func setUp() async throws {
        try await super.setUp()
        sink = try CodeSink()
    }

    // MARK: - Preferred password factors

    /// Preferred `PASSWORD` signs in at once (PL-1).
    ///
    /// - Given: a fresh user with a password, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .password)` and the password
    /// - Then:
    ///    - the sign-in returns `.done`, and the session is signed in as the user
    ///    - it sent one `InitiateAuth` `USER_AUTH` preferring `PASSWORD`, and answered no challenge
    ///
    func testSignInWithPasswordAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-1")

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(.password))

        XCTAssertStep(result.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertInitiated(recorder, preferring: "PASSWORD")
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), [])
    }

    /// Preferred `PASSWORD_SRP` signs in after the SRP exchange (PL-2).
    ///
    /// - Given: a fresh user with a password, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .passwordSRP)` and the password
    /// - Then:
    ///    - the sign-in returns `.done`, and the session is signed in as the user
    ///    - it sent `InitiateAuth` `USER_AUTH` preferring `PASSWORD_SRP`, then answered `PASSWORD_VERIFIER`
    ///
    func testSignInWithPasswordSRPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-2")

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(.passwordSRP))

        XCTAssertStep(result.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertInitiated(recorder, preferring: "PASSWORD_SRP")
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["PASSWORD_VERIFIER"])
    }

    // MARK: - Selecting a password factor

    /// With no preference, selecting `PASSWORD_SRP` then the password signs in (PL-3).
    ///
    /// - Given: a fresh user with a password, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: nil)` and the password
    ///    - selects `AuthClientFactorType.passwordSRP.challengeResponse`
    ///    - and confirms with the password
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection` offering `.passwordSRP`, after an
    ///      `InitiateAuth` `USER_AUTH` with no preference
    ///    - the selection returns `.confirmSignInWithPassword`
    ///    - the password returns `.done`: the `SELECT_CHALLENGE` answer chose `PASSWORD_SRP`, the SRP
    ///      exchange followed, and the session is signed in as the user
    ///
    func testSignInWithPasswordSRP_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-3")

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))

        let factors = try firstFactors(of: result.nextStep)
        XCTAssertTrue(factors.contains(.passwordSRP), "passwordSRP should be offered")
        assertInitiated(recorder, preferring: nil)

        let selected = try await client.confirmSignIn(challengeResponse: AuthClientFactorType.passwordSRP.challengeResponse)
        XCTAssertStep(selected.nextStep, .confirmSignInWithPassword)

        let confirmed = try await client.confirmSignIn(challengeResponse: password)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertSelected(recorder, "PASSWORD_SRP", answering: ["SELECT_CHALLENGE", "PASSWORD_VERIFIER"])
    }

    /// In `USER_AUTH`, a wrong password ends the attempt: a retry needs a new sign-in (PL-4).
    ///
    /// - Given: a fresh user, signed in with no preference, `PASSWORD_SRP` selected, and waiting on
    ///   `.confirmSignInWithPassword`; the recorder installed
    /// - When:
    ///    - the user confirms with a wrong password
    ///    - then confirms with the right password
    ///    - then signs in again, selects `PASSWORD_SRP` and confirms with the right password
    /// - Then:
    ///    - the wrong password throws `.notAuthorized`, and the session is signed out with nothing pending
    ///    - the retry throws `.invalidState` and sends no request: Cognito's challenge cannot be answered
    ///      again, as the plugin reports
    ///    - the new sign-in returns `.done`, and the session is signed in as the user
    ///
    func testSignInWithPasswordSRP_givenValidUser_expectErrorOnWrongPassword() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-4")
        let first = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))
        XCTAssertTrue(try firstFactors(of: first.nextStep).contains(.passwordSRP), "passwordSRP should be offered")
        let selected = try await client.confirmSignIn(challengeResponse: AuthClientFactorType.passwordSRP.challengeResponse)
        XCTAssertStep(selected.nextStep, .confirmSignInWithPassword)

        let wrong = await Expect.authClientError("confirming a wrong password") {
            try await client.confirmSignIn(challengeResponse: SandboxSignUp.freshPassword())
        }
        XCTAssertEqual(wrong?.kind, .notAuthorized, "\(String(describing: wrong?.kind))")
        let afterWrong = await client.currentSessionState()
        XCTAssertState(afterWrong, .signedOut)

        recorder.reset()
        let retry = await Expect.authClientError("confirming again after a wrong password") {
            try await client.confirmSignIn(challengeResponse: password)
        }
        XCTAssertEqual(retry?.kind, .invalidState, "\(String(describing: retry?.kind))")
        XCTAssertEqual(recorder.operations, [], "the refused retry should send nothing")

        let again = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))
        XCTAssertTrue(try firstFactors(of: again.nextStep).contains(.passwordSRP), "passwordSRP should be offered")
        let reselected = try await client.confirmSignIn(challengeResponse: AuthClientFactorType.passwordSRP.challengeResponse)
        XCTAssertStep(reselected.nextStep, .confirmSignInWithPassword)
        let confirmed = try await client.confirmSignIn(challengeResponse: password)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
    }

    /// With no preference, selecting `PASSWORD` then the password signs in (PL-5).
    ///
    /// - Given: a fresh user with a password, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: nil)` and the password
    ///    - selects `AuthClientFactorType.password.challengeResponse`
    ///    - and confirms with the password
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection` offering `.password`
    ///    - the selection returns `.confirmSignInWithPassword`
    ///    - the password returns `.done`: the `SELECT_CHALLENGE` answer chose `PASSWORD`, with no SRP
    ///      exchange, and the session is signed in as the user
    ///
    func testSignInWithPassword_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-5")

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))

        XCTAssertTrue(try firstFactors(of: result.nextStep).contains(.password), "password should be offered")
        let selected = try await client.confirmSignIn(challengeResponse: AuthClientFactorType.password.challengeResponse)
        XCTAssertStep(selected.nextStep, .confirmSignInWithPassword)

        let confirmed = try await client.confirmSignIn(challengeResponse: password)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertSelected(recorder, "PASSWORD", answering: ["SELECT_CHALLENGE"])
        XCTAssertFalse(recorder.answered.contains { $0.challengeName == "PASSWORD_VERIFIER" }, "no SRP exchange")
    }

    // MARK: - Preferred one-time codes

    /// Preferred `EMAIL_OTP` asks for the emailed code, which signs in (PL-6).
    ///
    /// - Given: a fresh user with a verified email, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .emailOTP)` and no password
    ///    - and confirms with the code the sink captured
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP` with an email destination, after an `InitiateAuth`
    ///      `USER_AUTH` preferring `EMAIL_OTP`
    ///    - the code returns `.done`, answering `EMAIL_OTP`, and the session is signed in as the user
    ///
    func testSignInWithEmailOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-6")

        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.emailOTP))
        }

        assertOTPStep(result.nextStep, .email)
        assertInitiated(recorder, preferring: "EMAIL_OTP")

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["EMAIL_OTP"])
    }

    /// Preferred `SMS_OTP` asks for the texted code, which signs in (PL-7).
    ///
    /// - Given: a fresh user with a verified phone number, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .smsOTP)` and no password
    ///    - and confirms with the code the sink captured
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP` with an SMS destination, after an `InitiateAuth`
    ///      `USER_AUTH` preferring `SMS_OTP`
    ///    - the code returns `.done`, answering `SMS_OTP`, and the session is signed in as the user
    ///
    func testSignInWithSMSOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-7")

        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.smsOTP))
        }

        assertOTPStep(result.nextStep, .sms)
        assertInitiated(recorder, preferring: "SMS_OTP")

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["SMS_OTP"])
    }

    // MARK: - Selecting a one-time code

    /// With no preference, selecting `EMAIL_OTP` asks for the emailed code, which signs in
    /// (PL-8).
    ///
    /// - Given: a fresh user with a password and a verified email, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: nil)` and the password
    ///    - selects `AuthClientFactorType.emailOTP.challengeResponse`
    ///    - and confirms with the code the sink captured
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection` offering `.emailOTP`
    ///    - the selection returns `.confirmSignInWithOTP` with an email destination
    ///    - the code returns `.done`: the `SELECT_CHALLENGE` answer chose `EMAIL_OTP`, then the code
    ///      answered `EMAIL_OTP`, and the session is signed in as the user
    ///
    func testSignInWithoutEmailOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-8")
        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))
        XCTAssertTrue(try firstFactors(of: result.nextStep).contains(.emailOTP), "emailOTP should be offered")

        let (selected, code) = try await sink.code(for: user, .otp) {
            try await client.confirmSignIn(challengeResponse: AuthClientFactorType.emailOTP.challengeResponse)
        }
        assertOTPStep(selected.nextStep, .email)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertSelected(recorder, "EMAIL_OTP", answering: ["SELECT_CHALLENGE", "EMAIL_OTP"])
    }

    /// With no preference, selecting `SMS_OTP` asks for the texted code, which signs in
    /// (PL-9).
    ///
    /// - Given: a fresh user with a password and a verified phone number, and the recorder installed
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: nil)` and the password
    ///    - selects `AuthClientFactorType.smsOTP.challengeResponse`
    ///    - and confirms with the code the sink captured
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection` offering `.smsOTP`
    ///    - the selection returns `.confirmSignInWithOTP` with an SMS destination
    ///    - the code returns `.done`: the `SELECT_CHALLENGE` answer chose `SMS_OTP`, then the code
    ///      answered `SMS_OTP`, and the session is signed in as the user
    ///
    func testSignInWithoutSMSOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-9")
        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))
        XCTAssertTrue(try firstFactors(of: result.nextStep).contains(.smsOTP), "smsOTP should be offered")

        let (selected, code) = try await sink.code(for: user, .otp) {
            try await client.confirmSignIn(challengeResponse: AuthClientFactorType.smsOTP.challengeResponse)
        }
        assertOTPStep(selected.nextStep, .sms)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        assertSelected(recorder, "SMS_OTP", answering: ["SELECT_CHALLENGE", "SMS_OTP"])
    }

    /// With no preference, the sign-in asks the user to choose a first factor (PL-10).
    ///
    /// - Given: a fresh user with a password, a verified email and a verified phone number
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: nil)` and the password
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection` with exactly the factors the pool
    ///      allows this user: password, password SRP, email OTP and SMS OTP
    ///    - the session waits on that step
    ///
    func testSignInWithNoPreference_givenValidUser_expectSelectChallenge() async throws {
        let (user, password) = try await makeUser()
        let client = try makeClient("pl-10", pool: Self.pool)

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(nil))

        let factors = try firstFactors(of: result.nextStep)
        XCTAssertEqual(factors, [.password, .passwordSRP, .emailOTP, .smsOTP], "\(factors.map(\.challengeResponse).sorted())")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))
    }

    /// A WebAuthn preference the pool does not support becomes the first-factor selection
    /// (PL-11).
    ///
    /// - Given: a fresh user with a password, on a pool whose first factors do not include `WEB_AUTHN`, and the
    ///   recorder installed
    /// - When:
    ///    - the user signs in with the password, a window, and `userAuth(preferredFirstFactor: .webAuthn)`,
    ///      through the anchored overload
    /// - Then:
    ///    - the sign-in returns `.continueSignInWithFirstFactorSelection`, as the plugin's does, with the
    ///      factors of PL-10 and without `.webAuthn`
    ///    - it sent one `InitiateAuth` `USER_AUTH` preferring `WEB_AUTHN`, and answered no challenge: no sheet
    ///    - the session waits on that step
    ///
    func testSignInWithUnsupportedPreference_givenValidUser_expectSelectChallenge() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            return XCTFail("WebAuthn needs iOS 17.4 or later; run on a newer simulator")
        }
        let (user, password) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-11")
        let window = await MainActor.run { ASPresentationAnchor() }

        let result = try await client.signIn(
            username: user.username,
            password: password,
            presentationAnchor: window,
            options: Self.userAuth(.webAuthn)
        )

        let factors = try firstFactors(of: result.nextStep)
        XCTAssertEqual(factors, [.password, .passwordSRP, .emailOTP, .smsOTP], "\(factors.map(\.challengeResponse).sorted())")
        assertInitiated(recorder, preferring: "WEB_AUTHN")
        XCTAssertEqual(recorder.answered.map(\.operation), ["InitiateAuth"])
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))
    }

    // MARK: - The one-time-code step

    /// Preferred `EMAIL_OTP` stops at the code step, and Cognito sends the code (PL-12).
    ///
    /// - Given: a fresh user with a verified email
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .emailOTP)` and no password
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP` with an email destination, and the session waits
    ///      on it
    ///    - the code sink captured a new code for the user
    ///
    func testSignInWithEmailOTPPreference_givenValidUser_expectConfirmOTPFlow() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-12", pool: Self.pool)

        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.emailOTP))
        }

        assertOTPStep(result.nextStep, .email)
        XCTAssertFalse(code.isEmpty, "the sink should hold the code")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))
    }

    /// Preferred `SMS_OTP` stops at the code step, and Cognito sends the code (PL-13).
    ///
    /// - Given: a fresh user with a verified phone number
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .smsOTP)` and no password
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP` with an SMS destination, and the session waits on it
    ///    - the code sink captured a new code for the user
    ///
    func testSignInWithSMSOTPPreference_givenValidUser_expectConfirmOTPFlow() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-13", pool: Self.pool)

        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.smsOTP))
        }

        assertOTPStep(result.nextStep, .sms)
        XCTAssertFalse(code.isEmpty, "the sink should hold the code")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))
    }

    // MARK: - Wrong passwords

    /// Preferred `PASSWORD` with a wrong password fails (PL-14).
    ///
    /// - Given: a fresh user with a password
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .password)` and a wrong password
    /// - Then:
    ///    - the sign-in throws `.notAuthorized`, and the session is signed out with nothing pending
    ///
    func testSignInWithPasswordAsPreferred_givenInvalidPassword_expectFailedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-14", pool: Self.pool)

        try await assertWrongPasswordFails(client, user, .password)
    }

    /// Preferred `PASSWORD` with a wrong password fails, and the right one then signs in
    /// (PL-15).
    ///
    /// - Given: a fresh user with a password
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .password)` and a wrong password
    ///    - then signs in the same way with the right password
    /// - Then:
    ///    - the first sign-in throws `.notAuthorized`, and the session is signed out
    ///    - the second returns `.done`, and the session is signed in as the user
    ///
    func testSignInWithPasswordAsPreferred_givenInvalidPasswordThenValidPassword_expectFailedThenCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let client = try makeClient("pl-15", pool: Self.pool)
        try await assertWrongPasswordFails(client, user, .password)

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(.password))

        XCTAssertStep(result.nextStep, .done)
        try await assertSignedIn(client, as: user)
    }

    /// Preferred `PASSWORD_SRP` with a wrong password fails (PL-16).
    ///
    /// - Given: a fresh user with a password
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .passwordSRP)` and a wrong password
    /// - Then:
    ///    - the sign-in throws `.notAuthorized`, and the session is signed out with nothing pending
    ///
    func testSignInWithPasswordSRPAsPreferred_givenInvalidPassword_expectFailedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-16", pool: Self.pool)

        try await assertWrongPasswordFails(client, user, .passwordSRP)
    }

    /// Preferred `PASSWORD_SRP` with a wrong password fails, and the right one then signs in
    /// (PL-17).
    ///
    /// - Given: a fresh user with a password
    /// - When:
    ///    - the user signs in with `userAuth(preferredFirstFactor: .passwordSRP)` and a wrong password
    ///    - then signs in the same way with the right password
    /// - Then:
    ///    - the first sign-in throws `.notAuthorized`, and the session is signed out
    ///    - the second returns `.done`, and the session is signed in as the user
    ///
    func testSignInWithPasswordSRPAsPreferred_givenInvalidPasswordThenValidPassword_expectFailedThenCompletedSignIn() async throws {
        let (user, password) = try await makeUser()
        let client = try makeClient("pl-17", pool: Self.pool)
        try await assertWrongPasswordFails(client, user, .passwordSRP)

        let result = try await client.signIn(username: user.username, password: password, options: Self.userAuth(.passwordSRP))

        XCTAssertStep(result.nextStep, .done)
        try await assertSignedIn(client, as: user)
    }

    // MARK: - Confirming email codes

    /// The right emailed code signs in (PL-18).
    ///
    /// - Given: a fresh user, signed in with a preferred `EMAIL_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with the code the sink captured
    /// - Then:
    ///    - the confirmation returns `.done`, the session is signed in as the user, and its user pool
    ///      tokens belong to the user
    ///
    func testConfirmEmailOTPWithCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-18", pool: Self.pool)
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.emailOTP))
        }
        assertOTPStep(result.nextStep, .email)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        try await assertTokensBelong(to: user, client)
    }

    /// A wrong emailed code fails, and the code step stays pending (PL-19).
    ///
    /// - Given: a fresh user, signed in with a preferred `EMAIL_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with a code that differs from the one sent in every digit
    /// - Then:
    ///    - the confirmation throws `.service(.codeMismatch)`
    ///    - the session still waits on `.confirmSignInWithOTP`
    ///
    func testConfirmEmailOTPWithIncorrectCode_givenValidUser_expectFailedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-19", pool: Self.pool)
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.emailOTP))
        }
        assertOTPStep(result.nextStep, .email)

        try await assertWrongCodeKeepsTheStep(client, code: code, step: result.nextStep)
    }

    /// A wrong emailed code fails, and the right one then signs in on the same attempt
    /// (PL-20).
    ///
    /// - Given: a fresh user, signed in with a preferred `EMAIL_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with a wrong code
    ///    - then with the code the sink captured
    /// - Then:
    ///    - the wrong code throws `.service(.codeMismatch)`, and the step stays pending
    ///    - the right code returns `.done` with no new sign-in, and the session is signed in as the user
    ///
    func testConfirmEmailOTPWithIncorrectCodeThenCorrectCode_givenValidUser_expectFailedThenCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-20")
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.emailOTP))
        }
        assertOTPStep(result.nextStep, .email)
        try await assertWrongCodeKeepsTheStep(client, code: code, step: result.nextStep)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        XCTAssertEqual(recorder.answered.count(where: { $0.operation == "InitiateAuth" }), 1, "one sign-in only")
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["EMAIL_OTP", "EMAIL_OTP"])
    }

    // MARK: - Confirming SMS codes

    /// The right texted code signs in (PL-21).
    ///
    /// - Given: a fresh user, signed in with a preferred `SMS_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with the code the sink captured
    /// - Then:
    ///    - the confirmation returns `.done`, the session is signed in as the user, and its user pool
    ///      tokens belong to the user
    ///
    func testConfirmSMSOTPWithCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-21", pool: Self.pool)
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.smsOTP))
        }
        assertOTPStep(result.nextStep, .sms)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        try await assertTokensBelong(to: user, client)
    }

    /// A wrong texted code fails with a code mismatch, and the code step stays pending
    /// (PL-22).
    ///
    /// - Given: a fresh user, signed in with a preferred `SMS_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with a code that differs from the one sent in every digit
    /// - Then:
    ///    - the confirmation throws `.service(.codeMismatch)`
    ///    - the session still waits on `.confirmSignInWithOTP`
    ///
    func testConfirmSMSOTPWithIncorrectCode_givenValidUser_expectFailedSignIn() async throws {
        let (user, _) = try await makeUser()
        let client = try makeClient("pl-22", pool: Self.pool)
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.smsOTP))
        }
        assertOTPStep(result.nextStep, .sms)

        try await assertWrongCodeKeepsTheStep(client, code: code, step: result.nextStep)
    }

    /// A wrong texted code fails, and the right one then signs in on the same attempt
    /// (PL-23).
    ///
    /// - Given: a fresh user, signed in with a preferred `SMS_OTP` and waiting on the code step
    /// - When:
    ///    - the user confirms with a wrong code
    ///    - then with the code the sink captured
    /// - Then:
    ///    - the wrong code throws `.service(.codeMismatch)`, and the step stays pending
    ///    - the right code returns `.done` with no new sign-in, and the session is signed in as the user
    ///
    func testConfirmSMSOTPWithIncorrectCodeThenCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let (user, _) = try await makeUser()
        let (client, recorder) = try makeRecordedClient("pl-23")
        let (result, code) = try await sink.code(for: user, .otp) {
            try await client.signIn(username: user.username, options: Self.userAuth(.smsOTP))
        }
        assertOTPStep(result.nextStep, .sms)
        try await assertWrongCodeKeepsTheStep(client, code: code, step: result.nextStep)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(client, as: user)
        XCTAssertEqual(recorder.answered.count(where: { $0.operation == "InitiateAuth" }), 1, "one sign-in only")
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["SMS_OTP", "SMS_OTP"])
    }

    // MARK: - Helpers

    /// A fresh user with a password, an email and a phone number, all verified (the plugin's `signUp`
    /// registers the same three), and its password.
    private func makeUser() async throws -> (user: FreshUser, password: String) {
        let user = try await makeFreshUser(on: Self.pool, .init(withEmail: true, withPhoneNumber: true))
        return try (user, XCTUnwrap(user.password))
    }

    /// A client on the pool with the recorder installed.
    private func makeRecordedClient(_ tag: String) throws -> (AmplifyCognitoClient, RecordingHTTPClient) {
        let recorder = RecordingHTTPClient()
        let client = try makeClient(tag, pool: Self.pool, configureUserPoolClient: recorder.configureUserPoolClient)
        return (client, recorder)
    }

    private static func userAuth(_ factor: AuthClientFactorType?) -> AuthClientSignInOptions {
        AuthClientSignInOptions(authFlowType: .userAuth(preferredFirstFactor: factor))
    }

    /// A code of the same length that differs from `code` in every digit, so it can never be the one sent.
    private static func wrongCode(for code: String) -> String {
        String(code.map { character in
            character.wholeNumberValue.map { Character(String(($0 + 1) % 10)) } ?? character
        })
    }

    private enum Channel {
        case email, sms
    }

    /// Asserts `.confirmSignInWithOTP` delivered over `channel`, printing no destination.
    private func assertOTPStep(
        _ step: AuthClientSignInStep,
        _ channel: Channel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .confirmSignInWithOTP(let details) = step else {
            XCTFail("the step is \(step.caseName), expected confirmSignInWithOTP", file: file, line: line)
            return
        }
        switch (channel, details.destination) {
        case (.email, .email), (.sms, .sms):
            break
        default:
            XCTFail("the code went to the wrong kind of destination", file: file, line: line)
        }
    }

    /// The factors of a `.continueSignInWithFirstFactorSelection` step; fails the test for any other step.
    private func firstFactors(
        of step: AuthClientSignInStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Set<AuthClientFactorType> {
        guard case .continueSignInWithFirstFactorSelection(let factors) = step else {
            XCTFail("the step is \(step.caseName), expected continueSignInWithFirstFactorSelection", file: file, line: line)
            throw HarnessError.malformedFixture("no first-factor selection")
        }
        return factors
    }

    /// Asserts the sign-in sent exactly one `InitiateAuth`, first, with `USER_AUTH`, preferring `factor`
    /// (nil: no preference).
    private func assertInitiated(
        _ recorder: RecordingHTTPClient,
        preferring factor: String?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let requests = recorder.answered
        let initiations = requests.filter { $0.operation == "InitiateAuth" }
        XCTAssertEqual(initiations.count, 1, "exactly one InitiateAuth", file: file, line: line)
        XCTAssertEqual(requests.first?.operation, "InitiateAuth", file: file, line: line)
        XCTAssertEqual(initiations.first?.authFlow, "USER_AUTH", file: file, line: line)
        XCTAssertEqual(initiations.first?.preferredChallenge, factor, file: file, line: line)
    }

    /// Asserts the one `SELECT_CHALLENGE` answer chose `factor`, and the challenges answered were exactly
    /// `challenges`, in order.
    private func assertSelected(
        _ recorder: RecordingHTTPClient,
        _ factor: String,
        answering challenges: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let requests = recorder.answered
        let selections = requests.filter { $0.challengeName == "SELECT_CHALLENGE" }.map(\.selectedChallenge)
        XCTAssertEqual(selections, [factor], file: file, line: line)
        XCTAssertEqual(requests.compactMap(\.challengeName), challenges, file: file, line: line)
    }

    /// Signs in with a wrong password preferring `factor`, and asserts `.notAuthorized` and a signed-out
    /// session with nothing pending.
    private func assertWrongPasswordFails(
        _ client: AmplifyCognitoClient,
        _ user: FreshUser,
        _ factor: AuthClientFactorType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let error = await Expect.authClientError("signing in with a wrong password", file: file, line: line) {
            try await client.signIn(
                username: user.username,
                password: SandboxSignUp.freshPassword(),
                options: Self.userAuth(factor)
            )
        }
        XCTAssertEqual(error?.kind, .notAuthorized, "\(String(describing: error?.kind))", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut, file: file, line: line)
    }

    /// Confirms a wrong code for the pending code step, and asserts `.service(.codeMismatch)` with the step
    /// still pending.
    private func assertWrongCodeKeepsTheStep(
        _ client: AmplifyCognitoClient,
        code: String,
        step: AuthClientSignInStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let wrong = Self.wrongCode(for: code)
        XCTAssertTrue(wrong != code && wrong.count == code.count, "the wrong code must differ", file: file, line: line)
        let error = await Expect.authClientError("confirming a wrong code", file: file, line: line) {
            try await client.confirmSignIn(challengeResponse: wrong)
        }
        XCTAssertEqual(error?.kind, .service(.codeMismatch), "\(String(describing: error?.kind))", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .awaitingChallenge(step), file: file, line: line)
    }

    /// Asserts the session is signed in as `user`, printing no username or sub.
    private func assertSignedIn(
        _ client: AmplifyCognitoClient,
        as user: FreshUser,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let current = try await client.getCurrentUser()
        XCTAssertTrue(current.username == user.username, "signed in as another user", file: file, line: line)
        XCTAssertTrue(current.userId == user.userSub, "signed in with another sub", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(current), file: file, line: line)
    }

    /// Asserts the session's user pool tokens are the user's: the id token's `sub` is the user's.
    private func assertTokensBelong(
        to user: FreshUser,
        _ client: AmplifyCognitoClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let tokens = try await client.fetchAuthSession().userPoolTokensResult.get()
        let sub = try IntegrationTestEnvironment.jwtClaims(tokens.idToken)["sub"] as? String
        XCTAssertTrue(sub == user.userSub, "the id token belongs to another user", file: file, line: line)
    }
}
