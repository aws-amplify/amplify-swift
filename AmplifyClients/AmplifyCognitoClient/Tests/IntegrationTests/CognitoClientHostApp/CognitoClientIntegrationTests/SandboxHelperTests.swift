//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import Foundation
import XCTest

/// The multi-pool harness helpers work against the sandbox: `SandboxPools`,
/// `SandboxSignUp`, every `CodeSink` code kind, `SandboxUserCleanup`, and the pool-aware sessions of
/// `ClientIntegrationTestCase`. Everything here uses the raw SDK on the parity pools' public clients,
/// except the session test, which signs in with the client. No assertion prints an identifier or a secret.
final class SandboxHelperTests: ClientIntegrationTestCase {

    /// Fresh identities are test-shaped, distinct, and keep their secrets out of descriptions.
    ///
    /// - Given: `SandboxSignUp`'s identity helpers
    /// - When:
    ///    - Two identities and a fictional number are made, and a `FreshUser` is described
    /// - Then:
    ///    - The usernames start `ccit-` (`ccit-confirm-` when asked), the emails are theirs at `example.com`,
    ///      the number is `+1555` and seven digits, the passwords meet the pools' policy
    ///    - The description names only the username: no password, sub or TOTP secret
    ///
    func testFreshIdentitiesAreTestShapedAndRedacted() throws {
        let plain = SandboxSignUp.identity()
        let confirm = SandboxSignUp.identity(needsConfirmation: true)
        XCTAssertTrue(plain.username.hasPrefix("ccit-"))
        XCTAssertFalse(plain.username.hasPrefix("ccit-confirm-"))
        XCTAssertTrue(confirm.username.hasPrefix("ccit-confirm-"))
        XCTAssertNotEqual(plain.username, SandboxSignUp.identity().username)
        XCTAssertEqual(plain.email, "\(plain.username)@example.com")
        let phone = SandboxSignUp.fictionalPhoneNumber()
        XCTAssertTrue(phone.hasPrefix("+1555"))
        XCTAssertEqual(phone.count, 12)
        XCTAssertTrue(phone.dropFirst().allSatisfy(\.isNumber))
        XCTAssertTrue(plain.password.contains { $0.isUppercase })
        XCTAssertTrue(plain.password.contains { $0.isLowercase })
        XCTAssertTrue(plain.password.contains { $0.isNumber })
        XCTAssertTrue(plain.password.contains { !$0.isLetter && !$0.isNumber })
        XCTAssertGreaterThanOrEqual(plain.password.count, 12)

        let user = FreshUser(
            pool: .standard, username: plain.username, password: plain.password, email: plain.email,
            phoneNumber: phone, userSub: "sub-sentinel", isConfirmed: true
        )
        user.recordTOTPSecret(TOTPSecret("JBSWY3DPEHPK3PXP"))
        for text in [String(describing: user), String(reflecting: user), "\(Mirror(reflecting: user).children.map(\.value))"] {
            XCTAssertFalse(text.contains(plain.password), "The password leaked")
            XCTAssertFalse(text.contains("sub-sentinel"), "The sub leaked")
            XCTAssertFalse(text.contains("JBSWY3DPEHPK3PXP"), "The TOTP secret leaked")
        }
    }

    /// Every parity pool confirms a fresh user, and the admin-free cleanup deletes it (P-5b, P-6).
    ///
    /// - Given: Each pool that has its own users, and its pre-sign-up trigger
    /// - When:
    ///    - A fresh user signs up, then `SandboxUserCleanup.delete` runs, twice
    /// - Then:
    ///    - The sign-up is confirmed (`SandboxSignUp` checks it): by the pre-sign-up trigger, or, on a pool
    ///      without one (the plugin's passwordless backend), with its sign-up code
    ///    - The first delete signs in as the user with its password (SRP where the app client offers no
    ///      password flow), answering the pool's MFA (setup, email or TOTP) where required, and deletes it;
    ///      the second is a no-op
    ///    - The user can no longer sign in
    ///    - A pool that fails is reported by name, and the others are still checked
    ///    - On CI, a pool whose sign-ups skip there (`SandboxSignUp.ciSkip(for:)`: the device-alias pool, while
    ///      the plugin's backend cannot confirm a fresh user) is left out, with its reason recorded as an
    ///      activity, so the other pools are still checked
    ///
    func testEveryPoolAutoConfirmsAFreshUserAndCleanupDeletesIt() async throws {
        for kind in SandboxPools.userPools {
            if let skip = SandboxSignUp.ciSkip(for: kind),
               IntegrationTestEnvironment.skipsOnCI(present: skip.present) {
                await XCTContext.runActivity(named: "\(kind) left out on CI. \(skip.reason.message)") { _ in }
                continue
            }
            do {
                let pool = try SandboxPools.pool(kind)
                let user = try await makeFreshUser(on: kind)
                XCTAssertTrue(user.isConfirmed, "\(kind)")

                let first = try await SandboxUserCleanup.delete(user)
                XCTAssertEqual(first, .deleted, "\(kind)")
                let second = try await SandboxUserCleanup.delete(user)
                XCTAssertEqual(second, .alreadyGone, "\(kind)")
                try await assertCannotSignIn(user, on: pool)
            } catch {
                XCTFail("\(kind): \(error)")
            }
        }
    }

