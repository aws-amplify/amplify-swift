//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Sign-in on the pools that require MFA, through the client's
/// `signIn` and `confirmSignIn` only.
///
/// This file holds the plugin's `TOTPSetupWhenUnauthenticatedTests` (MF-13 … MF-17, on U-REQ-TS:
/// MFA required, TOTP and SMS). `RequiredMFATests+Email.swift` holds `EmailMFAOnlyTests` (MF-18, MF-19,
/// U-REQ-E) and `EmailMFAWithAllMFATypesRequiredTests` (MF-20 … MF-23, U-REQ-ALL). Each test keeps the
/// plugin's method name.
///
/// Every user is fresh and is deleted: through the client once the test has signed it in, otherwise in
/// `tearDown`, whose raw sign-in answers the pool's MFA (a TOTP secret the test records, a code from the
/// code sink, or a TOTP or email setup). Codes, secrets, usernames and delivery destinations never
/// reach a failure message.
final class RequiredMFATests: ClientIntegrationTestCase {

    // MARK: - TOTPSetupWhenUnauthenticatedTests (U-REQ-TS)

    /// A user with no phone number must set up TOTP to sign in (MF-13).
    ///
    /// - Given: a fresh user without a phone number on U-REQ-TS (MFA required, TOTP and SMS)
    /// - When:
    ///    - the user signs in with the password
    /// - Then:
    ///    - the step is `.continueSignInWithTOTPSetup`, with a shared secret and the user's username
    ///    - the session waits on that step
    ///
    func testSetupMFANextStepDuringSignIn() async throws {
        let user = try await makeFreshUser(on: .mfaRequiredTOTPSMS)
        let client = try makeClient("mf-13", pool: .mfaRequiredTOTPSMS)

        let result = try await client.signIn(username: user.username, password: user.password)

        let details = try totpSetupDetails(result.nextStep, of: user)
        let state = await client.currentSessionState()
        XCTAssertState(state, .awaitingChallenge(.continueSignInWithTOTPSetup(details)))
    }

    /// A user with a phone number is sent an SMS code, which completes the sign-in (MF-14). The plugin
    /// stops at the step, having no access to the SMS; the client also confirms, with the code sink's
    /// copy.
    ///
    /// It reads the SMS code, so it runs on U-REQ-ALL (MFA required with TOTP, SMS and email), the
    /// MFA-required backend closest to U-REQ-TS whose outputs name a code API; U-REQ-TS's name none. The user
    /// has no email, so SMS is its one MFA type there as on U-REQ-TS.
    ///
    /// - Given: a fresh user with a (fictional) phone number and no email on U-REQ-ALL, whose SMS codes the
    ///   code sink captures
    /// - When:
    ///    - the user signs in with the password
    ///    - and confirms with the SMS code
    /// - Then:
    ///    - the step is `.confirmSignInWithSMSMFACode`, to an SMS destination, and the session waits on it
    ///    - the confirmation returns `.done`, and the session is signed in as the user
    ///
    func testSMSMFANextStepDuringSignIn() async throws {
        try SandboxPools.pool(.mfaRequiredAll).requireLive("sms-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredAll, .init(withEmail: false, withPhoneNumber: true))
        let client = try makeClient("mf-14", pool: .mfaRequiredAll)

        let (result, code) = try await CodeSink().code(for: user, .mfa) {
            try await client.signIn(username: user.username, password: user.password)
        }

        guard case .confirmSignInWithSMSMFACode(let delivery, _) = result.nextStep else {
            return XCTFail("the step is \(result.nextStep.caseName), expected confirmSignInWithSMSMFACode")
        }
        guard case .sms(let destination) = delivery.destination else {
            return XCTFail("the code went to \(delivery.destination.caseName), expected sms")
        }
        XCTAssertFalse(destination?.isEmpty ?? true, "the SMS destination is named")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// TOTP set up during sign-in completes the sign-in (MF-15).
    ///
    /// - Given: a fresh user without a phone number on U-REQ-TS
    /// - When:
    ///    - the user signs in, and is asked to set up TOTP
    ///    - and confirms with a code from the shared secret
    /// - Then:
    ///    - the confirmation returns `.done`, and the session is signed in as the user
    ///
    func testSuccessfulSignForSetupMFANextStep() async throws {
        let user = try await makeFreshUser(on: .mfaRequiredTOTPSMS)
        let client = try makeClient("mf-15", pool: .mfaRequiredTOTPSMS)
        let result = try await client.signIn(username: user.username, password: user.password)
        let secret = try recordTOTPSetup(result.nextStep, of: user)

        let confirmed = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// A wrong TOTP setup code fails with `softwareTokenMFANotEnabled` and keeps the setup, so the right
    /// code then completes the sign-in (MF-16).
    ///
    /// - Given: a fresh user on U-REQ-TS, asked to set up TOTP during sign-in
    /// - When:
    ///    - the user confirms with a six-digit code no nearby step produces
    ///    - then with a fresh, right code
    /// - Then:
    ///    - the wrong code throws `.service(.softwareTokenMFANotEnabled)`, and the session still waits
    ///      on the same TOTP setup
    ///    - the right code returns `.done`, and the session is signed in as the user
    ///
    func testSuccessfulSignInForSetupMFANextStepAfterInvalidInitialEntry() async throws {
        let user = try await makeFreshUser(on: .mfaRequiredTOTPSMS)
        let client = try makeClient("mf-16", pool: .mfaRequiredTOTPSMS)
        let result = try await client.signIn(username: user.username, password: user.password)
        let secret = try recordTOTPSetup(result.nextStep, of: user)

        let wrongCode = try TOTP.wrongCode(secret: secret)
        let error = await Expect.authClientError("confirming the TOTP setup with a wrong code") {
            try await client.confirmSignIn(challengeResponse: wrongCode)
        }

        XCTAssertEqual(error?.kind, .service(.softwareTokenMFANotEnabled), "\(String(describing: error?.kind))")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))

        let confirmed = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }

    /// A non-numeric TOTP setup code fails with `invalidParameter` and keeps the setup, so the right
    /// code then completes the sign-in (MF-17).
    ///
    /// - Given: a fresh user on U-REQ-TS, asked to set up TOTP during sign-in
    /// - When:
    ///    - the user confirms with the alphabetic `userCode`
    ///    - then with a fresh, right code
    /// - Then:
    ///    - the alphabetic code throws `.service(.invalidParameter)`, and the session still waits on the
    ///      same TOTP setup
    ///    - the right code returns `.done`, and the session is signed in as the user
    ///
    func testSuccessfulSignInForSetupMFANextStepAfterInvalidParameterException() async throws {
        let user = try await makeFreshUser(on: .mfaRequiredTOTPSMS)
        let client = try makeClient("mf-17", pool: .mfaRequiredTOTPSMS)
        let result = try await client.signIn(username: user.username, password: user.password)
        let secret = try recordTOTPSetup(result.nextStep, of: user)

        let error = await Expect.authClientError("confirming the TOTP setup with an alphabetic code") {
            try await client.confirmSignIn(challengeResponse: "userCode")
        }

        XCTAssertEqual(error?.kind, .service(.invalidParameter), "\(String(describing: error?.kind))")
        let pending = await client.currentSessionState()
        XCTAssertState(pending, .awaitingChallenge(result.nextStep))

        let confirmed = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedInThenDelete(user, on: client)
    }
}

// MARK: - Helpers

extension RequiredMFATests {

