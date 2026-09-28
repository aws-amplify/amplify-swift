//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The plugin's `AuthSignUpTests`, `AuthConfirmSignUpTests`, `AuthResendSignUpCodeTests`,
/// `PasswordlessSignUpTests` and `PasswordlessConfirmSignUpTests`, through the client (SU-1 … SU-15). The
/// plugin's test names are kept.
///
/// Every user signed up here is a fresh `ccit-` user, deleted at teardown. Nothing prints a password, a
/// code or a Cognito session.
final class SignUpTests: ClientSignUpTestCase {

    // MARK: AuthSignUpTests

    /// A new user on `default` signs up and is auto-confirmed (SU-1).
    ///
    /// - Given: a fresh username on `default`, whose pre-sign-up trigger confirms `ccit-` users
    /// - When:
    ///    - the client signs it up with a password and an email
    /// - Then:
    ///    - sign-up is complete, and the result carries the user's `sub`
    ///
    func testSuccessfulRegisterUser() async throws {
        let client = try makeClient("su-1", pool: .standard)

        let (result, _) = try await signUp(on: client, pool: .standard)

        XCTAssertTrue(result.isSignUpComplete, "sign-up should be complete")
        XCTAssertNotNil(result.userId)
    }

    /// Several sign-ups on one client at once each complete (SU-2).
    ///
    /// - Given: two fresh usernames on `default`
    /// - When:
    ///    - one client signs both up concurrently
    /// - Then:
    ///    - both sign-ups are complete
    ///
    func testMultipleSignUps() async throws {
        let client = try makeClient("su-2", pool: .standard)

        let users = signedUpUsers
        async let first = Self.signUp(on: client, pool: .standard, recordingIn: users)
        async let second = Self.signUp(on: client, pool: .standard, recordingIn: users)
        let (one, two) = try await (first, second)
        let results = [one.result, two.result]

        XCTAssertEqual(results.map(\.isSignUpComplete), [true, true])
    }

    /// An empty username is refused before any request (SU-3).
    ///
    /// - Given: a client on `default` with the request recorder
    /// - When:
    ///    - it signs up an empty username with a password
    /// - Then:
    ///    - it throws `validation` for `username`, and no request was sent
    ///
    func testRegisterUserValidation() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-3", pool: .standard, configureUserPoolClient: recorder.configureUserPoolClient)

