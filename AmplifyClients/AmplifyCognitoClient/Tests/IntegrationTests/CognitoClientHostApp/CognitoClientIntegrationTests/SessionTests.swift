//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import Security
import XCTest

/// A signed-in session's `fetchAuthSession()` over the live engine: the plugin's `SignedInAuthSessionTests`
/// and its expired-session cases (SE-5), on the default backend with alice, a fresh user each test signs up
/// (`makeSignInUser()`).
final class SessionTests: ClientIntegrationTestCase {

    /// The plugin's `AWSAuthBaseTest.networkTimeout`.
    private static let networkTimeout: TimeInterval = 5

    private var configuration: AmplifyCognitoClientConfiguration!
    /// This test's own user.
    private var alice: TestUser!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
        alice = try await makeSignInUser()
    }

    /// A signed-in session has user pool tokens, an identity and AWS credentials (SE-1; the
    /// plugin's `testSuccessfulSessionFetch`).
    ///
    /// - Given: alice signed in on a fresh session
    /// - When:
    ///    - `fetchAuthSession()`
    /// - Then:
    ///    - every field succeeds: the tokens are alice's (the id token's sub is the session user's), the sub
    ///      matches, and there is an identity and AWS credentials that expire in the future
    ///    - the state is `.signedIn(alice)`
    ///
    func testFetchAuthSessionAfterSignIn() async throws {
        let client = try makeClient("alice")
        _ = try await client.signIn(username: alice.username, password: alice.password)
        let user = try await client.getCurrentUser()

        let session = try await client.fetchAuthSession()

        let tokens = try session.requireUserPoolTokens()
        let claims = try IntegrationTestEnvironment.jwtClaims(tokens.idToken)
        XCTAssertTrue(claims["sub"] as? String == user.userId, "the id token is the session user's")
        XCTAssertTrue(claims["cognito:username"] as? String == alice.username, "the id token names alice")
        XCTAssertTrue(try session.requireUserSub() == user.userId, "the session's sub is the user's")
        XCTAssertFalse(try session.requireIdentityId().isEmpty)
        let credentials = try session.requireAWSCredentials()
        XCTAssertGreaterThan(credentials.expiration, Date())
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
    }

    /// A session whose record was removed out of band reads signed out once reloaded (SE-2; the
    /// plugin's `testSessionCleared`, which clears its keychain service and reloads; the client's store is
    /// the keychain account itself).
    ///
    /// - Given: alice signed in on a session, its refresh token captured (and revoked at teardown, since
    ///   nothing else will), then every handle dropped
    /// - When:
    ///    - the session's keychain account is deleted with a raw `SecItemDelete`, and a new client over the
    ///      same session ID reads it
    /// - Then:
    ///    - the state is `.signedOut`; `getCurrentUser()` and the token provider fail as not signed in
    ///    - `fetchAuthSession()` makes the cleared session a guest, with no user pool tokens or sub (the default
    ///      backend's identity pool allows guests; the plugin reports its tokens as `.signedOut`)
    ///
    func testRecordRemovedOutOfBandReadsSignedOut() async throws {
        let raw = try RawUserPool()
        let sessionId = try makeSessionID("alice-cleared")
        let refreshToken: String
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            _ = try await client.signIn(username: alice.username, password: alice.password)
            refreshToken = try await client.fetchAuthSession().requireUserPoolTokens().refreshToken
        }
        addTeardownBlock { try await raw.revoke(refreshToken) }
        try await SessionCleanup.waitUntilReleased([sessionId])
        let account = SessionRecordKey.account(for: sessionId, in: configuration.poolNamespace, kind: .session)
        XCTAssertTrue(try IntegrationTestEnvironment.rawKeychainAccounts().contains(account), "the sign-in stored the record")

        try Self.deleteKeychainAccount(account)

        let reloaded = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        let state = await reloaded.currentSessionState()
        XCTAssertState(state, .signedOut)
        let userError = await Expect.authClientError("getCurrentUser on a cleared session") {
            try await reloaded.getCurrentUser()
        }
        XCTAssertEqual(userError?.kind, .notSignedIn)
        let tokenError = await Expect.credentialsError("the token provider of a cleared session") {
            try await reloaded.userPoolTokenProvider.accessToken()
        }
        XCTAssertEqual(tokenError?.caseName, "notSignedIn")
        // A cleared session is signed out, so its fetch becomes a guest: the default backend's identity pool
        // allows guests.
        let session = try await reloaded.fetchAuthSession()
        XCTAssertNil(session.userPoolTokens, "a cleared session should hold no user pool tokens")
        XCTAssertNil(session.userSub, "a cleared session should have no user sub")
        XCTAssertNoThrow(try session.requireIdentityId(), "the cleared session's fetch has a guest identity")
        let guest = await reloaded.currentSessionState()
        XCTAssertState(guest, .guest)
    }

    /// A stored session past its expiry, whose refresh token Cognito rejects, reads `.sessionExpired` from a plain
    /// fetch and sends one `.sessionExpired` event (SE-5; the plugin's `testSessionExpired` and
    /// `testSessionExpiredEvent`).
    ///
    /// The plugin's two tests plant the record with `AuthSessionHelper.invalidateSession`: both tokens' `exp`
    /// claims 3,000 s in the past, the stored `expiration` 50,000 s in the past, the refresh token `"invalid"`,
    /// the rest (identity, AWS credentials) unchanged. They then reload the plugin from the keychain and call
    /// `fetchAuthSession()` without forcing a refresh. This plants the same record through `SessionRecordStore`
    /// and reloads with a new client handle over the same session ID.
    ///
    /// - Given: alice signed in on a session, its refresh token captured (and revoked at teardown, since the
    ///   planted record no longer holds it), then every handle dropped; the session's record rewritten as the
    ///   plugin's helper rewrites its own
    /// - When:
    ///    - a new client over the same session ID subscribes to its event stream, then calls
    ///      `fetchAuthSession()` with no options
    /// - Then:
    ///    - the user pool tokens fail with `.sessionExpired` (the plugin's `AuthError.sessionExpired`)
    ///    - the session stays `.signedIn(alice)` (the plugin's "signed in, tokens `sessionExpired`")
    ///    - the event stream delivers `.sessionExpired` within the plugin's `networkTimeout`, and, once the handle
    ///      is released and the stream has finished, nothing more: exactly one event (the plugin's single Hub
    ///      `sessionExpired`)
    ///
    func testExpiredSessionWithARejectedRefreshTokenReadsSessionExpired() async throws {
        let raw = try RawUserPool()
        let sessionId = try makeSessionID("alice-expired")
        let refreshToken: String
        let user: AmplifyCognitoClientUser
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            _ = try await client.signIn(username: alice.username, password: alice.password)
            user = try await client.getCurrentUser()
            refreshToken = try await client.fetchAuthSession().requireUserPoolTokens().refreshToken
        }
        addTeardownBlock { try await raw.revoke(refreshToken) }
        try await SessionCleanup.waitUntilReleased([sessionId])

        let store = SessionRecordStore(namespace: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        guard case .record(let envelope) = try store.read(sessionId) else {
            return XCTFail("the sign-in stored no record")
        }
        var record = envelope.record
        record.credentials = try Self.expiringWithARejectedRefreshToken(XCTUnwrap(record.credentials))
        let planted = try store.write(record, for: sessionId, expecting: envelope.version)
        guard planted.didCommit else {
            return XCTFail("the expired record was not planted: the record moved under the test")
        }

        let events: StreamRecorder<AuthEvent>
        do {
            let reloaded = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            events = StreamRecorder(reloaded.listenToAuthEvents())
            let error = await Expect.authClientError("the fetch of an expired session with a rejected refresh token") {
                try await reloaded.fetchAuthSession()
            }

            XCTAssertEqual(error?.kind, .sessionExpired, "\(String(describing: error?.kind))")
            let state = await reloaded.currentSessionState()
            XCTAssertState(state, .signedIn(user), "an expired session stays signed in as its user")
            try await events.waitUntil("the sessionExpired event", timeout: Self.networkTimeout) {
                $0.contains(.sessionExpired)
            }
        }
        // The handle is gone, so the stream finishes and holds every event it delivered, a late duplicate too.
        let delivered = try await events.waitUntilFinished()
        XCTAssertEqual(delivered, [.sessionExpired], "exactly one sessionExpired event")
    }

    /// `payload` (the plugin's stored credentials) as `AuthSessionHelper.invalidateSession` leaves the plugin's:
    /// the id and access tokens' `exp` claims 3,000 s in the past, `expiration` 50,000 s in the past, and the
    /// refresh token `"invalid"`, which Cognito rejects. The tokens keep their header and signature, which
    /// nothing checks on the device. Everything else, the identity and AWS credentials included, is unchanged.
    private static func expiringWithARejectedRefreshToken(_ payload: Data) throws -> Data {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        let kindKey = try XCTUnwrap(["userPoolAndIdentityPool", "userPoolOnly"].first { json[$0] != nil })
        var kind = try XCTUnwrap(json[kindKey] as? [String: Any])
        var signedIn = try XCTUnwrap(kind["signedInData"] as? [String: Any])
        var tokens = try XCTUnwrap(signedIn["cognitoUserPoolTokens"] as? [String: Any])
        let pastExpiry = Date(timeIntervalSinceNow: -3_000).timeIntervalSince1970
        for key in ["idToken", "accessToken"] {
            tokens[key] = try withExpiry(pastExpiry, XCTUnwrap(tokens[key] as? String))
        }
        tokens["refreshToken"] = "invalid"
        // A default `JSONEncoder`'s date: seconds since the reference date.
        tokens["expiration"] = Date(timeIntervalSinceNow: -50_000).timeIntervalSinceReferenceDate
        signedIn["cognitoUserPoolTokens"] = tokens
        kind["signedInData"] = signedIn
        json[kindKey] = kind
        return try JSONSerialization.data(withJSONObject: json)
    }

    /// `token` with its payload's `exp` claim replaced by `expiry` (seconds since 1970).
    private static func withExpiry(_ expiry: TimeInterval, _ token: String) throws -> String {
        var parts = token.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else {
            throw HarnessError.malformedToken("expected 3 segments, found \(parts.count)")
        }
        var claims = try IntegrationTestEnvironment.jwtClaims(token)
        claims["exp"] = Int(expiry)
        parts[1] = try JSONSerialization.data(withJSONObject: claims).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return parts.joined(separator: ".")
    }

    /// Repeated fetches of a signed-in session are served from the session, with no request
    /// (SE-3; the plugin's `testMultipleSuccessfulSessionFetch`).
    ///
    /// - Given: alice signed in, a first `fetchAuthSession()` made, and the recorder then reset
    /// - When:
    ///    - five more fetches, one after another
    /// - Then:
    ///    - each is signed in with the same access token, identity and AWS credentials as the first
    ///    - the recorder saw no request: nothing was refreshed
    ///
    func testRepeatedFetchesServeTheCachedSession() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("alice-cached", configureUserPoolClient: recorder.configureUserPoolClient)
        _ = try await client.signIn(username: alice.username, password: alice.password)
        let first = try await client.fetchAuthSession()
        let firstToken = try fingerprint(first.requireUserPoolTokens().accessToken)
        let firstIdentity = try first.requireIdentityId()
        let firstKey = try first.requireAWSCredentials().accessKeyId
        recorder.reset()

        for fetch in 1 ... 5 {
            let session = try await client.fetchAuthSession()
            XCTAssertTrue(try fingerprint(session.requireUserPoolTokens().accessToken) == firstToken, "fetch \(fetch): the same tokens")
            XCTAssertTrue(try session.requireIdentityId() == firstIdentity, "fetch \(fetch): the same identity")
            XCTAssertTrue(try session.requireAWSCredentials().accessKeyId == firstKey, "fetch \(fetch): the same credentials")
        }

        XCTAssertEqual(recorder.operations, [], "cached fetches make no request")
    }

    /// Concurrent fetches across a sign-out all return a coherent session (SE-4; the plugin's
    /// `testMultipleParallelSuccessfulSessionFetch`, with its 100 and 50 fetches and its 5-second limit).
    ///
    /// - Given: alice signed in on a session over the default backend (its identity pool allows guests), and
    ///   her identity ID
    /// - When:
    ///    - 100 fetches start, each in its own task (every sixth yields first), and `signOut()` runs among
    ///      them; once it returns, 50 more fetches start
    ///    - all 150 are awaited for at most the plugin's `networkTimeout`, 5 s
    /// - Then:
    ///    - the sign-out is `.complete`, and no fetch throws
    ///    - each of the first 100 has an identity, and its user pool tokens are either alice's or absent (it ran
    ///      after the sign-out, as a guest)
    ///    - none of the last 50 is signed in: each has no user pool tokens, and all 50 share one guest identity,
    ///      which is not alice's
    ///    - the final state is `.guest`: the session is signed out of the user pool, and a fetch on a
    ///      signed-out session with guest access acquires guest credentials (the plugin's "not signed in")
    ///
    func testConcurrentFetchesAcrossASignOut() async throws {
        let client = try makeClient("alice-parallel")
        _ = try await client.signIn(username: alice.username, password: alice.password)
        let user = try await client.getCurrentUser()
        let aliceIdentity = try await client.fetchAuthSession().requireIdentityId()

        let duringCalls = ConcurrentCalls("the fetches across the sign-out", count: 100) { index in
            if (index + 1).isMultiple(of: 6) {
                await Task.yield()
            }
            return try await client.fetchAuthSession()
        }
        await Task.yield()
        // Bounded too, so a sign-out that deadlocks against the fetches fails the test instead of hanging it.
        let signOutCall = ConcurrentCalls("the sign-out", count: 1) { _ in await client.signOut() }
        await fulfillment(of: [signOutCall.expectation], timeout: Self.networkTimeout)
        let signOut = try XCTUnwrap(signOutCall.values().first)
        let afterCalls = ConcurrentCalls("the fetches after the sign-out", count: 50) { _ in
            try await client.fetchAuthSession()
        }
        await fulfillment(of: [duringCalls.expectation, afterCalls.expectation], timeout: Self.networkTimeout)
        let during = try duringCalls.values()
        let after = try afterCalls.values()

        XCTAssertSignOutComplete(signOut)
        XCTAssertEqual(during.count, 100)
        for (index, session) in during.enumerated() {
            XCTAssertNoThrow(try session.requireIdentityId(), "fetch \(index) has an identity")
            if let tokens = session.userPoolTokens {
                let sub = try IntegrationTestEnvironment.jwtClaims(tokens.idToken)["sub"] as? String
                XCTAssertTrue(sub == user.userId, "fetch \(index): signed-in tokens are alice's")
            } else {
                XCTAssertNil(session.userSub, "fetch \(index): a guest has no sub")
            }
        }
        for (index, session) in after.enumerated() {
            XCTAssertNil(session.userPoolTokens, "fetch \(index) after the sign-out is still signed in")
        }
        let guestIdentities = try Set(after.map { try $0.requireIdentityId() })
        XCTAssertEqual(guestIdentities.count, 1, "the fetches after the sign-out share one guest identity")
        XCTAssertFalse(guestIdentities.contains(aliceIdentity), "the guest identity is not alice's")
        let state = await client.currentSessionState()
        XCTAssertState(state, .guest)
    }

    /// Deletes one account of the session service, in every access group, as another process could.
    private static func deleteKeychainAccount(_ account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: IntegrationTestEnvironment.sessionService,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw HarnessError.keychain("SecItemDelete of the session record", status)
        }
    }
}
