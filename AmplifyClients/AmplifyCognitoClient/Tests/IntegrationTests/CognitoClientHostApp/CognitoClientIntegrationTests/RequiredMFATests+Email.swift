//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The plugin's `EmailMFAOnlyTests` (class `EmailMFARequiredTests`, U-REQ-E: MFA required, email) and
/// `EmailMFAWithAllMFATypesRequiredTests` (U-REQ-ALL: MFA required, TOTP, SMS and email), rows MF-18 …
/// MF-23. Email codes come from the code sink, which replaces the plugin's AppSync subscription.
extension RequiredMFATests {

    // MARK: - EmailMFAOnlyTests (U-REQ-E)

    /// A user with no email sets email MFA up during sign-in, then confirms the emailed code (MF-18).
    ///
    /// - Given: a fresh user with neither email nor phone number on U-REQ-E
    /// - When:
    ///    - the user signs in with the password
    ///    - gives an email address
    ///    - and confirms with the code sent to it
    /// - Then:
    ///    - the first step is `.continueSignInWithEmailMFASetup`, and the session waits on it
    ///    - the address gets `.confirmSignInWithOTP`, to an email destination
    ///    - the code returns `.done`, the session is signed in as the user, and the user's email is the
    ///      address given
    ///
    func testSuccessfulEmailMFASetupStep() async throws {
        try SandboxPools.pool(.mfaRequiredEmail).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredEmail, .init(withEmail: false))
        let client = try makeClient("mf-18", pool: .mfaRequiredEmail)

        let result = try await client.signIn(username: user.username, password: user.password)

