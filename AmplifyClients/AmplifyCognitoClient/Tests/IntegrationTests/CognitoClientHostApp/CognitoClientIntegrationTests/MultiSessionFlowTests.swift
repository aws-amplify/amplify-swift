//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// The multi-session flows this harness exists for, over the live engine: MS-1, MS-3,
/// MS-4 and MS-5 (MS-2 and MS-6 are in the `+SignOut` and `+SameUser` extensions). Each runs against
/// `alice` and `bob` from
/// `IntegrationTestEnvironment.users()`, on the real keychain and the sandbox.
final class MultiSessionFlowTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!
    private var users: SandboxUsers!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
        users = try IntegrationTestEnvironment.users()
    }

    private func account(_ sessionId: SessionID) -> String {
        SessionRecordKey.account(for: sessionId, in: configuration.poolNamespace, kind: .session)
    }

    /// Two users signed in at once hold independent sessions (MS-1).
    ///
    /// - Given: Two clients over one configuration, `alice`'s and `bob`'s, with their state streams subscribed
    /// - When:
    ///    - Both sign in concurrently
    /// - Then:
    ///    - Each `getCurrentUser()` reports its own user; the two `sub`s differ
    ///    - Each record sits under its own `amplify.1.<ns>.<sessionId>.session` account, and each decodes to
    ///      its own user
    ///    - Neither session's state stream carried the other's transitions
    ///
    func testTwoUsersSignedInConcurrently() async throws {
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let alice = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
        let bob = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bobId))
        let aliceStates = StreamCollector(alice.listenToSessionStateChanges())
        let bobStates = StreamCollector(bob.listenToSessionStateChanges())

        let aliceUserRecord = users.alice
        let bobUserRecord = users.bob
        async let aliceSignIn = alice.signIn(username: aliceUserRecord.username, password: aliceUserRecord.password)
        async let bobSignIn = bob.signIn(username: bobUserRecord.username, password: bobUserRecord.password)
        let (aliceResult, bobResult) = try await (aliceSignIn, bobSignIn)

        XCTAssertEqual(aliceResult.nextStep, .done)
        XCTAssertEqual(bobResult.nextStep, .done)
        let aliceUser = try await alice.getCurrentUser()
        let bobUser = try await bob.getCurrentUser()
        XCTAssertEqual(aliceUser.username, "alice")
        XCTAssertEqual(bobUser.username, "bob")
        XCTAssertTrue(aliceUser.userId != bobUser.userId, "alice's and bob's subs should differ")

        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertTrue(accounts.contains(account(aliceId)))
        XCTAssertTrue(accounts.contains(account(bobId)))
        let store = SessionRecordStore(namespace: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        for (sessionId, user) in [(aliceId, aliceUser), (bobId, bobUser)] {
            guard case .record(let envelope) = try store.read(sessionId) else {
                return XCTFail("no record for \(user.username)'s session")
            }
            XCTAssertEqual(envelope.record.username, user.username)
            XCTAssertTrue(envelope.record.userId == user.userId, "\(user.username)'s record names another user")
            // The credentials themselves, decoded: their id token is this user's.
            let payload = try XCTUnwrap(envelope.record.credentials)
            let sub = try IntegrationTestEnvironment.jwtClaims(Self.idToken(in: payload))["sub"] as? String
            XCTAssertTrue(sub == user.userId, "\(user.username)'s record holds another user's credentials")
        }

        try await aliceStates.waitFor(1)
        try await bobStates.waitFor(1)
        XCTAssertTrue(aliceStates.elements.contains(.signedIn(aliceUser)))
        XCTAssertFalse(aliceStates.elements.contains(.signedIn(bobUser)), "bob's sign-in reached alice's stream")
        XCTAssertTrue(bobStates.elements.contains(.signedIn(bobUser)))
        XCTAssertFalse(bobStates.elements.contains(.signedIn(aliceUser)), "alice's sign-in reached bob's stream")
        aliceStates.stop()
        bobStates.stop()
    }

    /// Signing out keeps the stored row; an opt-in purge removes it (MS-3).
    ///
    /// - Given: alice and bob both signed in
    /// - When:
    ///    - alice signs out with default options
    ///    - then alice signs in again and signs out with `purgeStoredSession: true`
    /// - Then:
    ///    - after the first sign-out, `storedSessions(includingSignedOut: true)` still lists alice's ID, with
    ///      `kind == .signedOut` and `username == "alice"`; the default listing hides it; bob still resolves
    ///      credentials
    ///    - after the purge, the row is gone from both listings, and the raw keychain has no account for it
    ///
    func testSignOutKeepsStoredRow() async throws {
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let alice = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
        let bob = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bobId))
        _ = try await alice.signIn(username: users.alice.username, password: users.alice.password)
        _ = try await bob.signIn(username: users.bob.username, password: users.bob.password)

        let signOut = try await alice.signOut()

        XCTAssertEqual(signOut, .complete)
        let aliceState = await alice.currentSessionState()
        XCTAssertEqual(aliceState, .signedOut)
        let withSignedOut = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        let aliceRow = try XCTUnwrap(withSignedOut.first { $0.sessionId == aliceId })
        XCTAssertEqual(aliceRow.kind, SessionKind.signedOut)
        XCTAssertEqual(aliceRow.username, "alice")
        let withoutSignedOut = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertFalse(withoutSignedOut.contains { $0.sessionId == aliceId }, "a signed-out row is hidden by default")
        _ = try await bob.credentialsProvider.resolve()

        _ = try await alice.signIn(username: users.alice.username, password: users.alice.password)
        _ = try await alice.signOut(options: .init(purgeStoredSession: true))

        let afterPurge = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(afterPurge.contains { $0.sessionId == aliceId }, "the purged row is gone")
        let defaultListing = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertFalse(defaultListing.contains { $0.sessionId == aliceId })
        XCTAssertFalse(try IntegrationTestEnvironment.rawKeychainAccounts().contains(account(aliceId)))
        XCTAssertTrue(afterPurge.contains { $0.sessionId == bobId }, "bob's row is untouched")
    }

    /// `storedSessions()` lists every stored session from the real keychain, with its label, and without a
    /// network call; the plugin's own record adds no session of ours (MS-4).
    ///
    /// - Given: alice and bob signed in under two session IDs, alice labelled `"Work"`, every handle then
    ///   dropped, and a plugin record (`amplify.<ns>.session`) written into the same keychain service
    /// - When:
    ///    - `storedSessions()` reads the keychain, with no live session for either
    /// - Then:
    ///    - both session IDs are listed, alice with the label `"Work"`, each naming its user
    ///    - every listed ID is a v1 `amplify.1.` record's, or `.default`, which reads through to the plugin's
    ///      record; the plugin's account is never a session ID of its own
    ///    - no request is sent: structurally, since no handle is live and the listing reads only the
    ///      keychain; the recorder the handles used confirms it saw nothing
    ///
    func testStoredSessionsListsEverySession() async throws {
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let recorder = RecordingHTTPClient()
        try await signIn(aliceId, as: users.alice, label: "Work", recorder: recorder)
        try await signIn(bobId, as: users.bob, label: nil, recorder: recorder)
        try await SessionCleanup.waitUntilReleased([aliceId, bobId])
        recorder.reset()
        let legacyAccount = SessionRecordKey.legacySessionAccount(in: configuration.poolNamespace)
        let legacyWritten = try !IntegrationTestEnvironment.rawKeychainAccounts().contains(legacyAccount)
        if legacyWritten {
            let status = RealKeychain.add(
                #"{"userPoolOnly":{"signedInData":{"username":"legacy-probe"}}}"#,
                account: legacyAccount,
                service: IntegrationTestEnvironment.sessionService
            )
            XCTAssertEqual(status, errSecSuccess, "could not write the plugin record")
        }
        defer {
            if legacyWritten {
                Self.removeRawAccount(legacyAccount)
            }
        }

        let stored = try await AmplifyCognitoClient.storedSessions(configuration: configuration)

        XCTAssertEqual(recorder.requests, [], "listing sessions makes no network call")
        let byId = Dictionary(uniqueKeysWithValues: stored.map { ($0.sessionId, $0) })
        XCTAssertEqual(byId[aliceId]?.username, "alice")
        XCTAssertEqual(byId[aliceId]?.label, "Work")
        XCTAssertEqual(byId[bobId]?.username, "bob")
        XCTAssertNil(byId[bobId]?.label)
        let v1Ids = try Set(IntegrationTestEnvironment.rawKeychainAccounts().compactMap { account -> SessionID? in
            guard let parsed = SessionRecordKey.parse(account), parsed.kind == .session,
                  parsed.namespaceComponent == configuration.poolNamespace.keyComponent else {
                return nil
            }
            return parsed.sessionId
        })
        for row in stored {
            XCTAssertTrue(
                v1Ids.contains(row.sessionId) || row.sessionId == .default,
                "a listed session came from neither a v1 record nor .default's read-through"
            )
        }
    }

    /// Deletes one raw account from the session records' service.
    private static func removeRawAccount(_ account: String) {
        var query = KeychainItemAttributes(service: IntegrationTestEnvironment.sessionService).defaultGetQuery()
        query[kSecAttrAccount as String] = account
        let status = SecItemDelete(query as CFDictionary)
        XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound, "could not remove the plugin record")
    }

    /// Signs `user` in on `sessionId`, labels it, and releases the client on return.
    private func signIn(_ sessionId: SessionID, as user: TestUser, label: String?, recorder: RecordingHTTPClient) async throws {
        let client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )
        _ = try await client.signIn(username: user.username, password: user.password)
        if let label {
            try await client.setSessionLabel(label)
        }
    }

    /// Each session's credentials provider resolves that session's own credentials (MS-5).
    ///
    /// - Given: alice and bob signed in
    /// - When:
    ///    - each client's `credentialsProvider` resolves, and signs an STS `GetCallerIdentity`
    /// - Then:
    ///    - each provider resolves its own session's credentials (the same access key ID as its session),
    ///      and alice's and bob's differ; their identity-pool identities differ
    ///    - both sign as the authenticated role (STS names the role, not the identity, so the identities are
    ///      compared through the sessions)
    ///    - after bob signs out, alice's provider still resolves, and bob's throws `notSignedIn` rather
    ///      than falling back to guest
    ///
    func testCredentialsProviderPerSession() async throws {
        let region = try XCTUnwrap(configuration.identityPool).region
        let aliceId = try makeSessionID("alice")
        let bobId = try makeSessionID("bob")
        let alice = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
        let bob = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: bobId))
        _ = try await alice.signIn(username: users.alice.username, password: users.alice.password)
        _ = try await bob.signIn(username: users.bob.username, password: users.bob.password)

        let aliceSession = try await alice.fetchAuthSession()
        let bobSession = try await bob.fetchAuthSession()
        let aliceResolved = try await alice.credentialsProvider.resolve()
        let bobResolved = try await bob.credentialsProvider.resolve()

        let aliceKey = try aliceSession.awsCredentialsResult.get().accessKeyId
        let bobKey = try bobSession.awsCredentialsResult.get().accessKeyId
        XCTAssertTrue(aliceResolved.accessKeyId == aliceKey, "alice's provider should resolve her session's credentials")
        XCTAssertTrue(bobResolved.accessKeyId == bobKey, "bob's provider should resolve his session's credentials")
        XCTAssertTrue(aliceResolved.accessKeyId != bobResolved.accessKeyId, "alice's and bob's credentials should differ")
        let aliceIdentity = try aliceSession.identityIdResult.get()
        let bobIdentity = try bobSession.identityIdResult.get()
        XCTAssertTrue(aliceIdentity != bobIdentity, "alice's and bob's identities should differ")
        for client in [alice, bob] {
            let identity = try await CallerIdentity.of(client.credentialsProvider, region: region)
            let role = try XCTUnwrap(CallerIdentity.roleName(of: try XCTUnwrap(identity.arn)))
            XCTAssertTrue(role.hasSuffix("-authenticated"), "a signed-in session signs as the authenticated role")
        }

        _ = try await bob.signOut()

        _ = try await CallerIdentity.of(alice.credentialsProvider, region: region)
        await assertResolveThrowsNotSignedIn(bob)
    }

    /// The id token in a stored credentials payload (the plugin's `AmplifyCredentials` format), read without
    /// the engine: `userPoolAndIdentityPool` or `userPoolOnly` → `signedInData.cognitoUserPoolTokens.idToken`.
    static func idToken(in payload: Data) throws -> String {
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        let kind = try XCTUnwrap((json["userPoolAndIdentityPool"] ?? json["userPoolOnly"]) as? [String: Any])
        let signedIn = try XCTUnwrap(kind["signedInData"] as? [String: Any])
        let tokens = try XCTUnwrap(signedIn["cognitoUserPoolTokens"] as? [String: Any])
        return try XCTUnwrap(tokens["idToken"] as? String)
    }

    private func assertResolveThrowsNotSignedIn(
        _ client: AmplifyCognitoClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await client.credentialsProvider.resolve()
            XCTFail("a signed-out session must not resolve credentials", file: file, line: line)
        } catch let error as CredentialsError {
            guard case .notSignedIn = error else {
                return XCTFail("expected notSignedIn, got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("expected CredentialsError.notSignedIn, got \(error)", file: file, line: line)
        }
    }
}
