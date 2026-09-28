//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Signing one session out while another stays signed in (MS-2).
extension MultiSessionFlowTests {

    /// Signing out one session leaves the other signed in, and the event goes to the signed-out session
    /// only (MS-2; the plugin's `testNonGlobalSignOut` and `testSuccessfulSignOutEvent`).
    ///
    /// - Given: alice signed in on session A and bob on session B, both event streams subscribed
    /// - When:
    ///    - A signs out
    /// - Then:
    ///    - A's sign-out is `.complete`, and A is `.signedOut`
    ///    - B is still `.signedIn(bob)`, and B's forced refresh succeeds
    ///    - once both sessions are released, A's stream delivered exactly `[.signedOut]` and B's nothing
    ///
    func testSignOutOfOneSessionLeavesTheOther() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let users = try IntegrationTestEnvironment.users()
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let aliceEvents: StreamRecorder<AuthEvent>
        let bobEvents: StreamRecorder<AuthEvent>
        do {
            let alice = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
            let bob = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bobId))
            _ = try await alice.signIn(username: users.alice.username, password: users.alice.password)
            _ = try await bob.signIn(username: users.bob.username, password: users.bob.password)
            let bobUser = try await bob.getCurrentUser()
            aliceEvents = StreamRecorder(alice.listenToAuthEvents())
            bobEvents = StreamRecorder(bob.listenToAuthEvents())

            let signOut = try await alice.signOut()

            XCTAssertEqual(signOut, .complete)
            let aliceState = await alice.currentSessionState()
            XCTAssertState(aliceState, .signedOut)
            let bobState = await bob.currentSessionState()
            XCTAssertState(bobState, .signedIn(bobUser))
            let refreshed = try await bob.fetchAuthSession(options: .init(forceRefresh: true))
            let accessToken = try refreshed.userPoolTokensResult.get().accessToken
            XCTAssertEqual(try IntegrationTestEnvironment.jwtClaims(accessToken)["username"] as? String, "bob")
        }

        // Both handles are gone, so both streams finish and hold every event they delivered.
        let aliceDelivered = try await aliceEvents.waitUntilFinished()
        let bobDelivered = try await bobEvents.waitUntilFinished()
        XCTAssertEqual(aliceDelivered, [.signedOut])
        XCTAssertEqual(bobDelivered, [], "bob's stream carries nothing of alice's sign-out")
    }
}