    /// A `ccit-confirm-` user stays unconfirmed, and sign-up and resent codes reach the sink (P-5c).
    ///
    /// - Given: The passwordless pool (whose outputs name a code API), and a fresh user it leaves
    ///   unconfirmed
    /// - When:
    ///    - It signs up; the test reads the sign-up code, then resends and reads the new code with
    ///      `code(for:_:sentBy:)`, and confirms with that one
    /// - Then:
    ///    - The sign-up is unconfirmed, both codes arrive, the resent one confirms the user, and the
    ///      raw sign-in then returns tokens
    ///
    func testSignUpAndResentCodesReachTheSinkAndConfirm() async throws {
        let pool = try SandboxPools.pool(.passwordless)
        let sink = try CodeSink()
        let since = Date()
        let user = try await makeFreshUser(on: .passwordless, .init(needsConfirmation: true))
        XCTAssertFalse(user.isConfirmed)
        _ = try await sink.signUpCode(for: user, since: since)

        let (_, resent) = try await sink.code(for: user, .signUp) {
            try await pool.client.resendConfirmationCode(input: ResendConfirmationCodeInput(
                clientId: pool.clientId,
                username: user.username
            ))
        }
        _ = try await pool.client.confirmSignUp(input: ConfirmSignUpInput(
            clientId: pool.clientId,
            confirmationCode: resent,
            username: user.username
        ))
        user.recordConfirmed()
        let tokens = try await pool.signIn(user, sink: sink)
        XCTAssertNotNil(tokens.accessToken)
    }

    /// On the email-alias pool, codes are found by the username Cognito generated (U-ALIAS, P-5c).
    ///
    /// A sandbox check: it needs a code API on an email-alias pool. It runs on
    /// `IntegrationTestEnvironment.emailAliasCodesRole`: the sandbox's email-alias pool, or on CI the client's own
    /// `ccit-ci-email-alias-codes`, which the capabilities file says so for (`SandboxCapability.emailAliasCodes`).
    /// The plugin's device-alias backend has none (its suite signs in a pre-created user and reads no code), so
    /// with neither it skips, saying so.
    ///
    /// - Given: That role's pool, where the email is the username attribute, and a fresh
    ///   `ccit-confirm-…@example.com` user
    /// - When:
    ///    - It signs up by email; `SandboxSignUp.confirm` reads the code by `sinkUsername` and confirms;
    ///      the user signs in with its email
    /// - Then:
    ///    - The code arrives under the generated username, the confirmation succeeds, and the access
    ///      token's `username` is that generated username, not the email
    ///
    func testEmailAliasCodesAreFoundByTheGeneratedUsername() async throws {
        let role = IntegrationTestEnvironment.emailAliasCodesRole
        try IntegrationTestEnvironment.requireCapability(.emailAliasCodes, on: role)
        let pool = try SandboxPools.pool(role)
        let sink = try CodeSink()
        let since = Date()
        let user = try await makeFreshUser(on: role, .init(needsConfirmation: true))
        XCTAssertEqual(user.username, user.email)

        try await SandboxSignUp.confirm(user, sentSince: since, on: pool, sink: sink)
        let tokens = try await pool.signIn(user, sink: sink)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        let username = try XCTUnwrap(claims["username"] as? String)
        XCTAssertTrue(username == user.sinkUsername, "The token's username is not the sink's key")
        XCTAssertFalse(username == user.email, "The token's username is the email")
    }

