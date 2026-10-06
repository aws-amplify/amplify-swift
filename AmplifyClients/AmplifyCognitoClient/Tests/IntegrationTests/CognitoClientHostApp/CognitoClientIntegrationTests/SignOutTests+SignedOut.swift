//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Signing out a session that holds no user.
extension SignOutTests {

    /// Signing out a signed-out session completes, sends nothing and writes nothing (SO-4; the
    /// plugin's `testSignedOutWithUnAuthState`).
    ///
    /// - Given: a client on a fresh session that never signed in, the recorder installed and the event
    ///   stream subscribed
    /// - When:
    ///    - `signOut()`
    /// - Then:
    ///    - it returns `.complete`, and the state is still `.signedOut`
    ///    - the recorder saw no request
    ///    - once the handle is gone, the event stream delivered nothing: no credentials were removed, so
    ///      there is no `.signedOut`
    ///    - no row is listed for the session, and the keychain holds no account for it
    ///
    func testSignOutOfASignedOutSessionCompletes() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let recorder = RecordingHTTPClient()
        let sessionId = try makeSessionID("signed-out")
        let events: StreamRecorder<AuthEvent>
        do {
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            events = StreamRecorder(client.listenToAuthEvents())

            let result = await client.signOut()

            XCTAssertSignOutComplete(result)
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedOut)
        }
        // The only handle is gone, so the stream finishes and holds every event it ever delivered.
        let delivered = try await events.waitUntilFinished()
        XCTAssertEqual(delivered, [], "signing out a signed-out session sends no event")
        XCTAssertEqual(recorder.operations, [], "signing out a signed-out session sends no request")
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "the sign-out created no row")
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(sessionId.stringValue).") }, "no keychain account for the session")
    }
}
