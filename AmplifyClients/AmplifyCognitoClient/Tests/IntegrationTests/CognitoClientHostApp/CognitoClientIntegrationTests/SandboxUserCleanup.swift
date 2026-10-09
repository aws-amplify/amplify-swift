//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import Foundation
import XCTest

/// Deletes fresh users without admin calls: each user deletes itself (`DeleteUser`) with tokens from its
/// own raw sign-in, as the plugin's tests do with `deleteUser()`.
///
/// The sign-in answers every challenge a fresh user can meet (`SandboxPoolClient.signIn(_:sink:)`),
/// so it works on the MFA-required pools and for users who enrolled TOTP. It is a password sign-in, with
/// SRP where the app client offers no `USER_PASSWORD_AUTH` (the plugin's Gen2 MFA-required and device-alias
/// backends, and the hosted-UI clients). A user still unconfirmed is confirmed first with a resent code
/// from the code API; on a backend with none, the cleanup fails naming the file, since the user cannot
/// sign in. On an app client that offers neither flow, the user signs in through another role's app
/// client on the same user pool, or else with SRP through the client, on a session of its own, and
/// deletes itself with `deleteUser()`. Deleting a user also invalidates every token it holds. The
/// sandbox's `prepare-run.sh` removes whatever a crashed run leaves behind (P-12).
enum SandboxUserCleanup {

    enum Outcome: Equatable, Sendable {
        /// The user signed in and deleted itself.
        case deleted
        /// The user was already gone: the test deleted it (`FreshUser.recordDeleted()`), or Cognito
        /// refuses its credentials (existence errors are prevented, so a deleted user reads as a wrong
        /// password; so does a password change the test did not record, which leaves the user to P-12).
        case alreadyGone
        /// The user could not be deleted from this process: its app client offers no password flow, no
        /// other role's client is on its pool, and the process has no keychain for the client's SRP
        /// sign-in (a UI-test runner). It is left for the backend's cleanup of old test users, and the
        /// reason is logged without the user's name, as `.alreadyGone` leaves an unrecorded password
        /// change to that cleanup: neither fails the test, whose assertions have passed.
        case left
    }

    /// Deletes `user` through its own session. Calling it again is a no-op.
    @discardableResult
    static func delete(_ user: FreshUser, sink: CodeSink? = nil) async throws -> Outcome {
        guard !user.isDeleted else {
            return .alreadyGone
        }
        let pool = try SandboxPools.pool(user.pool)
        if !user.isConfirmed {
            guard (try? IntegrationTestEnvironment.codeSinkAPI(user.pool)) != nil else {
                // Only a code confirms a user without an administrator; a user that cannot be confirmed
                // cannot sign in to delete itself.
                throw HarnessError.malformedFixture("""
                \(user) is unconfirmed, and \(user.pool.sourceName) names no code API to confirm it with, so it \
                cannot sign in to delete itself: it is left on the backend.
                """)
            }
            await confirmFirst(user, on: pool, sink: sink)
        }
        var attempt = 0
        while true {
            attempt += 1
            let tokens: CognitoIdentityProviderClientTypes.AuthenticationResultType
            do {
                tokens = try await signIn(user, on: pool, sink: sink)
            } catch is InvalidParameterException {
                // The app client offers neither USER_PASSWORD_AUTH nor SRP: Cognito refuses the flow itself
                // with InvalidParameterException, before looking at the user.
                return try await deleteWithoutAPasswordFlow(user, on: pool, sink: sink)
            } catch is NotAuthorizedException {
                user.recordDeleted()
                return .alreadyGone
            } catch is UserNotFoundException {
                user.recordDeleted()
                return .alreadyGone
            }
            guard let accessToken = tokens.accessToken else {
                throw HarnessError.malformedFixture("\(user)'s sign-in returned no access token.")
            }
            do {
                _ = try await pool.client.deleteUser(input: DeleteUserInput(accessToken: accessToken))
            } catch let error as NotAuthorizedException
                where attempt < revokedTokenAttempts && error.message?.contains("revoked") == true {
                // "Access Token has been revoked": a global sign-out the test made a moment before also
                // revokes a token issued within the same second or so (RF-3, once in three iterations on
                // CI). A new sign-in a little later gets one that holds. Any other refusal is thrown.
                try await Task.sleep(nanoseconds: 2_000_000_000)
                continue
            } catch is UserNotFoundException {
                // The SDK retried a `DeleteUser` whose response was lost (`NSURLErrorNetworkConnectionLost`,
                // seen once locally): the first attempt deleted the user, and the retry finds it gone.
                user.recordDeleted()
                return .deleted
            }
            user.recordDeleted()
            return .deleted
        }
    }

    /// How many sign-ins cleanup makes when `DeleteUser` finds the new access token already revoked.
    private static let revokedTokenAttempts = 3

