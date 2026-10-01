//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The base of the suites that sign users up through the client: it records each user the client signs up,
/// and deletes it at teardown, after the test's sessions are signed out.
class ClientSignUpTestCase: ClientIntegrationTestCase {

    /// The users the client signed up in this test, for teardown. Sendable, so concurrent sign-ups can
    /// record into it without capturing the test case.
    let signedUpUsers = SignedUpUsers()

    override func tearDown() async throws {
        var firstError: Error?
        do {
            // The sessions first: a user's deletion must not race its own session's sign-out.
            try await super.tearDown()
        } catch {
            firstError = error
        }
        for user in signedUpUsers.takeAll() {
            do {
                // It confirms a user the test left unconfirmed first.
                try await SandboxUserCleanup.delete(user)
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }

    /// Signs a fresh user up through `client`, with an email, and records it for deletion.
    func signUp(
        on client: AmplifyCognitoClient,
        pool: SandboxPool,
        needsConfirmation: Bool = false,
        withPassword: Bool = true
    ) async throws -> (result: AuthClientSignUpResult, user: FreshUser) {
        try await Self.signUp(
            on: client,
            pool: pool,
            needsConfirmation: needsConfirmation,
            withPassword: withPassword,
            recordingIn: signedUpUsers
        )
    }

    /// Signs a fresh user up through `client`, with an email, and records it in `users`. A
    /// `needsConfirmation` user is `ccit-confirm-`, which the pre-sign-up trigger leaves unconfirmed.
    ///
    /// As `SandboxSignUp`: it fails before any request on a role that cannot confirm a fresh user
    /// (`SandboxSignUp.requireNotKnownUnconfirmable(_:)`), and it starts the role's code subscription before
    /// the sign-up (`CodeSink.prepare(_:)`), which on a plugin backend is the only way to see its code.
    static func signUp(
        on client: AmplifyCognitoClient,
        pool: SandboxPool,
        needsConfirmation: Bool = false,
        withPassword: Bool = true,
        recordingIn users: SignedUpUsers
    ) async throws -> (result: AuthClientSignUpResult, user: FreshUser) {
        try SandboxSignUp.requireNotKnownUnconfirmable(pool)
        let identity = SandboxSignUp.identity(needsConfirmation: needsConfirmation)
        let password = withPassword ? identity.password : nil
        // Listening before the sign-up: its code is published once, when it is sent.
        await CodeSink.prepare(pool)
        let signedUpAt = Date()
        let result = try await client.signUp(
            username: identity.username,
            password: password,
            options: .init(userAttributes: [.init(.email, value: identity.email)])
        )
        // Recorded before any check, so a user Cognito created is deleted whatever follows.
        let user = FreshUser(
            pool: pool,
            username: identity.username,
            password: password,
            email: identity.email,
            phoneNumber: nil,
            userSub: result.userId ?? "",
            isConfirmed: result.isSignUpComplete,
            signedUpAt: signedUpAt
        )
        users.append(user)
        guard result.userId != nil else {
            throw HarnessError.malformedFixture("sign-up should return the user's sub")
        }
        return (result, user)
    }

    /// Signs a fresh passwordless `ccit-confirm-` user up through `client`, then confirms it with the
    /// sign-up code from the sink.
    ///
    /// - Returns: the confirmation's result, and the user.
    func signUpAndConfirm(
        on client: AmplifyCognitoClient,
        pool: SandboxPool
    ) async throws -> (confirmation: AuthClientSignUpResult, user: FreshUser) {
        let (signUp, user) = try await signUp(on: client, pool: pool, needsConfirmation: true, withPassword: false)
        guard case .confirmUser = signUp.nextStep else {
            throw HarnessError.malformedFixture("the passwordless sign-up should wait for confirmation")
        }
        XCTAssertFalse(signUp.isSignUpComplete)
        let code = try await CodeSink().signUpCode(for: user, since: user.signedUpAt)
        let confirmation = try await client.confirmSignUp(for: user.username, confirmationCode: code)
        user.recordConfirmed()
        return (confirmation, user)
    }

    /// Asserts a confirmation left an auto-sign-in session: `.completeAutoSignIn` with a non-empty session,
    /// and complete. Prints neither the session nor the user.
    func assertReadyForAutoSignIn(
        _ confirmation: AuthClientSignUpResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .completeAutoSignIn(let session) = confirmation.nextStep else {
            return XCTFail("expected .completeAutoSignIn", file: file, line: line)
        }
        XCTAssertFalse(session.isEmpty, "the auto-sign-in session should not be empty", file: file, line: line)
        XCTAssertTrue(confirmation.isSignUpComplete, "the confirmed sign-up should be complete", file: file, line: line)
    }

    func assertValidation(
        _ field: String,
        _ body: () async throws -> some Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await body()
            XCTFail("expected a validation error", file: file, line: line)
        } catch AuthClientError.validation(let actual, _, _, _) {
            XCTAssertEqual(actual, field, file: file, line: line)
        } catch {
            XCTFail("expected a validation error, got \(error)", file: file, line: line)
        }
    }

    func assertService(
        _ code: AuthClientServiceErrorCode,
        _ body: () async throws -> some Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertService([code], body, file: file, line: line)
    }

    func assertService(
        _ codes: Set<AuthClientServiceErrorCode>,
        _ body: () async throws -> some Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await body()
            XCTFail("expected one of \(codes)", file: file, line: line)
        } catch AuthClientError.service(let actual, _, _, _) {
            let matched = actual.map(codes.contains) ?? false
            XCTAssertTrue(matched, "\(String(describing: actual)) is not one of \(codes)", file: file, line: line)
        } catch {
            XCTFail("expected one of \(codes), got \(error)", file: file, line: line)
        }
    }
}

/// The users a test signed up through the client, recorded as they are created.
final class SignedUpUsers: @unchecked Sendable {
    private let lock = NSLock()
    private var users: [FreshUser] = []

    func append(_ user: FreshUser) {
        lock.withLock { users.append(user) }
    }

    /// Every recorded user, emptying the record.
    func takeAll() -> [FreshUser] {
        lock.withLock {
            let taken = users
            users = []
            return taken
        }
    }
}
