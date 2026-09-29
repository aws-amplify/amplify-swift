//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import XCTest

/// The plugin's `AuthStressTests` that need only sign-in and sessions: 50 concurrent calls on one
/// session, the plugin's `concurrencyLimit`. ST-1 (attributes) is `UserAttributesStressTests`.
///
/// Bounded and deterministic: each test starts exactly 50 unstructured tasks, as the plugin's do, and waits
/// for all of them with `fulfillment(of:timeout:)` and the plugin's `networkTimeout` (5 s,
/// `AuthStressBaseTest`), so a hung or slow batch fails rather than hangs; then it asserts on what every call
/// returned and on the requests the recorder counted.
/// The recorder sees only user pool requests (the identity client has no configure hook); a
/// single identity ID and access key ID across the 50 results is the evidence of a single `GetId` and
/// `GetCredentialsForIdentity`, since each of those calls would mint new ones.
final class StressTests: ClientIntegrationTestCase {

    private static let concurrencyLimit = 50
    /// The plugin's `AuthStressBaseTest.networkTimeout`.
    private static let networkTimeout: TimeInterval = 5

    /// 50 concurrent fetches of a signed-in session return it, with no refresh (ST-2; the
    /// plugin's `testMultipleFetchAuthSessionAfterSignIn`).
    ///
    /// - Given: alice signed in, the recorder then reset
    /// - When:
    ///    - 50 concurrent `fetchAuthSession()` calls
    /// - Then:
    ///    - every one is signed in, with the same access token, one identity and one set of AWS credentials
    ///    - the recorder saw no request: 0 refreshes
    ///
    func testMultipleFetchAuthSessionAfterSignIn() async throws {
        let recorder = RecordingHTTPClient()
        let alice = try await makeSignInUser()
        let client = try makeClient("stress-fetch", configureUserPoolClient: recorder.configureUserPoolClient)
        _ = try await client.signIn(username: alice.username, password: alice.password)
        recorder.reset()

        let sessions = try await concurrently(Self.concurrencyLimit, timeout: Self.networkTimeout) { _ in try await client.fetchAuthSession() }

        XCTAssertEqual(sessions.count, Self.concurrencyLimit)
        let tokens = try Set(sessions.map { try fingerprint($0.userPoolTokensResult.get().accessToken) })
        XCTAssertEqual(tokens.count, 1, "every fetch returns the same access token")
        XCTAssertEqual(try Set(sessions.map { try $0.identityIdResult.get() }).count, 1, "one identity")
        XCTAssertEqual(try Set(sessions.map { try $0.awsCredentialsResult.get().accessKeyId }).count, 1, "one set of credentials")
        XCTAssertEqual(recorder.operations, [], "fetching fresh tokens refreshes nothing")
    }

    /// 50 concurrent fetches with one forced refresh among them all return, with one network refresh
    /// (ST-3, as RF-2; the plugin's `testMultipleFetchAuthSessionWithRandomForceRefresh`).
    ///
    /// - Given: alice signed in, a first fetch made, and the recorder then reset
    /// - When:
    ///    - 50 concurrent fetches; the one at index 25 (`concurrencyLimit / 2`, the 26th) forces a refresh, as the
    ///      plugin's `index == concurrencyLimit / 2` does
    /// - Then:
    ///    - every fetch has an identity; every access token is the old one or the forced refresh's new one
    ///    - the recorder saw exactly one `GetTokensFromRefreshToken`
    ///    - a fetch afterwards returns the new token
    ///
    func testMultipleFetchAuthSessionWithRandomForceRefresh() async throws {
        let recorder = RecordingHTTPClient()
        let alice = try await makeSignInUser()
        let client = try makeClient("stress-force", configureUserPoolClient: recorder.configureUserPoolClient)
        _ = try await client.signIn(username: alice.username, password: alice.password)
        let before = try await fingerprint(client.fetchAuthSession().userPoolTokensResult.get().accessToken)
        recorder.reset()
        let forced = Self.concurrencyLimit / 2

        let sessions = try await concurrently(Self.concurrencyLimit, timeout: Self.networkTimeout) { index in
            try await client.fetchAuthSession(options: .init(forceRefresh: index == forced))
        }

        for (index, session) in sessions.enumerated() {
            XCTAssertNoThrow(try session.identityIdResult.get(), "fetch \(index) has an identity")
        }
        let refreshed = try fingerprint(sessions[forced].userPoolTokensResult.get().accessToken)
        XCTAssertFalse(refreshed == before, "the forced fetch returns a new access token")
        for (index, session) in sessions.enumerated() {
            let token = try fingerprint(session.userPoolTokensResult.get().accessToken)
            XCTAssertTrue(token == before || token == refreshed, "fetch \(index) returns the old or the new token")
        }
        XCTAssertEqual(recorder.operations, ["GetTokensFromRefreshToken"], "one forced refresh, one network refresh")
        let after = try await fingerprint(client.fetchAuthSession().userPoolTokensResult.get().accessToken)
        XCTAssertTrue(after == refreshed, "a fetch afterwards returns the new token")
    }

