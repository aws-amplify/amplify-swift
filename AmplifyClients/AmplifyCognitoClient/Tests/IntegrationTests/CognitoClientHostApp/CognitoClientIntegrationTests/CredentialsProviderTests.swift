//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest

/// The session's two providers over the live engine: the user pool token provider,
/// the never-guest rule for a signed-out session, and a guest session signing in in place.
final class CredentialsProviderTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!
    private var users: SandboxUsers!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
        users = try IntegrationTestEnvironment.users()
    }

    /// The user pool token provider returns the signed-in user's access token (CR-2).
    ///
    /// - Given: alice signed in
    /// - When:
    ///    - `userPoolTokenProvider.accessToken()`
    /// - Then:
    ///    - the token's claims are an access token (`token_use`) for `alice`, issued to the configured app
    ///      client, and the same token the session reports
    ///
    func testUserPoolTokenProviderReturnsAliceAccessToken() async throws {
        let sessionId = try makeSessionID("alice")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)

        let token = try await client.userPoolTokenProvider.accessToken()

        let claims = try IntegrationTestEnvironment.jwtClaims(token)
        XCTAssertEqual(claims["token_use"] as? String, "access")
        XCTAssertEqual(claims["username"] as? String, "alice")
        let appClientId = try XCTUnwrap(configuration.userPool).appClientId
        XCTAssertTrue(claims["client_id"] as? String == appClientId, "the token is not the configured app client's")
        let sessionToken = try await client.fetchAuthSession().userPoolTokensResult.get().accessToken
        XCTAssertTrue(token == sessionToken, "the provider and the session disagree on the access token")
    }

    /// A signed-out session's credentials provider never falls back to guest credentials
    /// (CR-4; design §7 rule 2).
    ///
    /// - Given: a fresh session, never signed in and never fetched, over a pool that allows guests
    /// - When:
    ///    - its `credentialsProvider.resolve()`
    /// - Then:
    ///    - it throws `CredentialsError.notSignedIn`
    ///    - the state is still `.signedOut`, and the session has no stored row
    ///
    func testSignedOutSessionNeverFallsBackToGuest() async throws {
        let sessionId = try makeSessionID("never-guest")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))

        let error = await Expect.credentialsError("resolving a signed-out session's credentials") {
            try await client.credentialsProvider.resolve()
        }

        XCTAssertEqual(error?.caseName, "notSignedIn")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "resolving created no row")
    }

    /// A guest session signs in in place: the same session moves from guest to the user
    /// (CR-5; the plugin's `testSuccessfulSessionFetchAndSignIn`).
    ///
    /// - Given: a fresh session that became a guest through `fetchAuthSession()`
    /// - When:
    ///    - alice signs in on the same session ID
    /// - Then:
    ///    - before: the state is `.guest`, the provider signs as the unauthenticated role, and the row's
    ///      kind is `.guest`
    ///    - after: the state is `.signedIn(alice)`, the provider signs as the authenticated role, the row's
    ///      kind is `.userPoolAndIdentityPool`, and it names alice
    ///    - a `fetchAuthSession()` afterwards returns alice's tokens and sub, an identity, and AWS
    ///      credentials
    ///
    func testGuestThenSignInOnTheSameSession() async throws {
        let region = try XCTUnwrap(configuration.identityPool).region
        let roles = try SandboxRoles()
        let sessionId = try makeSessionID("guest-then-alice")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        let guest = try await client.fetchAuthSession()
        XCTAssertNoThrow(try guest.identityIdResult.get())
        let guestState = await client.currentSessionState()
        XCTAssertState(guestState, .guest)
        let guestRole = try await roles.role(of: client.credentialsProvider, region: region)
        XCTAssertEqual(guestRole, .unauthenticated)
        let guestRow = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
            .first { $0.sessionId == sessionId }
        XCTAssertEqual(guestRow?.kind, .guest)

        let result = try await client.signIn(username: users.alice.username, password: users.alice.password)

        XCTAssertStep(result.nextStep, .done)
        let alice = try await client.getCurrentUser()
        XCTAssertEqual(alice.username, "alice")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(alice))
        let role = try await roles.role(of: client.credentialsProvider, region: region)
        XCTAssertEqual(role, .authenticated)
        let row = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
            .first { $0.sessionId == sessionId }
        XCTAssertEqual(row?.kind, .userPoolAndIdentityPool)
        XCTAssertEqual(row?.username, "alice")
        // As the plugin case ends: a signed-in fetch returns the user's tokens, identity and credentials.
        let session = try await client.fetchAuthSession()
        let tokens = try session.userPoolTokensResult.get()
        XCTAssertEqual(try IntegrationTestEnvironment.jwtClaims(tokens.accessToken)["username"] as? String, "alice")
        XCTAssertTrue(try session.userSubResult.get() == alice.userId, "the session's sub is not alice's")
        // Not necessarily the guest's identity: alice already has an identity in the pool from earlier
        // runs, and Cognito maps her login to that one.
        XCTAssertNoThrow(try session.identityIdResult.get())
        XCTAssertNoThrow(try session.awsCredentialsResult.get())
    }
}
