//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Deleting the signed-in user, over the live engine.
///
/// The user is a fresh one, signed up for the test on U-DEF, the plugin's default backend (self sign-up,
/// MFA optional, devices tracked), rather than a shared sandbox user: deleting a shared user would break
/// any other run using it, and the provisioning checks that expect it.
final class DeleteUserTests: ClientIntegrationTestCase {

    /// Deleting the user removes her from the pool and removes the session's row (DU-1;
    /// the plugin's `testDeleteUserFromAuthState` and `testSuccessfulDeletedUserEvent`).
    ///
    /// - Given: a fresh user signed in on a fresh session, its event stream subscribed
    /// - When:
    ///    - `deleteUser()`
    /// - Then:
    ///    - it returns, the state is `.signedOut`, and the event stream delivers `.userDeleted`, once
    ///    - the row is gone from both listings, and the keychain holds no account for the session
    ///    - a new sign-in as the user throws `.notAuthorized` (the pool prevents user-existence errors)
    ///      or `.service(.userNotFound)`
    ///
    func testDeleteUserRemovesTheUserAndTheRow() async throws {
        let pool = SandboxPool.standard
        let configuration = try IntegrationTestEnvironment.configuration(pool)
        let fresh = try await makeFreshUser(on: pool)
        let credentials = fresh.testUser
        let sessionId = try makeSessionID("delete", pool: pool)
        let events: StreamRecorder<AuthEvent>
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            _ = try await client.signIn(username: credentials.username, password: credentials.password)
            events = StreamRecorder(client.listenToAuthEvents())

            try await client.deleteUser()
            fresh.recordDeleted()

            let state = await client.currentSessionState()
            XCTAssertState(state, .signedOut)
        }
        // The only handle is gone, so the stream finishes and holds every event it ever delivered.
        let delivered = try await events.waitUntilFinished()
        XCTAssertEqual(delivered, [.userDeleted])

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "the deleted user's row is gone")
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(sessionId.stringValue).") }, "no keychain account is left for the session")

        let retryId = try makeSessionID("delete-again", pool: pool)
        let retry = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: retryId))
        let error = await Expect.authClientError("signing a deleted user in") {
            try await retry.signIn(username: credentials.username, password: credentials.password)
        }
        let kind = try XCTUnwrap(error?.kind)
        XCTAssertTrue(kind == .notAuthorized || kind == .service(.userNotFound), "\(kind)")
    }
}
