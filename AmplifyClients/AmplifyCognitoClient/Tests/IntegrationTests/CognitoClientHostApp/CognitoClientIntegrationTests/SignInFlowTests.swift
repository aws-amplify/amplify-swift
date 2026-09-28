//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import XCTest

/// The single-session cases over the live engine: SI-1, RF-1, CR-1, CR-3 and PS-1.
///
/// RF-1, CR-1 and CR-3, and PS-1 belong with `RefreshTests`, `CredentialsProviderTests` and
/// `PersistenceTests` by topic. They are kept here, with their original test names, because they were
/// written first, with the sign-in they depend on.
final class SignInFlowTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!
    private var users: SandboxUsers!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
        users = try IntegrationTestEnvironment.users()
    }

    private var pools: PoolNamespace {
        configuration.poolNamespace
    }

    /// SRP sign-in of a registered user completes (SI-1).
    ///
    /// - Given: a client on a fresh session ID, the recorder installed, and both of its streams subscribed
    /// - When:
    ///    - alice signs in with her password and default options
    /// - Then:
    ///    - the result is `.done`, and the state is `.signedIn` with username `alice` and the `sub` of her id
    ///      token
    ///    - the event stream delivered `.signedIn` exactly once
    ///    - the keychain holds `amplify.1.<ns>.<sid>.session`, and the sign-in created no plugin
    ///      `amplify.<ns>.session` record
    ///    - the recorder saw `InitiateAuth` with `USER_SRP_AUTH`, then `RespondToAuthChallenge` with
    ///      `PASSWORD_VERIFIER`, each with the Amplify user agent
    ///
    func testSRPSignInForAlice() async throws {
        let sessionId = try makeSessionID("alice")
        let legacyAccount = SessionRecordKey.legacySessionAccount(in: pools)
        let legacyBefore = try IntegrationTestEnvironment.rawKeychainAccounts().contains(legacyAccount)
        let recorder = RecordingHTTPClient()
        let client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )
        let events = StreamCollector(client.listenToAuthEvents())

        let result = try await client.signIn(username: users.alice.username, password: users.alice.password)

        XCTAssertEqual(result.nextStep, .done)
        let idToken = try await client.fetchAuthSession().userPoolTokensResult.get().idToken
        let sub = try XCTUnwrap(IntegrationTestEnvironment.jwtClaims(idToken)["sub"] as? String)
        let state = await client.currentSessionState()
        XCTAssertTrue(
            state == .signedIn(AuthClientUser(username: "alice", userId: sub)),
            "the state should be .signedIn as alice, with her id token's sub"
        )
        try await events.waitFor(1)
        XCTAssertEqual(events.elements, [.signedIn], "one .signedIn, and nothing else")
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertTrue(accounts.contains(SessionRecordKey.account(for: sessionId, in: pools, kind: .session)))
        XCTAssertEqual(accounts.contains(legacyAccount), legacyBefore, "the sign-in wrote no plugin record")
        let signIn = Array(recorder.requests.prefix(2))
        XCTAssertEqual(signIn.map(\.operation), ["InitiateAuth", "RespondToAuthChallenge"])
        XCTAssertEqual(signIn.first?.authFlow, "USER_SRP_AUTH")
        XCTAssertEqual(signIn.last?.challengeName, "PASSWORD_VERIFIER")
        for request in recorder.requests {
            let userAgent = try XCTUnwrap(request.userAgent)
            XCTAssertTrue(userAgent.contains("lib/amplify-swift#"), "no Amplify lib token")
            XCTAssertTrue(userAgent.contains("md/amplify-cognito"), "no amplify-cognito metadata")
        }
        events.stop()
    }

    /// A forced refresh commits new tokens, with one network refresh and no event (RF-1).
    ///
    /// - Given: alice signed in, the recorder reset, and the event stream subscribed
    /// - When:
    ///    - two unforced `fetchAuthSession()` calls, then `fetchAuthSession(forceRefresh: true)`, then an
    ///      unforced one, then every handle is dropped and a new one reads the record
    /// - Then:
    ///    - as the plugin's `testSuccessfulForceSessionFetch` compares whole sessions: the two unforced fetches
    ///      return the same session with no request, the forced one a different session, and the unforced
    ///      fetch after it the forced one's session, from the cache
    ///    - the new access token has a different `jti` and an `iat` no earlier than the old one's
    ///    - the recorder saw exactly `GetTokensFromRefreshToken`; the state stays `.signedIn(alice)`; no event
    ///    - the new handle, over the restored record, holds the new token
    ///
    func testForcedRefreshCommitsNewTokens() async throws {
        let sessionId = try makeSessionID("alice")
        let committed = try await refreshAndDrop(sessionId)
        try await SessionCleanup.waitUntilReleased([sessionId])

        let reread = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        let restored = try await reread.fetchAuthSession().userPoolTokensResult.get().accessToken

        XCTAssertTrue(fingerprint(restored) == committed, "a new handle should read the committed token")
    }

    /// Signs alice in, forces a refresh with the recorder and the event stream watching, asserts RF-1's
    /// in-session half, and returns the new access token's fingerprint. The client is released on return.
    private func refreshAndDrop(_ sessionId: SessionID) async throws -> String {
        let recorder = RecordingHTTPClient()
        let client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)
        let user = try await client.getCurrentUser()
        recorder.reset()
        let events = StreamCollector(client.listenToAuthEvents())
        let first = try await client.fetchAuthSession()
        let second = try await client.fetchAuthSession()
        XCTAssertTrue(first == second, "unforced fetches return the same session")
        XCTAssertEqual(recorder.operations, [], "unforced fetches of fresh tokens make no request")

        let forced = try await client.fetchAuthSession(options: .init(forceRefresh: true))
        let cached = try await client.fetchAuthSession()

        XCTAssertFalse(second == forced, "a forced refresh should return a new session")
        XCTAssertTrue(forced == cached, "an unforced fetch after the refresh should serve the refreshed session")
        let before = try second.userPoolTokensResult.get().accessToken
        let after = try forced.userPoolTokensResult.get().accessToken
        let beforeClaims = try IntegrationTestEnvironment.jwtClaims(before)
        let afterClaims = try IntegrationTestEnvironment.jwtClaims(after)
        XCTAssertFalse(fingerprint(before) == fingerprint(after), "a forced refresh should mint a new access token")
        let beforeJti = try XCTUnwrap(beforeClaims["jti"] as? String, "the old access token has no jti")
        let afterJti = try XCTUnwrap(afterClaims["jti"] as? String, "the new access token has no jti")
        XCTAssertTrue(beforeJti != afterJti, "the refreshed access token should have a new jti")
        XCTAssertGreaterThanOrEqual(afterClaims["iat"] as? Int ?? 0, beforeClaims["iat"] as? Int ?? .max)
        XCTAssertEqual(recorder.operations, ["GetTokensFromRefreshToken"])
        let state = await client.currentSessionState()
        XCTAssertTrue(state == .signedIn(user), "the state should stay .signedIn as alice")
        XCTAssertEqual(events.elements, [], "a refresh emits no event")
        events.stop()
        return fingerprint(after)
    }

    /// A fresh session acquires guest credentials, and the provider signs as the unauthenticated role
    /// (CR-3).
    ///
    /// - Given: a client on a fresh session with no sign-in
    /// - When:
    ///    - `fetchAuthSession()` acquires guest credentials, and the provider signs `GetCallerIdentity`
    /// - Then:
    ///    - the state is `.guest`, `identityIdResult` succeeds, and the stored row's kind is `.guest`
    ///    - the session is not signed in: it carries no user pool tokens (the plugin's
    ///      `SignedOutAuthSessionTests.testSuccessfulSessionFetch` checks `isSignedIn == false`)
    ///    - the provider resolves the session's own credentials (the same access key ID)
    ///    - `GetCallerIdentity` answers as the unauthenticated role
    ///
    func testGuestCredentials() async throws {
        let region = try XCTUnwrap(configuration.identityPool).region
        let sessionId = try makeSessionID("guest")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))

        let session = try await client.fetchAuthSession()

        let state = await client.currentSessionState()
        XCTAssertTrue(state == .guest, "the session is a guest")
        XCTAssertNoThrow(try session.identityIdResult.get())
        XCTAssertThrowsError(try session.userPoolTokensResult.get(), "a guest session has no user pool tokens")
        let resolved = try await client.credentialsProvider.resolve()
        let guestKey = try session.awsCredentialsResult.get().accessKeyId
        XCTAssertTrue(resolved.accessKeyId == guestKey, "the provider should resolve the session's own credentials")
        let identity = try await CallerIdentity.of(client.credentialsProvider, region: region)
        let role = try XCTUnwrap(CallerIdentity.roleName(of: try XCTUnwrap(identity.arn)))
        XCTAssertTrue(role.hasSuffix("-unauthenticated"), "a guest signs as the unauthenticated role")
        let stored = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertEqual(stored.first { $0.sessionId == sessionId }?.kind, .guest)
    }

    /// The credentials provider resolves the signed-in user's identity-pool credentials (CR-1).
    ///
    /// - Given: alice signed in
    /// - When:
    ///    - her provider resolves, and signs an STS `GetCallerIdentity`
    /// - Then:
    ///    - it resolves the session's own credentials (the same access key ID), expiring in the future
    ///    - `GetCallerIdentity` answers as the authenticated role
    ///
    func testCredentialsProviderResolvesIdentityPoolCredentials() async throws {
        let region = try XCTUnwrap(configuration.identityPool).region
        let sessionId = try makeSessionID("alice")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)

        let resolved = try await client.credentialsProvider.resolve()
        let identity = try await CallerIdentity.of(client.credentialsProvider, region: region)

        let session = try await client.fetchAuthSession()
        let sessionKey = try session.awsCredentialsResult.get().accessKeyId
        XCTAssertTrue(resolved.accessKeyId == sessionKey, "the provider should resolve the session's own credentials")
        let expiration = try XCTUnwrap((resolved as? any AWSTemporaryCredentials)?.expiration)
        XCTAssertGreaterThan(expiration, Date())
        let role = try XCTUnwrap(CallerIdentity.roleName(of: try XCTUnwrap(identity.arn)))
        XCTAssertTrue(role.hasSuffix("-authenticated"), "a signed-in user signs as the authenticated role")
    }

    /// A signed-in session restores across a client re-creation, with no network call, both when the app's
    /// outputs changed in a way that does not touch its pools and when they did not change at all
    /// (PS-1; the plugin's `testCredentialsMigrationDoesntHappenOnNoConfigurationChange`,
    /// `testCredentialClearingOnAppReinstall` and `testNonSharedKeychainCredentialsClearedOnFreshInstall`).
    ///
    /// - Given: alice signed in, her session fetched, then every handle dropped and the registry emptied for
    ///   the session
    /// - When:
    ///    - a new client with the same ID, over the same outputs plus unrelated sections (analytics,
    ///      notifications, custom), reads its state and session; it is dropped and the registry emptied
    ///    - a new client with the same ID, over the unchanged configuration, does the same, then forces a
    ///      refresh
    /// - Then:
    ///    - each time, the state is `.signedIn(alice)`, and the session holds the same tokens, identity ID and
    ///      AWS credentials as before the drop, with no request (the plugin compares the identity ID and the
    ///      credentials)
    ///    - the forced refresh then succeeds with the restored refresh token
    ///
    func testRestoreAcrossClientRecreation() async throws {
        let sessionId = try makeSessionID("alice")
        // The sign-in client goes out of scope at the end of this call, so no handle keeps the session live.
        let stored = try await signInAndDrop(sessionId)
        try await SessionCleanup.waitUntilReleased([sessionId])
        let changed = try Self.withUnrelatedSections(IntegrationTestEnvironment.data(forResource: IntegrationTestEnvironment.outputsResource))

        try await assertRestores(sessionId, as: stored, through: changed)
        try await SessionCleanup.waitUntilReleased([sessionId])
        let recorder = try await assertRestores(sessionId, as: stored, through: configuration) { client in
            _ = try await client.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get()
        }

        XCTAssertEqual(recorder.operations, ["GetTokensFromRefreshToken"], "the restored refresh token refreshes")
    }

    /// Opens `sessionId` through a new client over `outputs`, and asserts it restores `.signedIn(alice)`
    /// and `stored`, with no request. Then runs `then`, and returns the recorder. The client is released on
    /// return.
    @discardableResult
    private func assertRestores(
        _ sessionId: SessionID,
        as stored: AuthClientSession,
        through outputs: AuthClientConfiguration,
        then: (AmplifyCognitoClient) async throws -> Void = { _ in }
    ) async throws -> RecordingHTTPClient {
        let recorder = RecordingHTTPClient()
        let reread = try AmplifyCognitoClient(
            configuration: outputs,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )
        let user = try await reread.getCurrentUser()

        XCTAssertEqual(user.username, "alice")
        let state = await reread.currentSessionState()
        XCTAssertTrue(state == .signedIn(user), "the restored state should be .signedIn as alice")
        let restored = try await reread.fetchAuthSession()
        XCTAssertTrue(
            try restored.identityIdResult.get() == stored.identityIdResult.get(),
            "the restored identity ID should be the stored one"
        )
        XCTAssertTrue(
            try restored.awsCredentialsResult.get() == stored.awsCredentialsResult.get(),
            "the restored AWS credentials should be the stored ones"
        )
        XCTAssertTrue(restored == stored, "the restored session should be the stored one, tokens included")
        XCTAssertEqual(recorder.operations, [], "restoring and reading the session make no user pool request")
        recorder.reset()
        try await then(reread)
        return recorder
    }

    /// The outputs with sections added that an auth client does not read: what changes when an app adds
    /// another category, and must not touch a stored session.
    private static func withUnrelatedSections(_ outputs: Data) throws -> AuthClientConfiguration {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: outputs) as? [String: Any])
        json["analytics"] = ["amazon_pinpoint": ["aws_region": "us-east-1", "app_id": "unrelated-app"]]
        json["notifications"] = ["aws_region": "us-east-1", "amazon_pinpoint_app_id": "unrelated-app", "channels": ["APNS"]]
        json["custom"] = ["note": "changed after the sign-in"]
        return try AuthClientConfiguration(
            outputsData: JSONSerialization.data(withJSONObject: json),
            resourceName: IntegrationTestEnvironment.outputsResource
        )
    }

    /// Signs alice in on `sessionId` through a client that is released when this returns, and returns her
    /// session, which holds an identity ID and AWS credentials.
    private func signInAndDrop(_ sessionId: SessionID) async throws -> AuthClientSession {
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)
        let session = try await client.fetchAuthSession()
        XCTAssertNoThrow(try session.identityIdResult.get(), "the signed-in session has an identity ID")
        XCTAssertNoThrow(try session.awsCredentialsResult.get(), "the signed-in session has AWS credentials")
        return session
    }
}