    /// The TOTP setup `step` carries, checked as the plugin checks it: a shared secret, and the user's
    /// username. Neither is printed.
    func totpSetupDetails(
        _ step: AuthClientSignInStep,
        of user: FreshUser,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> AuthClientTOTPSetupDetails {
        guard case .continueSignInWithTOTPSetup(let details) = step else {
            XCTFail("the step is \(step.caseName), expected continueSignInWithTOTPSetup", file: file, line: line)
            throw HarnessError.malformedFixture("no TOTP setup step")
        }
        XCTAssertFalse(details.sharedSecret.isEmpty, "the setup has a shared secret", file: file, line: line)
        XCTAssertTrue(details.username == user.username, "the setup names another user", file: file, line: line)
        return details
    }

    /// The TOTP setup `step` carries, its secret recorded on `user` before anything is verified, so the
    /// cleanup's raw sign-in can answer `SOFTWARE_TOKEN_MFA` if the setup completes.
    func recordTOTPSetup(
        _ step: AuthClientSignInStep,
        of user: FreshUser,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> TOTPSecret {
        let secret = try TOTPSecret(totpSetupDetails(step, of: user, file: file, line: line).sharedSecret)
        user.recordTOTPSecret(secret)
        return secret
    }

    /// Asserts `client` is signed in as `user`, then deletes the user through the client, so the cleanup
    /// has nothing left to do.
    func assertSignedInThenDelete(
        _ user: FreshUser,
        on client: AmplifyCognitoClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let current = try await client.getCurrentUser()
        XCTAssertTrue(current.username == user.username, "signed in as another user", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(current), file: file, line: line)

        try await client.deleteUser()
        user.recordDeleted()
    }

    /// Asserts the signed-in user's email, read through the client's `fetchUserAttributes`, is `email`, as
    /// the plugin's email-setup tests do. Neither side is printed.
    func assertEmail(
        of client: AmplifyCognitoClient,
        is email: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let attributes = try await client.fetchUserAttributes()
        let stored = attributes.first { $0.key == .email }?.value
        XCTAssertTrue(stored == email, "the user's email is the address set up", file: file, line: line)
    }
}

extension AuthClientDeliveryDestination {

    /// The case's name alone, without the (masked) destination.
    var caseName: String {
        switch self {
        case .email: return "email"
        case .phone: return "phone"
        case .sms: return "sms"
        case .unknown: return "unknown"
        }
    }
}