    /// For a user whose app client offers no password flow: a raw sign-in through another role's app client
    /// on the same user pool, if there is one, else `deleteThroughClient`. A process with no keychain for
    /// the client (a UI-test runner) leaves the user (`.left`).
    private static func deleteWithoutAPasswordFlow(
        _ user: FreshUser,
        on pool: SandboxPoolClient,
        sink: CodeSink?
    ) async throws -> Outcome {
        let poolId = pool.configuration.userPool?.poolId
        for other in SandboxPools.userPools where other != user.pool {
            guard let sibling = try? SandboxPools.pool(other), sibling.configuration.userPool?.poolId == poolId else {
                continue
            }
            let tokens: CognitoIdentityProviderClientTypes.AuthenticationResultType
            do {
                tokens = try await sibling.signIn(user, sink: sink)
            } catch is NotAuthorizedException {
                user.recordDeleted()
                return .alreadyGone
            } catch is UserNotFoundException {
                user.recordDeleted()
                return .alreadyGone
            }
            guard let accessToken = tokens.accessToken else {
                throw HarnessError.malformedFixture("\(user)'s sign-in returned no access token.")
            }
            do {
                _ = try await sibling.client.deleteUser(input: DeleteUserInput(accessToken: accessToken))
            } catch is UserNotFoundException {
                // A retried `DeleteUser` whose first attempt deleted the user, as in `delete(_:sink:)`.
            }
            user.recordDeleted()
            return .deleted
        }
        do {
            return try await deleteThroughClient(user, on: pool)
        } catch let error as AuthClientError {
            guard case .storageUnavailable = error.kind else {
                throw error
            }
            print("""
            [SandboxUserCleanup] left a \(user.pool.rawValue) user for the backend's cleanup of old test users: its \
            app client offers no password flow, no other role's app client is on its pool, and this process has no \
            keychain for the client's SRP sign-in.
            """)
            return .left
        }
    }

    /// Signs `user` in with SRP through the client, on a session used for nothing else, deletes the user
    /// with `deleteUser()`, and purges the session. For an app client with no password flow.
    private static func deleteThroughClient(_ user: FreshUser, on pool: SandboxPoolClient) async throws -> Outcome {
        let sessionId = try IntegrationTestEnvironment.uniqueSessionID("cleanup")
        let client = try AmplifyCognitoClient(configuration: pool.configuration, options: .init(sessionId: sessionId))
        func purge() async {
            try? await AmplifyCognitoClient.purgeStoredSession(sessionId: sessionId, configuration: pool.configuration)
        }
        do {
            let result = try await client.signIn(username: user.username, password: user.password ?? "")
            guard case .done = result.nextStep else {
                await purge()
                throw HarnessError.malformedFixture("\(user)'s cleanup sign-in stopped at a challenge.")
            }
        } catch let error as AuthClientError where [.notAuthorized, .service(.userNotFound)].contains(error.kind) {
            await purge()
            user.recordDeleted()
            return .alreadyGone
        }
        do {
            try await client.deleteUser()
        } catch let error as AuthClientError where error.kind == .service(.userNotFound) {
            // A retried `DeleteUser` whose first attempt deleted the user, as in `delete(_:sink:)`.
        } catch {
            await purge()
            throw error
        }
        user.recordDeleted()
        await purge()
        return .deleted
    }

    /// Deletes the user an access token belongs to, for a test that already holds one.
    static func deleteUser(accessToken: String, on pool: SandboxPool) async throws {
        _ = try await SandboxPools.pool(pool).client.deleteUser(input: DeleteUserInput(accessToken: accessToken))
    }

    /// Confirms an unconfirmed user with its own sign-up code, before signing in as it.
    ///
    /// Without this, a passwordless user's sign-in (`EMAIL_OTP`) takes the first sink code it did not hold
    /// before; when the test ends before the sign-up code has reached the sink, that late sign-up code is
    /// taken for the OTP and Cognito answers `CodeMismatchException`. The sign-up code is the user's first,
    /// so `since` is safe. An already confirmed user is recorded as confirmed. Best effort: any other failure
    /// is left to the sign-in's `UserNotConfirmedException` fallback, which confirms with a resent code, so
    /// the deletion is always attempted.
    private static func confirmFirst(_ user: FreshUser, on pool: SandboxPoolClient, sink: CodeSink?) async {
        do {
            try await SandboxSignUp.confirm(user, sentSince: user.signedUpAt, on: pool, sink: sink ?? CodeSink())
        } catch let error as NotAuthorizedException where error.message?.contains("CONFIRMED") == true {
            // "User cannot be confirmed. Current status is CONFIRMED": the test confirmed it.
            user.recordConfirmed()
        } catch {
            // Left to the fallback in `signIn`.
        }
    }

    private static func signIn(
        _ user: FreshUser,
        on pool: SandboxPoolClient,
        sink: CodeSink?
    ) async throws -> CognitoIdentityProviderClientTypes.AuthenticationResultType {
        do {
            return try await pool.signIn(user, sink: sink)
        } catch is UserNotConfirmedException {
            let sink = try sink ?? CodeSink()
            let (_, code) = try await sink.code(for: user, .signUp) {
                try await pool.client.resendConfirmationCode(input: ResendConfirmationCodeInput(
                    clientId: pool.clientId,
                    username: user.username
                ))
            }
            _ = try await pool.client.confirmSignUp(input: ConfirmSignUpInput(
                clientId: pool.clientId,
                confirmationCode: code,
                username: user.username
            ))
            user.recordConfirmed()
            return try await pool.signIn(user, sink: sink)
        }
    }
}

extension XCTestCase {

    /// Registers `user`'s self-deletion as a teardown block, so the user is gone (and its tokens with it)
    /// however the test ends. In a `ClientIntegrationTestCase`, use `makeFreshUser(on:_:)` instead: it
    /// deletes users after the test's sessions are signed out.
    func deleteAtTeardown(_ user: FreshUser) {
        addTeardownBlock {
            try await SandboxUserCleanup.delete(user)
        }
    }

    /// Signs a fresh user up on `pool` and deletes it at teardown.
    func signUpFreshUser(on pool: SandboxPool, _ options: SandboxSignUp.Options = .init()) async throws -> FreshUser {
        let user = try await SandboxSignUp.signUp(on: pool, options)
        deleteAtTeardown(user)
        return user
    }
}
