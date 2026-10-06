//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The rest of the sign-in suite: the password flow, a wrong password, and the
/// per-session refusal.
extension SignInFlowTests {

    /// `USER_PASSWORD_AUTH` signs a user in with one request (SI-2).
    ///
    /// - Given: a client on a fresh session, the recorder installed
    /// - When:
    ///    - bob signs in with `authFlowType: .userPassword`
    /// - Then:
    ///    - the result is `.done` and the state is `.signedIn(bob)`
    ///    - the sign-in sent exactly one request, `InitiateAuth` with `AuthFlow` `USER_PASSWORD_AUTH`, and
    ///      then, as the pool's device tracking (`SandboxPool.tracksDevices`: the default backend tracks
    ///      devices) requires, exactly the new device's `ConfirmDevice`, or nothing on a pool that tracks none
    ///
    func testUserPasswordAuthSignInForBob() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let bob = try await makeSignInUser()
        let sessionId = try makeSessionID("bob")
        let recorder = RecordingHTTPClient()
        let client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )

        let result = try await client.signIn(
            username: bob.username,
            password: bob.password,
            options: AuthClientSignInOptions(authFlowType: .userPassword)
        )

        XCTAssertStep(result.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertTrue(user.username == bob.username, "signed in as another user")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
        let expected = SandboxPool.standard.tracksDevices ? ["InitiateAuth", "ConfirmDevice"] : ["InitiateAuth"]
        XCTAssertEqual(recorder.operations, expected)
        XCTAssertEqual(recorder.requests.first?.authFlow, "USER_PASSWORD_AUTH")
    }

    /// A wrong password fails and writes nothing (SI-3; the plugin's
    /// `testSignInWithWrongPassword`).
    ///
    /// - Given: a client on a fresh session
    /// - When:
    ///    - alice signs in with a wrong password
    /// - Then:
    ///    - it throws `.notAuthorized`, and the state stays `.signedOut`
    ///    - no row is listed for the session, and the keychain holds no account for it
    ///
    func testWrongPasswordFailsWithoutWritingARecord() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let alice = try await makeSignInUser()
        let sessionId = try makeSessionID("alice-wrong")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        let wrongPassword = "Wrong-\(UUID().uuidString)"

        let error = await Expect.authClientError("signing in with a wrong password") {
            try await client.signIn(username: alice.username, password: wrongPassword)
        }

        XCTAssertEqual(error?.kind, .notAuthorized)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "a failed sign-in stores no row")
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(sessionId.stringValue).") }, "no keychain account for the session")
    }

    /// A signed-in session refuses a second sign-in, but only that session: another session signs a user
    /// in at the same time (SI-4; the plugin's `testSignInWhenAlreadySignedIn`).
    ///
    /// - Given: alice signed in on session A, and a client on session B
    /// - When:
    ///    - alice signs in again on A while bob signs in on B, concurrently
    /// - Then:
    ///    - A's sign-in throws `.invalidState` with the plugin's message, and A is still `.signedIn(alice)`
    ///    - B's sign-in returns `.done`, and B is `.signedIn(bob)`
    ///
    func testSignInIsRefusedPerSessionNotPerProcess() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let aliceUser = try await makeSignInUser()
        let bobUser = try await makeSignInUser()
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let aliceClient = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
        let bobClient = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bobId))
        _ = try await aliceClient.signIn(username: aliceUser.username, password: aliceUser.password)
        let alice = try await aliceClient.getCurrentUser()

        async let bobSignIn = bobClient.signIn(username: bobUser.username, password: bobUser.password)
        let refusal = await Expect.authClientError("a second sign-in on a signed-in session") {
            try await aliceClient.signIn(username: aliceUser.username, password: aliceUser.password)
        }
        let bobResult = try await bobSignIn

        XCTAssertEqual(refusal?.kind, .invalidState)
        XCTAssertEqual(
            refusal?.errorDescription,
            "There is already a user in signedIn state. SignOut the user first before calling signIn"
        )
        let aliceState = await aliceClient.currentSessionState()
        XCTAssertState(aliceState, .signedIn(alice))
        XCTAssertStep(bobResult.nextStep, .done)
        let bob = try await bobClient.getCurrentUser()
        XCTAssertTrue(bob.username == bobUser.username, "B signed in as another user")
        let bobState = await bobClient.currentSessionState()
        XCTAssertState(bobState, .signedIn(bob))
    }
}