        await assertValidation("username") {
            try await client.signUp(username: "", password: SandboxSignUp.freshPassword())
        }
        XCTAssertEqual(recorder.operations, [])
    }

    /// Signing up an existing username is `usernameExists` (SU-4).
    ///
    /// - Given: a fresh user already registered on `default`
    /// - When:
    ///    - the client signs the same username up again
    /// - Then:
    ///    - it throws `.service(.usernameExists)`
    ///
    func testRegisterExistingUser() async throws {
        let existing = try await makeFreshUser(on: .standard)
        let client = try makeClient("su-4", pool: .standard)

        await assertService(.usernameExists) {
            try await client.signUp(
                username: existing.username,
                password: SandboxSignUp.freshPassword(),
                options: .init(userAttributes: [.init(.email, value: try XCTUnwrap(existing.email))])
            )
        }
    }

    // MARK: AuthConfirmSignUpTests

    /// Confirming a user who does not exist fails with a code error, never `userNotFound`: the pool's app
    /// client prevents user-existence errors (SU-5). Cognito answers `ExpiredCodeException` today. The plugin's
    /// `AuthConfirmSignUpTests` accepts `userNotFound` or `codeMismatch`; with existence errors prevented, this one accepts the two code errors.
    ///
    /// - Given: a username never registered on `default`
    /// - When:
    ///    - the client confirms it with a code
    /// - Then:
    ///    - it throws `.service` with `codeMismatch` or `codeExpired`
    ///
    func testUserNotFoundConfirmSignUp() async throws {
        let client = try makeClient("su-5", pool: .standard)

        await assertService([.codeMismatch, .codeExpired]) {
            try await client.confirmSignUp(for: SandboxSignUp.identity().username, confirmationCode: "232323")
        }
    }

    /// An empty code is refused before any request (SU-6).
    ///
    /// - Given: a client on `default` with the request recorder
    /// - When:
    ///    - it confirms a username with an empty code
    /// - Then:
    ///    - it throws `validation` for `code`, and no request was sent
    ///
    func testConfirmSignUpValidation() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-6", pool: .standard, configureUserPoolClient: recorder.configureUserPoolClient)

        await assertValidation("code") {
            try await client.confirmSignUp(for: SandboxSignUp.identity().username, confirmationCode: "")
        }
        XCTAssertEqual(recorder.operations, [])
    }

    // MARK: AuthResendSignUpCodeTests

    /// Resending the code of a user who does not exist answers a simulated email delivery: the pool
    /// prevents existence errors and verifies email (SU-7, the plugin's Gen2 expectation).
    ///
    /// - Given: a username never registered on `default`
    /// - When:
    ///    - the client resends its sign-up code
    /// - Then:
    ///    - the destination is an email, and one `ResendConfirmationCode` was sent
    ///
    func testUserNotFoundResendSignUpCode() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-7", pool: .standard, configureUserPoolClient: recorder.configureUserPoolClient)

        let details = try await client.resendSignUpCode(for: SandboxSignUp.identity().username)

        guard case .email = details.destination else {
            return XCTFail("expected an email destination")
        }
        XCTAssertEqual(recorder.operations, ["ResendConfirmationCode"])
    }

    // MARK: PasswordlessSignUpTests

    /// A passwordless sign-up waits for its confirmation code (SU-8).
    ///
    /// - Given: a fresh `ccit-confirm-` username on `passwordless`, which the trigger leaves unconfirmed
    /// - When:
    ///    - the client signs it up with an email and no password
    /// - Then:
    ///    - the next step is `.confirmUser` with an email delivery, and sign-up is not complete
    ///
    func testSuccessfulPasswordlessRegisterUser() async throws {
        let client = try makeClient("su-8", pool: .passwordless)

        let (result, _) = try await signUp(on: client, pool: .passwordless, needsConfirmation: true, withPassword: false)

        guard case .confirmUser(let details, _, _) = result.nextStep else {
            return XCTFail("expected .confirmUser")
        }
        guard case .email? = details?.destination else {
            return XCTFail("expected an email delivery")
        }
        XCTAssertFalse(result.isSignUpComplete)
    }

    /// Several passwordless sign-ups on one client at once each wait for confirmation (SU-9).
    ///
    /// - Given: two fresh `ccit-confirm-` usernames on `passwordless`
    /// - When:
    ///    - one client signs both up concurrently, without passwords
    /// - Then:
    ///    - both are `.confirmUser`, not complete
    ///
    func testSuccessfulMultiplePasswordlessSignUps() async throws {
        let client = try makeClient("su-9", pool: .passwordless)

        let users = signedUpUsers
        async let first = Self.signUp(
            on: client,
            pool: .passwordless,
            needsConfirmation: true,
            withPassword: false,
            recordingIn: users
        )
        async let second = Self.signUp(
            on: client,
            pool: .passwordless,
            needsConfirmation: true,
            withPassword: false,
            recordingIn: users
        )
        let (one, two) = try await (first, second)
        let results = [one.result, two.result]

        for result in results {
            guard case .confirmUser = result.nextStep else {
                return XCTFail("expected .confirmUser")
            }
            XCTAssertFalse(result.isSignUpComplete)
        }
    }

    /// An empty username is refused before any request (SU-10).
    ///
    /// - Given: a client on `passwordless` with the request recorder
    /// - When:
    ///    - it signs up an empty username with an email and no password
    /// - Then:
    ///    - it throws `validation` for `username`, and no request was sent
    ///
    func testFailureRegisterUserEmptyUsername() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-10", pool: .passwordless, configureUserPoolClient: recorder.configureUserPoolClient)

        await assertValidation("username") {
            try await client.signUp(
                username: "",
                options: .init(userAttributes: [.init(.email, value: SandboxSignUp.identity().email)])
            )
        }
        XCTAssertEqual(recorder.operations, [])
    }

    /// Signing up an existing passwordless username is `usernameExists` (SU-11).
    ///
    /// - Given: a fresh passwordless user the client signed up on `passwordless`, unconfirmed
    /// - When:
    ///    - the client signs the same username up again
    /// - Then:
    ///    - it throws `.service(.usernameExists)`
    ///
    func testFailureRegisterExistingUser() async throws {
        let client = try makeClient("su-11", pool: .passwordless)
        let (first, user) = try await signUp(on: client, pool: .passwordless, needsConfirmation: true, withPassword: false)
        guard case .confirmUser = first.nextStep else {
            return XCTFail("expected .confirmUser")
        }

        await assertService(.usernameExists) {
            try await client.signUp(
                username: user.username,
                options: .init(userAttributes: [.init(.email, value: try XCTUnwrap(user.email))])
            )
        }
    }

    // MARK: PasswordlessConfirmSignUpTests

    /// Confirming a user who does not exist fails with a code error, never `userNotFound`: the pool's app
    /// client prevents user-existence errors (SU-12). Cognito answers `ExpiredCodeException` today. The plugin's
    /// `PasswordlessConfirmSignUpTests` accepts `userNotFound`, `codeMismatch` or `codeExpired`; with existence errors prevented, this one accepts the two code errors.
    ///
    /// - Given: a username never registered on `passwordless`
    /// - When:
    ///    - the client confirms it with a code
    /// - Then:
    ///    - it throws `.service` with `codeMismatch` or `codeExpired`
    ///
    func testFailurePasswordlessConfirmSignUpUserNotFound() async throws {
        let client = try makeClient("su-12", pool: .passwordless)

        await assertService([.codeMismatch, .codeExpired]) {
            try await client.confirmSignUp(for: SandboxSignUp.identity().username, confirmationCode: "123456")
        }
    }

    /// An empty code is refused before any request (SU-13).
    ///
    /// - Given: a client on `passwordless` with the request recorder
    /// - When:
    ///    - it confirms a username with an empty code
    /// - Then:
    ///    - it throws `validation` for `code`, and no request was sent
    ///
    func testFailurePasswordlessConfirmSignUpEmptyCode() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-13", pool: .passwordless, configureUserPoolClient: recorder.configureUserPoolClient)

        await assertValidation("code") {
            try await client.confirmSignUp(for: SandboxSignUp.identity().username, confirmationCode: "")
        }
        XCTAssertEqual(recorder.operations, [])
    }

    /// An empty username is refused before any request (SU-14).
    ///
    /// - Given: a client on `passwordless` with the request recorder
    /// - When:
    ///    - it confirms an empty username with a code
    /// - Then:
    ///    - it throws `validation` for `username`, and no request was sent
    ///
    func testFailurePasswordlessConfirmSignUpEmptyUsername() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("su-14", pool: .passwordless, configureUserPoolClient: recorder.configureUserPoolClient)

        await assertValidation("username") {
            try await client.confirmSignUp(for: "", confirmationCode: "123456")
        }
        XCTAssertEqual(recorder.operations, [])
    }

    /// A passwordless sign-up, confirmed with the code Cognito sent, is ready for auto sign-in (SU-15).
    ///
    /// - Given: a fresh `ccit-confirm-` username on `passwordless`, the code sink
    /// - When:
    ///    - the client signs it up without a password, reads the sign-up code from the sink, and confirms
    /// - Then:
    ///    - sign-up is `.confirmUser`, then the confirmation is `.completeAutoSignIn` with a non-empty
    ///      session, and complete
    ///
    func testSuccessfulPasswordlessSignUpAndConfirmSignUpEndtoEnd() async throws {
        let client = try makeClient("su-15", pool: .passwordless)

        let (confirmation, _) = try await signUpAndConfirm(on: client, pool: .passwordless)

        assertReadyForAutoSignIn(confirmation)
    }
}