    /// A password-reset code reaches the sink, and cleanup uses the recorded new password (U-DEF).
    ///
    /// A sandbox check: it needs a code API on the default pool and emails its pre-sign-up trigger verifies. It
    /// runs on the role with the default backend's extras (`IntegrationTestEnvironment.extrasRole`): the sandbox's
    /// default pool, or on CI the client's own `ccit-ci-default`, which the capabilities file says so for
    /// (`SandboxCapability.resetPasswordCodes`). The plugin's default backend has neither (its trigger only
    /// confirms), so with neither it skips, saying so.
    ///
    /// - Given: A fresh, confirmed user on that role's pool (recovery by verified email)
    /// - When:
    ///    - `ForgotPassword` runs; the test reads the code and confirms a new password, and records it
    /// - Then:
    ///    - The code resets the password: the new one signs in, and tearDown deletes the user with it
    ///
    func testResetPasswordCodeReachesTheSink() async throws {
        let role = IntegrationTestEnvironment.extrasRole
        try IntegrationTestEnvironment.requireCapability(.resetPasswordCodes, on: role)
        let pool = try SandboxPools.pool(role)
        let sink = try CodeSink()
        let user = try await makeFreshUser(on: role)
        let since = Date()

        _ = try await pool.client.forgotPassword(input: ForgotPasswordInput(clientId: pool.clientId, username: user.username))
        let code = try await sink.resetPasswordCode(for: user, since: since)
        let newPassword = SandboxSignUp.freshPassword()
        _ = try await pool.client.confirmForgotPassword(input: ConfirmForgotPasswordInput(
            clientId: pool.clientId,
            confirmationCode: code,
            password: newPassword,
            username: user.username
        ))
        user.recordPassword(newPassword)

        let signIn = try await pool.passwordSignIn(user)
        XCTAssertNotNil(signIn.authenticationResult?.accessToken)
    }