        XCTAssertStep(result.nextStep, .continueSignInWithEmailMFASetup)
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(.continueSignInWithEmailMFASetup))

        let email = SandboxSignUp.setupEmail(for: user)
        let (setUp, code) = try await CodeSink().code(for: user, .mfa) {
            try await client.confirmSignIn(challengeResponse: email)
        }
        assertEmailOTPStep(setUp.nextStep)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertEmail(of: client, is: email)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// A wrong email code fails with `codeMismatch` and keeps the challenge, so the right code then
    /// completes the sign-in (MF-19).
    ///
    /// - Given: a fresh user with a verified email on U-REQ-E
    /// - When:
    ///    - the user signs in, and is sent an email code
    ///    - confirms with a different six-digit code
    ///    - then with the code sent
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP`, to an email destination
    ///    - the wrong code throws `.service(.codeMismatch)`, and the session still waits on the same step
    ///    - the right code returns `.done`, and the session is signed in as the user
    ///
    func testSuccessfulEmailMFAWithIncorrectCodeFirstAndThenValidOne() async throws {
        try SandboxPools.pool(.mfaRequiredEmail).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredEmail)
        let client = try makeClient("mf-19", pool: .mfaRequiredEmail)

        let (result, code) = try await CodeSink().code(for: user, .mfa) {
            try await client.signIn(username: user.username, password: user.password)
        }
        assertEmailOTPStep(result.nextStep)

        let error = await Expect.authClientError("confirming a wrong email code") {
            try await client.confirmSignIn(challengeResponse: Self.otherCode(than: code))
        }

        XCTAssertEqual(error?.kind, .service(.codeMismatch), "\(String(describing: error?.kind))")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    // MARK: - EmailMFAWithAllMFATypesRequiredTests (U-REQ-ALL)

    /// A user with no email or phone number must choose an MFA type to set up (MF-20).
    ///
    /// - Given: a fresh user with neither email nor phone number on U-REQ-ALL
    /// - When:
    ///    - the user signs in with the password
    /// - Then:
    ///    - the step is `.continueSignInWithMFASetupSelection`, offering TOTP and email but not SMS
    ///    - the session waits on it
    ///
    func testSuccessfulMFASetupSelectionStep() async throws {
        try SandboxPools.pool(.mfaRequiredAll).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredAll, .init(withEmail: false))
        let client = try makeClient("mf-20", pool: .mfaRequiredAll)

        let result = try await client.signIn(username: user.username, password: user.password)

        assertSetupSelection(result.nextStep)
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))
    }

    /// A user with a verified email is sent an email code, which completes the sign-in (MF-21).
    ///
    /// The plugin signs this user up with an email-shaped username. Here the username is `ccit-…` and the
    /// email is an attribute: the pre-sign-up trigger accepts only `ccit-` usernames, and U-REQ-ALL does not
    /// use email as the username, so the username's shape does not change what Cognito challenges.
    ///
    /// - Given: a fresh user with a verified email on U-REQ-ALL
    /// - When:
    ///    - the user signs in with the password
    ///    - and confirms with the emailed code
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithOTP`, to an email destination
    ///    - the code returns `.done`, and the session is signed in as the user
    ///
    func testSuccessfulEmailMFACodeStep() async throws {
        try SandboxPools.pool(.mfaRequiredAll).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredAll)
        let client = try makeClient("mf-21", pool: .mfaRequiredAll)

        let (result, code) = try await CodeSink().code(for: user, .mfa) {
            try await client.signIn(username: user.username, password: user.password)
        }
        assertEmailOTPStep(result.nextStep)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// Choosing email at the setup selection leads through the email setup to an emailed code (MF-22).
    ///
    /// - Given: a fresh user with neither email nor phone number on U-REQ-ALL
    /// - When:
    ///    - the user signs in, and is asked to choose an MFA type to set up
    ///    - chooses `AuthClientMFAType.email.challengeResponse`
    ///    - gives an email address
    ///    - and confirms with the code sent to it
    /// - Then:
    ///    - the choice returns `.continueSignInWithEmailMFASetup`
    ///    - the address returns `.confirmSignInWithOTP`, to an email destination
    ///    - the code returns `.done`, the session is signed in as the user, and the user's email is the
    ///      address given
    ///
    func testConfirmSignInForEmailMFASetupSelectionStep() async throws {
        try SandboxPools.pool(.mfaRequiredAll).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredAll, .init(withEmail: false))
        let client = try makeClient("mf-22", pool: .mfaRequiredAll)
        let result = try await client.signIn(username: user.username, password: user.password)
        assertSetupSelection(result.nextStep)

        let chosen = try await client.confirmSignIn(challengeResponse: AuthClientMFAType.email.challengeResponse)

        XCTAssertStep(chosen.nextStep, .continueSignInWithEmailMFASetup)

        let email = SandboxSignUp.setupEmail(for: user)
        let (setUp, code) = try await CodeSink().code(for: user, .mfa) {
            try await client.confirmSignIn(challengeResponse: email)
        }
        assertEmailOTPStep(setUp.nextStep)

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertEmail(of: client, is: email)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// Choosing TOTP at the setup selection leads to a TOTP setup, which completes the sign-in (MF-23).
    ///
    /// - Given: a fresh user with neither email nor phone number on U-REQ-ALL
    /// - When:
    ///    - the user signs in, and is asked to choose an MFA type to set up
    ///    - chooses `AuthClientMFAType.totp.challengeResponse`
    ///    - and confirms with a code from the shared secret, naming the device
    /// - Then:
    ///    - the choice returns `.continueSignInWithTOTPSetup`, with a shared secret and the username
    ///    - the code returns `.done`, and the session is signed in as the user
    ///
    func testConfirmSignInForTOTPMFASetupSelectionStep() async throws {
        try SandboxPools.pool(.mfaRequiredAll).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredAll, .init(withEmail: false))
        let client = try makeClient("mf-23", pool: .mfaRequiredAll)
        let result = try await client.signIn(username: user.username, password: user.password)
        assertSetupSelection(result.nextStep)

        let chosen = try await client.confirmSignIn(challengeResponse: AuthClientMFAType.totp.challengeResponse)

        let secret = try recordTOTPSetup(chosen.nextStep, of: user)
        let confirmed = try await client.confirmSignIn(
            challengeResponse: TOTP.freshCode(secret: secret),
            options: .init(friendlyDeviceName: "device")
        )

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    // MARK: - Helpers

    /// Asserts `step` is `.confirmSignInWithOTP` to a named email destination, printing neither.
    private func assertEmailOTPStep(_ step: AuthClientSignInStep, file: StaticString = #filePath, line: UInt = #line) {
        guard case .confirmSignInWithOTP(let delivery) = step else {
            return XCTFail("the step is \(step.caseName), expected confirmSignInWithOTP", file: file, line: line)
        }
        guard case .email(let destination) = delivery.destination else {
            return XCTFail("the code went to \(delivery.destination.caseName), expected email", file: file, line: line)
        }
        XCTAssertFalse(destination?.isEmpty ?? true, "the email destination is named", file: file, line: line)
    }

    /// Asserts `step` is `.continueSignInWithMFASetupSelection` offering exactly what the plugin's tests
    /// expect: TOTP and email, never SMS (an SMS setup needs a phone number).
    private func assertSetupSelection(_ step: AuthClientSignInStep, file: StaticString = #filePath, line: UInt = #line) {
        guard case .continueSignInWithMFASetupSelection(let types) = step else {
            return XCTFail("the step is \(step.caseName), expected continueSignInWithMFASetupSelection", file: file, line: line)
        }
        XCTAssertTrue(types.contains(.totp), "TOTP is offered", file: file, line: line)
        XCTAssertTrue(types.contains(.email), "email is offered", file: file, line: line)
        XCTAssertFalse(types.contains(.sms), "SMS is not offered", file: file, line: line)
    }

    /// A six-digit code other than `code`.
    private static func otherCode(than code: String) -> String {
        String(format: "%06d", ((Int(code) ?? 0) + 1) % 1_000_000)
    }
}