    /// 50 concurrent fetches of a signed-out session make it one guest (ST-4; the plugin's
    /// `testMultipleFetchAuthSessionWhenSignedOut`).
    ///
    /// - Given: a fresh session, never signed in, over the default backend (its identity pool allows guests)
    /// - When:
    ///    - 50 concurrent `fetchAuthSession()` calls
    /// - Then:
    ///    - none is signed in (`.notSignedIn` tokens); every one has AWS credentials
    ///    - all 50 share one identity ID and one access key ID: one guest identity
    ///    - the state is `.guest`
    ///
    func testMultipleFetchAuthSessionWhenSignedOut() async throws {
        let client = try makeClient("stress-guest")

        let sessions = try await concurrently(Self.concurrencyLimit, timeout: Self.networkTimeout) { _ in try await client.fetchAuthSession() }

        for (index, session) in sessions.enumerated() {
            guard case .failure(let error) = session.userPoolTokensResult else {
                XCTFail("guest fetch \(index) is signed in")
                continue
            }
            XCTAssertEqual(error.kind, .notSignedIn, "guest fetch \(index)")
        }
        XCTAssertEqual(try Set(sessions.map { try $0.identityIdResult.get() }).count, 1, "one guest identity")
        XCTAssertEqual(try Set(sessions.map { try $0.awsCredentialsResult.get().accessKeyId }).count, 1, "one set of credentials")
        let state = await client.currentSessionState()
        XCTAssertState(state, .guest)
    }

    /// 50 concurrent `getCurrentUser()` calls all return the signed-in user, without the network
    /// (ST-5; the plugin's `testMultipleGetCurrentUser`).
    ///
    /// - Given: alice signed in, the recorder then reset
    /// - When:
    ///    - 50 concurrent `getCurrentUser()` calls
    /// - Then:
    ///    - every one is alice, with her id token's sub
    ///    - the recorder saw no request
    ///
    func testMultipleGetCurrentUser() async throws {
        let recorder = RecordingHTTPClient()
        let alice = try await makeSignInUser()
        let client = try makeClient("stress-user", configureUserPoolClient: recorder.configureUserPoolClient)
        _ = try await client.signIn(username: alice.username, password: alice.password)
        let idToken = try await client.fetchAuthSession().userPoolTokensResult.get().idToken
        let sub = try XCTUnwrap(IntegrationTestEnvironment.jwtClaims(idToken)["sub"] as? String)
        recorder.reset()

        let found = try await concurrently(Self.concurrencyLimit, timeout: Self.networkTimeout) { _ in try await client.getCurrentUser() }

        XCTAssertEqual(found.count, Self.concurrencyLimit)
        for (index, user) in found.enumerated() {
            XCTAssertTrue(user.username == alice.username, "call \(index) returns alice")
            XCTAssertTrue(user.userId == sub, "call \(index) returns alice's sub")
        }
        XCTAssertEqual(recorder.operations, [], "getCurrentUser reads the saved session")
    }
}
