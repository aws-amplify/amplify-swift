//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The plugin's `PasswordlessAutoSignInTests`, through the client (AS-1 … AS-3), on
/// the `passwordless` pool. The plugin's test names are kept. The auto-sign-in session is per session ID,
/// so AS-2 also checks that only the signing-up session is signed in and stored.
///
/// Every user signed up here is a fresh `ccit-confirm-` user, deleted at teardown.
final class AutoSignInTests: ClientSignUpTestCase {

    /// Without a sign-up, `autoSignIn` is `invalidState` and sends nothing (AS-1).
    ///
    /// - Given: a client on `passwordless` with the request recorder, and no sign-up
    /// - When:
    ///    - `autoSignIn()` is called
    /// - Then:
    ///    - it throws `invalidState`, and no request was sent
    ///
    func testFailureAutoSignInWithoutSignUp() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("as-1", pool: .passwordless, configureUserPoolClient: recorder.configureUserPoolClient)

        do {
            _ = try await client.autoSignIn()
            XCTFail("auto sign-in without a sign-up should not succeed")
        } catch AuthClientError.invalidState {
            // Expected.
        } catch {
            XCTFail("expected invalidState, got \(error)")
        }
        XCTAssertEqual(recorder.operations, [])
    }

    /// Sign up, confirm with the emailed code, then auto sign-in signs the session in (AS-2).
    ///
    /// - Given: two sessions on `passwordless`, `as-2` and `other`; the code sink
    /// - When:
    ///    - `as-2` signs a passwordless user up, confirms it with the sink's code, and calls `autoSignIn()`
    /// - Then:
    ///    - the confirmation is `.completeAutoSignIn` with a non-empty session, and complete
    ///    - the result is `.done`, `as-2` is `.signedIn` as the signed-up user, and its stream delivers
    ///      `.signedIn`
    ///    - `as-2`'s stored row names the user; `other` is not signed in, and has no row
    ///
    func testSuccessfulPasswordlessSignUpAndAutoSignInEndtoEnd() async throws {
        let configuration = try IntegrationTestEnvironment.configuration(.passwordless)
        let client = try makeClient("as-2", pool: .passwordless)
        let other = try makeClient("other", pool: .passwordless)
        _ = await client.currentSessionState()
        let events = client.listenToAuthEvents()

        let (confirmation, freshUser) = try await signUpAndConfirm(on: client, pool: .passwordless)
        assertReadyForAutoSignIn(confirmation)
        let result = try await client.autoSignIn()

        XCTAssertEqual(result.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertTrue(user.username == freshUser.username, "signed in as the signed-up user")
        let state = await client.currentSessionState()
        XCTAssertTrue(state == .signedIn(user), "the session is signed in as the signed-up user")
        let firstEvent = try await Self.firstEvent(of: events)
        XCTAssertEqual(firstEvent, .signedIn)
        let stored = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertTrue(stored.first { $0.sessionId == client.sessionId }?.username == user.username, "the row names the user")
        XCTAssertFalse(stored.contains { $0.sessionId == other.sessionId }, "the other session stores nothing")
        let otherState = await other.currentSessionState()
        XCTAssertEqual(otherState, .signedOut)
    }

    /// A second auto sign-in with the spent session, after a global sign-out, is `notAuthorized` (AS-3).
    ///
    /// - Given: a passwordless user signed up and confirmed on `as-3`
    /// - When:
    ///    - `as-3` auto signs in, signs out globally, then calls `autoSignIn()` again
    /// - Then:
    ///    - the confirmation is `.completeAutoSignIn` with a non-empty session, and complete
    ///    - the first auto sign-in is `.done` and the session is signed in; the second reaches Cognito and
    ///      throws `notAuthorized`
    ///
    func testFailureMultipleAutoSignInWithSameSession() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("as-3", pool: .passwordless, configureUserPoolClient: recorder.configureUserPoolClient)
        let (confirmation, _) = try await signUpAndConfirm(on: client, pool: .passwordless)
        assertReadyForAutoSignIn(confirmation)
        let first = try await client.autoSignIn()
        XCTAssertEqual(first.nextStep, .done)
        let afterFirst = await client.currentSessionState()
        let signedIn: Bool
        if case .signedIn = afterFirst {
            signedIn = true
        } else {
            signedIn = false
        }
        XCTAssertTrue(signedIn, "the first auto sign-in should sign the session in")

        XCTAssertSignOutComplete(await client.signOut(options: .init(globalSignOut: true)))
        recorder.reset()

        do {
            _ = try await client.autoSignIn()
            XCTFail("a second auto sign-in with the same session should not succeed")
        } catch AuthClientError.notAuthorized {
            // Expected.
        } catch {
            XCTFail("expected notAuthorized, got \(error)")
        }
        XCTAssertEqual(recorder.operations, ["InitiateAuth"])
    }

    /// The first event `events` delivers, within 10 seconds.
    private static func firstEvent(of events: AsyncStream<AuthEvent>) async throws -> AuthEvent? {
        try await withThrowingTaskGroup(of: AuthEvent?.self) { group in
            group.addTask {
                for await event in events {
                    return event
                }
                return nil
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                throw HarnessError.timedOut("the first auth event")
            }
            defer { group.cancelAll() }
            return try await group.next() ?? nil
        }
    }
}