    /// Attribute verification codes reach the sink, for an update and for a resend (U-PL).
    ///
    /// - Given: A fresh, signed-in user on the passwordless pool (whose outputs name a code API)
    /// - When:
    ///    - It changes its email to another `@example.com` address and verifies it with the code, then
    ///      asks for a verification code again and verifies with that one
    /// - Then:
    ///    - Both codes arrive and `VerifyUserAttribute` accepts each. Each is the first code sent after
    ///      its request: on a pool without a pre-sign-up trigger (the plugin's passwordless backend) the
    ///      user was confirmed with a sign-up code moments before, which must not be taken for the first
    ///
    func testAttributeVerificationCodesReachTheSink() async throws {
        let pool = try SandboxPools.pool(.passwordless)
        let sink = try CodeSink()
        let user = try await makeFreshUser(on: .passwordless)
        let signedIn = try await pool.signIn(user, sink: sink)
        let accessToken = try XCTUnwrap(signedIn.accessToken)

        let (_, updateCode) = try await sink.code(for: user, .attributeVerification) {
            try await pool.client.updateUserAttributes(input: UpdateUserAttributesInput(
                accessToken: accessToken,
                userAttributes: [.init(name: "email", value: SandboxSignUp.identity().email)]
            ))
        }
        _ = try await pool.client.verifyUserAttribute(input: VerifyUserAttributeInput(
            accessToken: accessToken,
            attributeName: "email",
            code: updateCode
        ))

        let (_, resendCode) = try await sink.code(for: user, .attributeVerification) {
            try await pool.client.getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput(
                accessToken: accessToken,
                attributeName: "email"
            ))
        }
        _ = try await pool.client.verifyUserAttribute(input: VerifyUserAttributeInput(
            accessToken: accessToken,
            attributeName: "email",
            code: resendCode
        ))
    }

    /// Email and SMS MFA codes reach the sink, and the raw sign-in answers them (U-REQ-E, U-REQ-ALL).
    ///
    /// - Given: A fresh user on the email-MFA-required pool, and one with a fictional number and no email
    ///   on the all-types-required pool (the MFA-required pool with TOTP and SMS whose outputs name a code
    ///   API), where SMS is then its one MFA type
    /// - When:
    ///    - Each signs in with its password (SRP where the app client offers no password flow, as on the
    ///      plugin's MFA backends): first by hand, reading the first code sent after the sign-in started,
    ///      then through `SandboxPoolClient.signIn`
    /// - Then:
    ///    - The email user is challenged `EMAIL_OTP` and the code returns tokens; the SMS user's raw
    ///      sign-in returns tokens (answering `SMS_MFA`, choosing it first if asked)
    ///
    func testMFACodesReachTheSinkAndTheRawSignInAnswersThem() async throws {
        let emailPool = try SandboxPools.pool(.mfaRequiredEmail)
        let sink = try CodeSink()
        let emailUser = try await makeFreshUser(on: .mfaRequiredEmail)
        let (start, code) = try await sink.code(for: emailUser, .mfa) {
            try await emailPool.passwordSignIn(emailUser)
        }
        XCTAssertEqual(start.challengeName, .emailOtp)
        let result = try await emailPool.respond(
            to: .emailOtp,
            ["USERNAME": emailUser.username, "EMAIL_OTP_CODE": code],
            session: start.session
        )
        XCTAssertNotNil(result.authenticationResult?.accessToken)

        let smsPool = try SandboxPools.pool(.mfaRequiredAll)
        let smsUser = try await makeFreshUser(on: .mfaRequiredAll, .init(withEmail: false, withPhoneNumber: true))
        let tokens = try await smsPool.signIn(smsUser, sink: sink)
        XCTAssertNotNil(tokens.accessToken)
        XCTAssertNil(smsUser.totpSecret, "The SMS user was made to set up TOTP instead")
    }

    /// First-factor OTP codes reach the sink, for a passwordless sign-up too (U-PL).
    ///
    /// - Given: The passwordless pool, a user signed up **without a password**, and one with a
    ///   fictional number
    /// - When:
    ///    - The first signs in through `SandboxPoolClient.signIn` (`USER_AUTH`, `EMAIL_OTP`)
    ///    - The second starts `USER_AUTH` preferring `SMS_OTP`, and answers with the first code sent after
    ///      the start (on a pool without a pre-sign-up trigger, its sign-up code came moments before)
    /// - Then:
    ///    - Both return tokens, and tearDown deletes the passwordless user through an OTP sign-in
    ///
    func testOTPCodesReachTheSinkForAPasswordlessSignUp() async throws {
        let pool = try SandboxPools.pool(.passwordless)
        let sink = try CodeSink()
        let passwordless = try await makeFreshUser(on: .passwordless, .init(withPassword: false))
        XCTAssertNil(passwordless.password)
        let tokens = try await pool.signIn(passwordless, sink: sink)
        XCTAssertNotNil(tokens.accessToken)

        let smsUser = try await makeFreshUser(on: .passwordless, .init(withPhoneNumber: true))
        let (start, code) = try await sink.code(for: smsUser, .otp) {
            try await pool.userAuthSignIn(username: smsUser.username, preferredChallenge: "SMS_OTP")
        }
        XCTAssertEqual(start.challengeName, .smsOtp)
        let result = try await pool.respond(
            to: .smsOtp,
            ["USERNAME": smsUser.username, "SMS_OTP_CODE": code],
            session: start.session
        )
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// A user who enrolled TOTP is challenged for it, and cleanup answers it (U-DEF, MFA optional).
    ///
    /// - Given: A fresh, signed-in user on the default pool
    /// - When:
    ///    - `enrollTOTP` associates, verifies and prefers a new secret; the user signs in again; then
    ///      `SandboxUserCleanup.delete` runs
    /// - Then:
    ///    - The second sign-in is challenged `SOFTWARE_TOKEN_MFA`, the delete succeeds by answering it,
    ///      and the user can no longer sign in
    ///
    func testTOTPEnrolledUserIsChallengedAndCleanupDeletesIt() async throws {
        let pool = try SandboxPools.pool(.standard)
        let user = try await makeFreshUser(on: .standard)
        let signedIn = try await pool.signIn(user)
        let accessToken = try XCTUnwrap(signedIn.accessToken)
        try await pool.enrollTOTP(user, accessToken: accessToken)
        XCTAssertNotNil(user.totpSecret)

        let challenged = try await pool.passwordSignIn(user)
        XCTAssertEqual(challenged.challengeName, .softwareTokenMfa)
        let outcome = try await SandboxUserCleanup.delete(user)
        XCTAssertEqual(outcome, .deleted)
        try await assertCannotSignIn(user, on: pool)
    }

    /// Cleanup deletes a user that has no email on the email-MFA pool by setting email MFA up with the
    /// address the email rows use (U-REQ-E), as it must when MF-18 fails before its own setup.
    ///
    /// - Given: A fresh user on `mfa-req-email` signed up without an email or phone number
    /// - When:
    ///    - `SandboxUserCleanup.delete` runs
    /// - Then:
    ///    - The raw sign-in is challenged `MFA_SETUP`, offering `EMAIL_OTP` and not `SOFTWARE_TOKEN_MFA`
    ///    - The delete succeeds by answering it with
    ///      `SandboxSignUp.setupEmail(for:)` and the emailed code, and the user can no longer sign in
    ///
    func testCleanupSetsUpEmailMFAForAUserWithoutAnEmail() async throws {
        let pool = try SandboxPools.pool(.mfaRequiredEmail)
        try pool.requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredEmail, .init(withEmail: false))

        let challenged = try await pool.passwordSignIn(user)
        XCTAssertEqual(challenged.challengeName, .mfaSetup)
        // Only email can be set up, so the cleanup must take the email path, not the TOTP one.
        let data = try XCTUnwrap(challenged.challengeParameters?["MFAS_CAN_SETUP"]?.data(using: .utf8))
        let offered = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String])
        XCTAssertTrue(offered.contains("EMAIL_OTP"), "\(offered)")
        XCTAssertFalse(offered.contains("SOFTWARE_TOKEN_MFA"), "\(offered)")
        let outcome = try await SandboxUserCleanup.delete(user)
        XCTAssertEqual(outcome, .deleted)
        try await assertCannotSignIn(user, on: pool)
    }

    /// Cleanup confirms an unconfirmed user with a resent code, then deletes it (U-PL).
    ///
    /// - Given: A fresh `ccit-confirm-` user on the passwordless pool (whose outputs name a code API),
    ///   never confirmed
    /// - When:
    ///    - `SandboxUserCleanup.delete` runs
    /// - Then:
    ///    - It deletes the user, which can then not sign in (rather than being unconfirmed)
    ///
    func testCleanupConfirmsAndDeletesAnUnconfirmedUser() async throws {
        let pool = try SandboxPools.pool(.passwordless)
        let user = try await makeFreshUser(on: .passwordless, .init(needsConfirmation: true))

        let outcome = try await SandboxUserCleanup.delete(user)
        XCTAssertEqual(outcome, .deleted)
        XCTAssertTrue(user.isConfirmed)
        try await assertCannotSignIn(user, on: pool)
    }

    /// Sessions on several pools are cleaned up, each with its own pool's configuration
    /// (`makeClient(_:pool:)`, `SessionCleanup.cleanUp(_:)`, which tearDown runs).
    ///
    /// - Given: A client over a session on the main configuration and one over a session on the passwordless pool, each
    ///   read once and dropped
    /// - When:
    ///    - `SessionCleanup.cleanUp` runs for both sessions
    /// - Then:
    ///    - The parity client was built from the passwordless pool's configuration, not the main one
    ///    - Neither session is live, and neither has a row
    ///
    func testSessionsOnSeveralPoolsAreCleanedUpWithTheirOwnPool() async throws {
        let parityConfiguration = try IntegrationTestEnvironment.configuration(.passwordless)
        var sessions: [CreatedSession] = []
        for pool in [nil, SandboxPool.passwordless] {
            let client = try makeClient("h2-\(pool?.rawValue ?? "rup")", pool: pool)
            sessions.append(CreatedSession(sessionId: client.sessionId, accessGroup: nil, pool: pool))
            if pool != nil {
                // Compared without XCTAssertEqual, which would print the ids.
                XCTAssertTrue(
                    client.core.configuration.userPool?.appClientId == parityConfiguration.userPool?.appClientId,
                    "The parity client is not on the passwordless pool's app client"
                )
            }
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedOut)
        }

        try await SessionCleanup.cleanUp(sessions)

        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        for session in sessions {
            XCTAssertNil(SessionCoreRegistry.shared.liveSession(for: session.sessionId))
            XCTAssertFalse(accounts.contains { $0.contains(".\(session.sessionId.stringValue).") }, RealKeychain.redact("\(accounts)"))
        }
    }

    // MARK: - Private

    /// Fails unless Cognito refuses the user's password sign-in as for a user that does not exist.
    private func assertCannotSignIn(_ user: FreshUser, on pool: SandboxPoolClient, line: UInt = #line) async throws {
        do {
            _ = try await pool.passwordSignIn(user)
            XCTFail("\(user) still signs in on \(pool.pool)", line: line)
        } catch is NotAuthorizedException {
            // Expected: existence errors are prevented, so a deleted user reads as a wrong password.
        } catch is UserNotFoundException {
            // Also a deleted user.
        }
    }
}
