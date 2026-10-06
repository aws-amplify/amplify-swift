//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// One user in two sessions (MS-6).
extension MultiSessionFlowTests {

    /// The same user signed in on two sessions holds two independent sessions (MS-6; the design's
    /// second clarification of the session model).
    ///
    /// - Given: alice signed in on session A and, separately, on session B
    /// - When:
    ///    - A signs out locally
    /// - Then:
    ///    - the two sessions held different refresh tokens
    ///    - A's sign-out is `.complete`, and A is `.signedOut`
    ///    - B is still `.signedIn(alice)`, and its forced refresh succeeds with a new access token
    ///
    func testSameUserInTwoSessionsIsTwoIndependentSessions() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let alice = try XCTUnwrap(users).alice
        let aId = try makeSessionID("alice-a")
        let bId = try makeSessionID("alice-b")
        let a = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aId))
        let b = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bId))
        _ = try await a.signIn(username: alice.username, password: alice.password)
        _ = try await b.signIn(username: alice.username, password: alice.password)
        let aTokens = try await a.fetchAuthSession().userPoolTokensResult.get()
        let bTokens = try await b.fetchAuthSession().userPoolTokensResult.get()
        XCTAssertTrue(aTokens.refreshToken != bTokens.refreshToken, "each sign-in holds its own refresh token")
        let bUser = try await b.getCurrentUser()
        XCTAssertTrue(bUser.username == alice.username, "B names another user")

        let signOut = await a.signOut()

        XCTAssertSignOutComplete(signOut)
        let aState = await a.currentSessionState()
        XCTAssertState(aState, .signedOut)
        let bState = await b.currentSessionState()
        XCTAssertState(bState, .signedIn(bUser))
        let refreshed = try await b.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get()
        XCTAssertTrue(refreshed.accessToken != bTokens.accessToken, "B's forced refresh minted a new access token")
        XCTAssertTrue(refreshed.refreshToken == bTokens.refreshToken, "B kept its own refresh token")
    }
}
