//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest

/// Refresh over the live engine: one network refresh per session however many
/// callers ask, and a global sign-out reaching a sibling session on its next refresh.
final class RefreshTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
    }

    /// Concurrent forced refreshes on one session make one network refresh, and each session has its
    /// own (RF-2).
    ///
    /// - Given: alice signed in on session A and bob on session B, each with its own recorder, reset
    ///   after sign-in
    /// - When:
    ///    - 20 forced refreshes and 20 `userPoolTokenProvider.accessToken()` calls run concurrently on A,
    ///      while 20 forced refreshes run on B
    /// - Then:
    ///    - A's recorder counts exactly one `GetTokensFromRefreshToken`, and so does B's
    ///    - all 20 of A's forced refreshes return one access token, a new one; each provider call returns
    ///      either that token or the one it replaced (a still-valid token is served without waiting for
    ///      the refresh), and a provider call afterwards returns the new one
    ///    - B's refreshes all return one new token of bob's, different from A's
    ///
    func testConcurrentForcedRefreshesMakeOneNetworkRefresh() async throws {
        let aliceUser = try await makeSignInUser()
        let bobUser = try await makeSignInUser()
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let aliceRecorder = RecordingHTTPClient()
        let bobRecorder = RecordingHTTPClient()
        let alice = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: aliceId, configureUserPoolClient: aliceRecorder.configureUserPoolClient)
        )
        let bob = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: bobId, configureUserPoolClient: bobRecorder.configureUserPoolClient)
        )
        _ = try await alice.signIn(username: aliceUser.username, password: aliceUser.password)
        _ = try await bob.signIn(username: bobUser.username, password: bobUser.password)
        let aliceBefore = try await alice.userPoolTokenProvider.accessToken()
        let bobBefore = try await bob.userPoolTokenProvider.accessToken()
        aliceRecorder.reset()
        bobRecorder.reset()

        let results = try await withThrowingTaskGroup(of: (String, String).self) { group in
            for _ in 0 ..< 20 {
                group.addTask {
                    try await ("alice-forced", alice.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get().accessToken)
                }
                group.addTask {
                    try await ("alice-provider", alice.userPoolTokenProvider.accessToken())
                }
                group.addTask {
                    try await ("bob-forced", bob.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get().accessToken)
                }
            }
            var results: [(String, String)] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        XCTAssertEqual(aliceRecorder.operations.count(where: { $0 == "GetTokensFromRefreshToken" }), 1, "\(aliceRecorder.operations)")
        XCTAssertEqual(bobRecorder.operations.count(where: { $0 == "GetTokensFromRefreshToken" }), 1, "\(bobRecorder.operations)")
        let aliceForced = Set(results.filter { $0.0 == "alice-forced" }.map(\.1))
        let aliceProvided = Set(results.filter { $0.0 == "alice-provider" }.map(\.1))
        let bobForced = Set(results.filter { $0.0 == "bob-forced" }.map(\.1))
        XCTAssertEqual(results.count, 60)
        XCTAssertEqual(aliceForced.count, 1, "every forced refresh on A joined one refresh")
        XCTAssertEqual(bobForced.count, 1, "every forced refresh on B joined one refresh")
        let aliceAfter = try XCTUnwrap(aliceForced.first)
        let bobAfter = try XCTUnwrap(bobForced.first)
        XCTAssertTrue(aliceAfter != aliceBefore, "the forced refresh minted a new token")
        XCTAssertTrue(bobAfter != bobBefore, "the forced refresh minted a new token")
        XCTAssertTrue(aliceAfter != bobAfter, "each session holds its own token")
        XCTAssertTrue(aliceProvided.isSubset(of: [aliceBefore, aliceAfter]), "a provider call returned a third token")
        let aliceLater = try await alice.userPoolTokenProvider.accessToken()
        XCTAssertTrue(aliceLater == aliceAfter, "the provider serves the refreshed token")
        XCTAssertTrue(try IntegrationTestEnvironment.jwtClaims(aliceAfter)["username"] as? String == aliceUser.username, "A's token")
        XCTAssertTrue(try IntegrationTestEnvironment.jwtClaims(bobAfter)["username"] as? String == bobUser.username, "B's token")
    }

    /// A global sign-out on one session expires the same user's other session at its next refresh
    /// (RF-3; the plugin's `testGlobalSignOut`). The plugin's `testSessionExpiredEvent` and
    /// `testSessionExpired` plant an expired record instead, and `SessionTests` mirrors them (SE-5).
    ///
    /// A global sign-out revokes every refresh token the user holds, anywhere. So the user is a fresh
    /// one, signed up on U-DEF and deleted at teardown, never a shared sandbox user another run may be
    /// using. The client reaches U-DEF through the configuration federated into an identity pool
    /// (`FederatedStandardPool`), so the sessions hold AWS credentials too.
    ///
    /// - Given: a fresh user signed in on sessions A and B, B's event stream subscribed
    /// - When:
    ///    - A signs out with `globalSignOut: true`
    ///    - B force-refreshes, twice
    /// - Then:
    ///    - A's sign-out is `.complete`
    ///    - B's refreshes report `.sessionExpired` in the token field; B stays `.signedIn(user)`,
    ///      and its row is kept and still listed
    ///    - B's credentials provider and its user pool token provider throw `CredentialsError.sessionExpired`
    ///    - B's event stream delivered `.sessionExpired` exactly once
    ///
    func testGlobalSignOutElsewhereExpiresTheSiblingSession() async throws {
        let poolConfiguration = try FederatedStandardPool.configuration()
        let fresh = try await makeFreshUser(on: .standard).testUser
        // Not minted through makeSessionID, so the cleanup names the configuration these sessions use.
        // Teardown blocks run before tearDown, so these are signed out and purged before the fresh user is
        // deleted.
        let sessionA = try IntegrationTestEnvironment.uniqueSessionID("fresh-a")
        let sessionB = try IntegrationTestEnvironment.uniqueSessionID("fresh-b")
        addTeardownBlock {
            try await SessionCleanup.cleanUp(
                [CreatedSession(sessionId: sessionA, accessGroup: nil), CreatedSession(sessionId: sessionB, accessGroup: nil)],
                configuration: poolConfiguration
            )
        }
        let signOutResult: AuthClientSignOutResult
        let events: StreamRecorder<AuthEvent>
        do {
            let a = try AmplifyCognitoClient(configuration: poolConfiguration, options: .init(sessionId: sessionA))
            let b = try AmplifyCognitoClient(configuration: poolConfiguration, options: .init(sessionId: sessionB))
            _ = try await a.signIn(username: fresh.username, password: fresh.password)
            _ = try await b.signIn(username: fresh.username, password: fresh.password)
            let user = try await b.getCurrentUser()
            // B holds AWS credentials before the sign-out, so the provider's failure below is the expiry.
            _ = try await b.credentialsProvider.resolve()
            events = StreamRecorder(b.listenToAuthEvents())

            signOutResult = try await a.signOut(options: .init(globalSignOut: true))

            for attempt in 1 ... 2 {
                let refreshed = try await b.fetchAuthSession(options: .init(forceRefresh: true))
                guard case .failure(let error) = refreshed.userPoolTokensResult else {
                    return XCTFail("refresh \(attempt) after a global sign-out elsewhere succeeded")
                }
                XCTAssertEqual(error.kind, .sessionExpired, "refresh \(attempt): \(error)")
            }
            let state = await b.currentSessionState()
            XCTAssertState(state, .signedIn(user), "an expired session stays signed in as its user")
            let listed = try await AmplifyCognitoClient.storedSessions(configuration: poolConfiguration)
            XCTAssertTrue(listed.first { $0.sessionId == sessionB }?.username == fresh.username, "the expired session's row is kept")
            let credentialsError = await Expect.credentialsError("an expired session's AWS credentials") {
                try await b.credentialsProvider.resolve()
            }
            XCTAssertEqual(credentialsError?.caseName, "sessionExpired")
            let tokenError = await Expect.credentialsError("an expired session's access token") {
                try await b.userPoolTokenProvider.accessToken()
            }
            XCTAssertEqual(tokenError?.caseName, "sessionExpired")
        }

        XCTAssertEqual(signOutResult, .complete)
        // Both handles are gone, so B's stream finishes and holds every event it delivered.
        let delivered = try await events.waitUntilFinished()
        XCTAssertEqual(delivered, [.sessionExpired])
    }
}
