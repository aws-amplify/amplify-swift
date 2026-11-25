//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `StoredSession.state`: the state a row reports for each thing a session can have saved, read offline, and the
/// same state a client built for the session restores to.
final class StoredSessionStateTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")
    private let step = AuthClientSignInStep.confirmSignInWithTOTPCode
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Fixtures

    private func rows(includingSignedOut: Bool = true) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: includingSignedOut,
            dependencies: harness.dependencies
        )
    }

    /// The state a client built for the session reports once it has restored.
    private func restoredState(_ sessionId: SessionID) async throws -> AuthSessionState {
        try await harness.client(sessionId).currentSessionState()
    }

    /// Saves an interrupted sign-in waiting on `step` for the session, `age` seconds before the harness's clock.
    private func saveChallenge(for sessionId: SessionID, age: TimeInterval = 0) throws {
        let record = ChallengeRecord(createdAt: TestClock.start.addingTimeInterval(-age), state: .fake(step)!)
        try harness.store().putChallenge(record, for: sessionId)
    }

    // MARK: A row per state

    /// - Given: a session signed in with AWS credentials, one signed in with user pool tokens only, and one whose
    ///   record keeps no user ID, so its user is read from its credentials
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - the rows are `.signedIn` with their user, with the kinds they had
    ///    - each is the state its client restores to
    func testASignedInRowIsSignedInWithOrWithoutAWSCredentials() async throws {
        let bob = AuthClientUser(username: "bob", userId: "sub-bob")
        let carol = AuthClientUser(username: "carol", userId: "sub-carol")
        let old = ClientFixtures.id("old")
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob", kind: .userPoolOnly))
        try harness.store().write(FakePayload.signedIn("carol").record(includeUserId: false), for: old, expecting: nil)

        let listed = try await rows()

        XCTAssertEqual(listed, [
            StoredSession(sessionId: home, label: nil, user: bob, kind: .userPoolOnly, state: .signedIn(bob)),
            StoredSession(sessionId: old, label: nil, user: carol, kind: .userPoolAndIdentityPool, state: .signedIn(carol)),
            StoredSession(sessionId: work, label: nil, user: alice, kind: .userPoolAndIdentityPool, state: .signedIn(alice))
        ])
        for row in listed {
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
    }

    /// - Given: a guest session and a federated session
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - the rows are `.guest` and `.federated` with the saved identity, with no user
    ///    - each is the state its client restores to
    func testGuestAndFederatedRowsReportTheirState() async throws {
        try harness.signIn(work, .guest())
        try harness.signIn(home, .federated(identityId: "us-east-1:federated"))

        let listed = try await rows()

        XCTAssertEqual(listed, [
            StoredSession(sessionId: home, label: nil, user: nil, kind: .federated, state: .federated(identityId: "us-east-1:federated")),
            StoredSession(sessionId: work, label: nil, user: nil, kind: .guest, state: .guest)
        ])
        for row in listed {
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
    }

    /// - Given: a session signed out, its row kept
    /// - When: the saved sessions are listed with and without signed-out rows
    /// - Then:
    ///    - the row is `.signedOut` with its last user, and only `includingSignedOut: true` lists it
    func testASignedOutRowIsSignedOutAndHiddenByDefault() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        XCTAssertEqual(try harness.store().signOut(work), .signedOut)

        let all = try await rows()
        let byDefault = try await rows(includingSignedOut: false)

        XCTAssertEqual(all, [StoredSession(sessionId: work, label: "Work", user: alice, kind: .signedOut, state: .signedOut)])
        XCTAssertEqual(byDefault, [])
    }

    /// A row that needs action is never hidden.
    ///
    /// - Given: a signed-out row and a guest session, each with a sign-in saved while it waited on a challenge
    /// - When: the saved sessions are listed without signed-out rows
    /// - Then:
    ///    - both rows are `.awaitingChallenge` with the saved step, with the kinds, label and last user they had
    ///    - each is the state its client restores to
    func testASignedOutOrGuestRowWithAPendingChallengeIsAwaitingChallenge() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        XCTAssertEqual(try harness.store().signOut(work), .signedOut)
        try harness.signIn(home, .guest())
        try saveChallenge(for: work)
        try saveChallenge(for: home)

        let listed = try await rows(includingSignedOut: false)

        XCTAssertEqual(listed, [
            StoredSession(sessionId: home, label: nil, user: nil, kind: .guest, state: .awaitingChallenge(step)),
            StoredSession(sessionId: work, label: "Work", user: alice, kind: .signedOut, state: .awaitingChallenge(step))
        ])
        for row in listed {
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
    }

    /// A first sign-in interrupted at a challenge has no session record: the picker can still offer to finish it.
    ///
    /// - Given: a named session and `.default`, each with nothing saved but a sign-in waiting on a challenge
    /// - When: the saved sessions are listed without signed-out rows
    /// - Then:
    ///    - each is a row, `.awaitingChallenge` with the saved step, with no label or user and kind `.signedOut`
    ///    - a client built with the row's session ID restores to the same state, so `confirmSignIn` can answer it
    ///    - nothing is written
    func testASessionWithOnlyAPendingChallengeIsListedAsAwaitingChallenge() async throws {
        try saveChallenge(for: work)
        try saveChallenge(for: .default)
        harness.keychain.resetLogs()

        let listed = try await rows(includingSignedOut: false)

        XCTAssertEqual(listed, [
            StoredSession(sessionId: .default, label: nil, user: nil, kind: .signedOut, state: .awaitingChallenge(step)),
            StoredSession(sessionId: work, label: nil, user: nil, kind: .signedOut, state: .awaitingChallenge(step))
        ])
        XCTAssertFalse(harness.keychain.hasMutations)
        for row in listed {
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
    }

    /// The listing resumes a saved sign-in only where a restore would.
    ///
    /// - Given: a signed-in session with a leftover challenge record; and sessions with nothing saved but a challenge
    ///   record that is 15 minutes and a second old, corrupt, written by a newer schema, or one the live engine
    ///   cannot resume (a sign-in flow this build does not know)
    /// - When: the saved sessions are listed, signed-out rows included
    /// - Then:
    ///    - the signed-in row stays `.signedIn`, and none of the other four is a row
    ///    - only the expired record is deleted
    func testAChallengeARestoreWouldNotResumeIsNotListed() async throws {
        let (expired, corrupt, newer) = (ClientFixtures.id("expired"), ClientFixtures.id("corrupt"), ClientFixtures.id("newer"))
        let unresumable = ClientFixtures.id("unresumable")
        let unknownFlow = try XCTUnwrap(ChallengeRecord.State.fake(step, signInMethod: .init(authFlow: "aNewerFlow")))
        let store = harness.store()
        try harness.signIn(work, .signedIn("alice"))
        try saveChallenge(for: work)
        try saveChallenge(for: expired, age: ChallengeRecord.ceiling + 1)
        try store.putChallengeBytes(Data("corrupt".utf8), for: corrupt)
        try store.putChallengeBytes(Data(#"{"schemaVersion":2,"createdAt":0}"#.utf8), for: newer)
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: unknownFlow), for: unresumable)

        let listed = try await rows()

        XCTAssertEqual(listed, [
            StoredSession(sessionId: work, label: nil, user: alice, kind: .userPoolAndIdentityPool, state: .signedIn(alice))
        ])
        XCTAssertEqual(try store.readChallenge(expired), .absent)
        XCTAssertEqual(try store.readChallenge(corrupt), .corrupt)
        XCTAssertEqual(try store.readChallenge(newer), .unsupportedSchema(version: 2))
        XCTAssertNotEqual(try store.readChallenge(work), .absent)
        XCTAssertNotEqual(try store.readChallenge(unresumable), .absent)
        let resumed = try await LiveEngineHarness().engine().resumeSignIn(from: unknownFlow, epoch: 1)
        XCTAssertNil(resumed, "the live engine does not resume it either")
    }

    /// `.default` keeps its interrupted sign-in beside the Auth plugin's record.
    ///
    /// - Given: `.default` with a sign-in saved while it waited on a challenge, over the plugin's signed-out record,
    ///   over the client's saved label and last user with no plugin record, and over the plugin's guest record
    /// - When: the saved sessions are listed without signed-out rows
    /// - Then:
    ///    - each is listed as `.awaitingChallenge` with the saved step, with the kind, label and user it had
    ///    - each is the state its client restores to
    func testTheDefaultRowWithAPendingChallengeIsAwaitingChallenge() async throws {
        let sidecar = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Home", username: "alice", userId: "sub-alice").encoded()
        let cases: [(String, Data?, Data?, StoredSession)] = [
            ("signed out", PluginRecordFixtures.noCredentials, nil, row(.default, kind: .signedOut)),
            ("no record", nil, sidecar, StoredSession(sessionId: .default, label: "Home", user: alice, kind: .signedOut, state: .awaitingChallenge(step))),
            ("a guest", FakePayload.guest().data, nil, row(.default, kind: .guest))
        ]
        for (name, record, meta, expected) in cases {
            await harness.waitForBaseline()
            harness = ClientHarness()
            if let record {
                harness.keychain.put(record, pluginAccount)
            }
            if let meta {
                harness.keychain.put(meta, SessionRecordKey.metaAccount(in: StorageFixtures.pools))
            }
            try saveChallenge(for: .default)

            let listed = try await rows(includingSignedOut: false)

            XCTAssertEqual(listed, [expected], name)
            let restored = try await restoredState(.default)
            XCTAssertEqual(restored, expected.state, name)
        }
    }

    /// An `.awaitingChallenge` row with nothing but its kind.
    private func row(_ sessionId: SessionID, kind: SessionKind) -> StoredSession {
        StoredSession(sessionId: sessionId, label: nil, user: nil, kind: kind, state: .awaitingChallenge(step))
    }

    /// A row a picker used to drop silently: it can now offer to sign the session out, which resets it.
    ///
    /// - Given: a session whose record a newer version of the app saved, one whose record is corrupt, and `.default`
    ///   over a plugin record that is not the plugin's format
    /// - When: the saved sessions are listed without signed-out rows
    /// - Then:
    ///    - each is a row, `.failed(.unknown)`, with no label or user and kind `.userPoolOnly`
    ///    - each is the state, and so the error, its client restores to
    ///    - no record is written or deleted
    func testARecordThisBuildCannotReadIsAFailedRow() async throws {
        let store = harness.store()
        harness.keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: work))
        harness.keychain.put(StorageFixtures.corruptRecord, store.sessionAccount(for: home))
        harness.keychain.put(Data("not json".utf8), pluginAccount)
        harness.keychain.resetLogs()

        let listed = try await rows(includingSignedOut: false)

        XCTAssertEqual(listed.map(\.sessionId), [.default, home, work])
        XCTAssertFalse(harness.keychain.hasMutations)
        for row in listed {
            XCTAssertEqual([row.label, row.user?.username], [nil, nil], "\(row.sessionId)")
            XCTAssertEqual(row.kind, .userPoolOnly, "\(row.sessionId)")
            guard case .failed(.unknown) = row.state else {
                XCTFail("\(row.sessionId) is \(row.state)")
                continue
            }
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
        XCTAssertNotEqual(listed.first?.state, listed.last?.state, "the two errors say what each record is")
    }

    /// A record a client can read but not use is a `.failed` row that keeps the record's label and kind, in the
    /// state its client restores to.
    ///
    /// - Given: a signed-in record with no user ID whose credentials cannot be decoded, and a signed-in record with a
    ///   user and no credentials
    /// - When: the saved sessions are listed without signed-out rows
    /// - Then:
    ///    - each is a row, `.failed(.unknown)`, with the record's label and kind; the first has no user, the second
    ///      the record's
    ///    - each is the state, and so the error, its client restores to, and the two errors differ
    func testAReadableRecordAClientCannotUseIsFailedAsItsClientRestores() async throws {
        let inconsistent = SessionRecord(label: "Work", username: "alice", userId: "sub-alice", kind: .userPoolOnly, credentials: nil)
        try harness.store().write(StorageFixtures.signedIn(label: "Home"), for: home, expecting: nil)
        try harness.store().write(inconsistent, for: work, expecting: nil)

        let listed = try await rows(includingSignedOut: false)

        XCTAssertEqual(listed.map(\.sessionId), [home, work])
        XCTAssertEqual(listed.map(\.label), ["Home", "Work"])
        XCTAssertEqual(listed.map(\.kind), [.userPoolAndIdentityPool, .userPoolOnly])
        XCTAssertEqual(listed.map(\.user), [nil, alice])
        for row in listed {
            guard case .failed(.unknown) = row.state else {
                XCTFail("\(row.sessionId) is \(row.state)")
                continue
            }
            let restored = try await restoredState(row.sessionId)
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
        XCTAssertNotEqual(listed.first?.state, listed.last?.state, "the two errors say what is wrong with each record")
    }

    // MARK: The engine's own decode

    /// A client of this harness's records, over a live engine in place of the fake.
    private func liveClient(_ sessionId: SessionID) throws -> AmplifyCognitoClient {
        let base = harness.dependencies
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try LiveEngineHarness().engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        return try AmplifyCognitoClient(configuration: ClientFixtures.configuration, options: .init(sessionId: sessionId), dependencies: dependencies)
    }

    /// The listing reads a record's credentials with the decode a restored client's engine uses, so a row and its
    /// client cannot disagree about a payload only one of two readers accepts.
    ///
    /// - Given: a store with the readers an app's store has, and records that name no user, so each state is read
    ///   from the credentials: a named session for each `AmplifyCredentials` case, encoded as the engine saves it; one
    ///   whose federated payload is from a provider this build does not know; one whose signed-in payload holds no
    ///   signed-in data; and `.default` over a plugin record from that unknown provider
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - each row's state is the one a client over the live engine restores to
    ///    - the five cases are `.signedIn` (twice), `.guest`, `.federated` and `.signedOut`, and the payloads the
    ///      engine cannot decode are `.failed`
    func testARowsStateIsTheOneAClientOverTheLiveEngineRestoresTo() async throws {
        let appStore = SessionRecordStore(
            namespace: StorageFixtures.namespace,
            keychain: harness.keychain.itemStore(service: SessionRecordStore.unsharedService)
        )
        let federated = String(decoding: try EnginePayloadFixtures.data("identityPoolWithFederation"), as: UTF8.self)
        let unknownProvider = Data(federated.replacingOccurrences(of: #""facebook""#, with: #""aNewerProvider""#).utf8)
        var payloads = try EnginePayloadFixtures.caseNames.map { ($0, try CredentialSlot.encode(EnginePayloadFixtures.credentials($0))) }
        payloads += [("unknownProvider", unknownProvider), ("noSignedInData", Data(#"{"userPoolOnly":{}}"#.utf8))]
        for (name, payload) in payloads {
            // Saved with its case's kind, and no username or user ID.
            let record = SessionRecord(label: nil, username: nil, kind: PluginRecordSummary.peek(payload).kind, credentials: payload)
            try appStore.write(record, for: ClientFixtures.id(name), expecting: nil)
        }
        harness.keychain.put(unknownProvider, pluginAccount)

        let listed = try appStore.storedSessions(includingSignedOut: true)

        let states = Dictionary(uniqueKeysWithValues: listed.map { ($0.sessionId.stringValue, $0.state) })
        let user = AuthClientUser(username: "fixture-user", userId: "fixture-sub")
        XCTAssertEqual(states.keys.sorted(), (payloads.map(\.0) + [SessionID.default.stringValue]).sorted())
        XCTAssertEqual(states["userPoolOnly"], .signedIn(user))
        XCTAssertEqual(states["userPoolAndIdentityPool"], .signedIn(user))
        XCTAssertEqual(states["identityPoolOnly"], .guest)
        XCTAssertEqual(states["identityPoolWithFederation"], .federated(identityId: "us-east-1:fixture-federated-identity-id"))
        XCTAssertEqual(states["noCredentials"], .signedOut)
        for row in listed {
            if ["unknownProvider", "noSignedInData", SessionID.default.stringValue].contains(row.sessionId.stringValue) {
                guard case .failed(.unknown) = row.state else {
                    XCTFail("\(row.sessionId) is \(row.state)")
                    continue
                }
            }
            let restored = try await liveClient(row.sessionId).currentSessionState()
            XCTAssertEqual(row.state, restored, "\(row.sessionId)")
        }
    }

    /// A dead refresh token is found by using it, and the session stays signed in as its user, so an app knows who to
    /// sign in again: the row says the same.
    ///
    /// - Given: a signed-in session whose record says a refresh proved its refresh token dead
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - the row is `.signedIn` with the user, as its client restores, though the client's session read throws
    ///      `sessionExpired`
    func testASessionWhoseRefreshTokenIsDeadIsStillSignedIn() async throws {
        let payload = FakePayload.signedIn("alice", stale: true)
        var record = payload.record()
        record.deadToken = DeadToken(
            token: DeadToken.digest(refreshToken: payload.userPoolTokens?.refreshToken, credentials: payload.data),
            cause: .invalid
        )
        try harness.store().write(record, for: work, expecting: nil)

        let listed = try await rows()

        XCTAssertEqual(listed, [
            StoredSession(sessionId: work, label: nil, user: alice, kind: .userPoolAndIdentityPool, state: .signedIn(alice))
        ])
        let client = try harness.client(work)
        let restored = await client.currentSessionState()
        XCTAssertEqual(restored, .signedIn(alice))
        await assertThrowsAsync({ try await client.fetchAuthSession() }) { error in
            guard case AuthClientError.sessionExpired = error else {
                return XCTFail("\(error)")
            }
        }
    }

    // MARK: Storage failures, and live clients

    /// A locked keychain is never a short list, and never a row's state: the call throws.
    ///
    /// - Given: a signed-out row with a pending challenge, on a device that is locked: first every keychain listing
    ///   fails, then only the read of the challenge's record
    /// - When: the saved sessions are listed, with and without signed-out rows
    /// - Then:
    ///    - every call throws `storageUnavailable(.locked)`, and none returns a list without the row
    func testALockedKeychainThrows() async throws {
        try harness.store().write(.signedOut(label: nil, username: "alice", userId: "sub-alice"), for: work, expecting: nil)
        try saveChallenge(for: work)

        for failure in ["the listing", "the challenge's record"] {
            harness.keychain.clearFailures()
            if failure == "the listing" {
                harness.keychain.failing(.list, with: errSecInteractionNotAllowed)
            } else {
                harness.keychain.failingReads(of: harness.store().challengeAccount(for: work), with: errSecInteractionNotAllowed)
            }
            for includingSignedOut in [false, true] {
                await assertThrowsAsync({ try await self.rows(includingSignedOut: includingSignedOut) }) { error in
                    XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, .locked, "\(failure): \(error)")
                }
            }
        }
    }

    /// The listing is what is saved, not what a client in the process holds.
    ///
    /// - Given: a client restored signed in, and its record then signed out behind it, as another process would
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - the row is `.signedOut`, though the client still reports `.signedIn`
    func testTheListingIsNotOverlaidWithALiveClient() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let before = await client.currentSessionState()
        XCTAssertEqual(try harness.store().signOut(work), .signedOut)

        let listed = try await rows()

        XCTAssertEqual(before, .signedIn(alice))
        XCTAssertEqual(listed.map(\.state), [.signedOut])
        let held = await client.currentSessionState()
        XCTAssertEqual(held, .signedIn(alice))
    }
}
