//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The challenge record in the store: its key and attributes, read, write and delete, the `createdAt`
/// rule, what sign-out and purge delete (under previous configurations too), and the listing's sweep.
final class ChallengeRecordStoreTests: XCTestCase {

    private static let userPoolOnly = PoolNamespace.userPool(StorageFixtures.userPoolId)
    private static let otherIdentityPool = PoolNamespace.userPoolAndIdentityPool(
        userPoolId: StorageFixtures.userPoolId,
        identityPoolId: "us-east-1:11111111-2222-3333-4444-555555555555"
    )

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let createdAt = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
    }

    private func record(session: String = "session-1", at date: Date? = nil, step: AuthClientSignInStep = .confirmSignInWithTOTPCode) -> ChallengeRecord {
        // `.fake` saves every answerable step.
        ChallengeRecord(createdAt: date ?? createdAt, state: .fake(step, session: session)!)
    }

    private func store(_ pools: PoolNamespace) -> SessionRecordStore {
        keychain.recordStore(for: SessionStorageNamespace(pools: pools, accessGroup: nil))
    }

    private func challengeAccount(_ pools: PoolNamespace, _ sessionId: SessionID? = nil) -> String {
        SessionRecordKey.account(for: sessionId ?? work, in: pools, kind: .challenge)
    }

    // MARK: Key and attributes

    /// - Given: the store's challenge account for `work`
    /// - When: it is built, and parsed back
    /// - Then:
    ///    - it is `amplify.1.<poolNamespace>.<sessionId>.challenge`, the design's key, next to the session record
    ///    - it parses as a `.challenge` of `work`, never as a session record, so no listing shows it as a row
    func testTheKeyIsTheDesignsKey() throws {
        let account = store.challengeAccount(for: work)

        XCTAssertEqual(account, "amplify.1.\(StorageFixtures.pools.keyComponent).\(work.stringValue).challenge")
        XCTAssertEqual(SessionRecordKey.parse(account)?.kind, .challenge)
        XCTAssertEqual(SessionRecordKey.parse(account)?.sessionId, work)
    }

    /// The design's "must not sync", asserted against the query the real store adds the record with, not assumed.
    ///
    /// - Given: the store over the real keychain, with and without an access group
    /// - When: the add query for the challenge account is built from the store's own attributes
    /// - Then:
    ///    - it has no `kSecAttrSynchronizable`, so the item is never synced to iCloud Keychain
    ///    - it is `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, device-only, as the session record is
    ///    - the service and access group are the session record's
    func testTheRecordIsDeviceOnlyAndNeverSynchronizable() throws {
        for accessGroup in [nil, "ABCDE12345.com.example.shared"] {
            let namespace = SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: accessGroup)
            let real = SessionRecordStore(namespace: namespace)
            let item = try XCTUnwrap(real.keychain as? KeychainItemStore)

            let query = item.attributes.addQuery(account: real.challengeAccount(for: work), value: Data())

            XCTAssertNil(query[kSecAttrSynchronizable as String], "the challenge record must never sync")
            XCTAssertEqual(query[kSecAttrAccessible as String] as? String, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
            XCTAssertEqual(query[kSecAttrService as String] as? String, SessionRecordStore.service(forAccessGroup: accessGroup))
            XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, accessGroup)
        }
    }

    // MARK: Read, write, delete

    /// - Given: nothing stored for `work`
    /// - When: a record is written, read, and deleted, twice over
    /// - Then:
    ///    - it reads absent, then as written, then absent; deleting an absent record succeeds
    func testWriteReadDelete() throws {
        XCTAssertEqual(try store.readChallenge(work), .absent)

        try store.writeChallenge(record(), for: work)

        XCTAssertEqual(try store.readChallenge(work), .record(record()))
        try store.deleteChallenge(work)
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertNoThrow(try store.deleteChallenge(work))
    }

    /// The session's lifetime runs from when Cognito issued it.
    ///
    /// - Given: a record for session string `s1`, created at `t`
    /// - When: it is rewritten later with the same string and a new step, then with a new string
    /// - Then:
    ///    - the same string keeps `createdAt == t`, with the new step
    ///    - a new string takes the new `createdAt`
    func testARewriteOfTheSameSessionKeepsItsCreationTime() throws {
        try store.writeChallenge(record(session: "s1", at: createdAt), for: work)

        let later = createdAt.addingTimeInterval(60)
        let same = try store.writeChallenge(record(session: "s1", at: later, step: .confirmSignInWithPassword), for: work)
        XCTAssertEqual(same.createdAt, createdAt)
        XCTAssertEqual(try store.storedChallenge(work), same)
        XCTAssertEqual(try store.storedChallenge(work)?.state, record(step: .confirmSignInWithPassword).state.withSession("s1"))

        let fresh = try store.writeChallenge(record(session: "s2", at: later), for: work)
        XCTAssertEqual(fresh.createdAt, later)
    }

    /// The `createdAt` read is best effort: a write never fails on it.
    ///
    /// - Given: a record for session string `s1` created at `t`, and reads of the challenge account failing
    /// - When: a record with the same string is written a minute later
    /// - Then:
    ///    - the write succeeds, with the new `createdAt` (the stored one could not be read), and reads back so once
    ///      the reads recover
    func testAWriteDoesNotFailWhenItsFirstReadFails() throws {
        try store.writeChallenge(record(session: "s1", at: createdAt), for: work)
        keychain.failingReads(of: store.challengeAccount(for: work), with: errSecInteractionNotAllowed)
        let later = createdAt.addingTimeInterval(60)

        let written = try store.writeChallenge(record(session: "s1", at: later), for: work)

        XCTAssertEqual(written.createdAt, later)
        keychain.clearFailures()
        XCTAssertEqual(try store.storedChallenge(work)?.createdAt, later)
    }

    /// - Given: corrupt bytes, and a newer schema's record, under two sessions' challenge accounts
    /// - When: they are read
    /// - Then:
    ///    - they are `.corrupt` and `.unsupportedSchema(version: 2)`, never `.absent`
    func testUnreadableRecordsAreNotAbsent() throws {
        try store.putChallengeBytes(Data("not a record".utf8), for: work)
        try store.putChallengeBytes(Data(#"{"schemaVersion":2,"createdAt":1}"#.utf8), for: home)

        XCTAssertEqual(try store.readChallenge(work), .corrupt)
        XCTAssertEqual(try store.readChallenge(home), .unsupportedSchema(version: 2))
    }

    /// - Given: the keychain failing reads, then sets, then removes of `work`'s challenge account
    /// - When: it is read, written and deleted
    /// - Then:
    ///    - each throws `storageUnavailable`: a failure is never absent, and never silently dropped
    func testFailuresAreStorageUnavailable() throws {
        let account = store.challengeAccount(for: work)

        keychain.failingReads(of: account, with: errSecInteractionNotAllowed)
        assertUnavailable { try store.readChallenge(work) }
        keychain.clearFailures()

        keychain.failingSets(of: account, with: errSecInteractionNotAllowed)
        assertUnavailable { try store.writeChallenge(record(), for: work) }
        keychain.clearFailures()

        keychain.failingRemovals(of: account, with: errSecInteractionNotAllowed)
        assertUnavailable { try store.deleteChallenge(work) }
    }

    private func assertUnavailable(_ body: () throws -> some Any, line: UInt = #line) {
        XCTAssertThrowsError(try body(), line: line) { error in
            XCTAssertNotNil((error as? AuthClientError)?.storageUnavailableReason, "\(error)", line: line)
        }
    }

    /// No stored byte contains the password (built from the machine state that holds it).
    ///
    /// - Given: the engine's TOTP-setup state, which carries the sign-in's whole `SignInEventData`, password and
    ///   client metadata included, as the machine holds it mid-sign-in; and its error sub-state after a wrong code
    /// - When: its saved form is taken as the engine takes it, and written through the store
    /// - Then:
    ///    - neither the password's nor the client metadata's bytes appear under any account the store holds
    func testNoStoredByteContainsThePassword() throws {
        let password = "Correct-Horse-Battery-Staple-1"
        let metadata = "metadata-value-9f2c"
        let eventData = SignInEventData(
            username: "alice",
            password: password,
            clientMetadata: ["k": metadata],
            signInMethod: .apiBased(.userSRP),
            session: "event-session"
        )
        let setup = SignInTOTPSetupData(secretCode: "SECRET", session: "setup-session", username: "alice")
        let machineStates: [SignInTOTPSetupState] = [
            .waitingForAnswer(setup),
            .error(setup, .service(error: FixtureError(description: "wrong code")))
        ]
        for setupState in machineStates {
            keychain = TestKeychain()
            store = keychain.recordStore(for: StorageFixtures.namespace)
            let authState = AuthState.configured(.signingIn(.resolvingTOTPSetup(setupState, eventData)), .configured, .notStarted)
            let state = try XCTUnwrap(ChallengeRecord.State(authState), "the TOTP setup has a saved form")

            try store.writeChallenge(ChallengeRecord(createdAt: createdAt, state: state), for: work)

            let accounts = try store.listAccounts()
            XCTAssertFalse(accounts.isEmpty)
            for account in accounts {
                let bytes = try XCTUnwrap(keychain.value(account))
                XCTAssertNil(bytes.range(of: Data(password.utf8)), "the password is stored")
                XCTAssertNil(bytes.range(of: Data(metadata.utf8)), "the client metadata is stored")
            }
        }
    }

    // MARK: Sign-out and purge

    /// - Given: `work` signed in, with a challenge record; `home` with one too
    /// - When: `work` is signed out, then `home` is purged
    /// - Then:
    ///    - each loses its challenge record; the other session's is untouched until its own turn
    func testSignOutAndPurgeDeleteTheRecord() throws {
        _ = try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        try store.writeChallenge(record(), for: work)
        try store.writeChallenge(record(), for: home)

        XCTAssertEqual(try store.signOut(work), .signedOut)
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertNotEqual(try store.readChallenge(home), .absent)

        try store.purge(home)
        XCTAssertEqual(try store.readChallenge(home), .absent)
    }

    /// A superseded sign-out leaves the session signed in, and its challenge, which may be the newer sign-in's.
    ///
    /// - Given: `work` signed in with credentials A, and a challenge record
    /// - When: a sign-out that removes only credentials B runs
    /// - Then:
    ///    - it is superseded, and the challenge record is kept
    func testASupersededSignOutKeepsTheRecord() throws {
        _ = try store.write(StorageFixtures.signedIn(credentials: "tokens-A"), for: work, expecting: nil)
        try store.writeChallenge(record(), for: work)

        XCTAssertEqual(try store.signOut(work, removing: Data("tokens-B".utf8)), .superseded)
        XCTAssertNotEqual(try store.readChallenge(work), .absent)
    }

    /// A challenge is never carried to a new configuration, so one left under a namespace the marker remembers is
    /// deleted by sign-out and purge.
    ///
    /// - Given: `work` run under the user pool alone (its marker names it), with a challenge record there; then the
    ///   session carried to user pool + identity pool, which remembers the old namespace; a challenge record under a
    ///   third namespace the marker never named
    /// - When: `work` is signed out under the new configuration, and then the same again with a purge
    /// - Then:
    ///    - the old namespace's challenge record is deleted by each; the unnamed namespace's is never touched
    ///    - the carry itself never moved or copied the challenge record
    func testSignOutAndPurgeDeleteChallengesUnderRememberedNamespaces() throws {
        for purging in [false, true] {
            keychain = TestKeychain()
            let old = store(Self.userPoolOnly)
            let new = store(StorageFixtures.pools)
            _ = try old.write(FakePayload.signedIn("alice", kind: .userPoolOnly).record(), for: work, expecting: nil)
            try old.writeChallenge(record(), for: work)
            try store(Self.otherIdentityPool).writeChallenge(record(), for: work)

            _ = try new.readCarryingForward(work)
            XCTAssertEqual(try new.readChallenge(work), .absent, "a challenge is never carried")
            XCTAssertNotEqual(try old.readChallenge(work), .absent)

            if purging {
                try new.purge(work)
            } else {
                XCTAssertEqual(try new.signOut(work), .signedOut)
            }

            XCTAssertEqual(try old.readChallenge(work), .absent, "purging: \(purging)")
            XCTAssertNotEqual(try store(Self.otherIdentityPool).readChallenge(work), .absent, "purging: \(purging)")
        }
    }

    /// Only the copies' namespaces are swept, and only as `removePreviousCopies` sweeps the copies themselves: the
    /// namespace a marker names, when it is not this one, is another configuration's.
    ///
    /// - Given: alice signed in to `work` under this namespace; a marker naming another namespace N, and remembering
    ///   alice's unchanged copy at A, alice's copy at C that another writer has since changed, and alice's guest copy
    ///   at G, each with a challenge record under it; a challenge record under N too
    /// - When: `work` is signed out; then, set up again in a fresh keychain, purged
    /// - Then:
    ///    - A's challenge record is deleted each time
    ///    - N's, C's and G's are never touched
    func testOnlyTheSameUsersUnchangedCopiesAreSwept() throws {
        let copyA = Self.userPoolOnly
        let copyC = PoolNamespace.userPool("us-east-1_Changed01")
        let copyG = PoolNamespace.identityPool("us-east-1:99999999-8888-7777-6666-555555555555")
        for purging in [false, true] {
            keychain = TestKeychain()
            store = keychain.recordStore(for: StorageFixtures.namespace)
            _ = try store.write(FakePayload.signedIn("alice").record(), for: work, expecting: nil, recordingMarker: false)
            let aData = try plant(FakePayload.signedIn("alice", kind: .userPoolOnly).record(), under: copyA)
            let cData = try plant(FakePayload.signedIn("alice", kind: .userPoolOnly).record(), under: copyC)
            _ = try plant(FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2).record(), under: copyC)
            let gData = try plant(FakePayload.guest(identityId: "us-east-1:guest").record(), under: copyG)
            try store.writeMarker(.init(
                poolNamespace: Self.otherIdentityPool.keyComponent,
                copies: [
                    .init(poolNamespace: copyA.keyComponent, sha256: SessionRecordStore.digest(aData), user: "user:sub-alice"),
                    .init(poolNamespace: copyC.keyComponent, sha256: SessionRecordStore.digest(cData), user: "user:sub-alice"),
                    .init(poolNamespace: copyG.keyComponent, sha256: SessionRecordStore.digest(gData), user: "user:sub-alice")
                ]
            ), for: work)
            for pools in [copyA, copyC, copyG, Self.otherIdentityPool] {
                try store(pools).writeChallenge(record(), for: work)
            }

            if purging {
                try store.purge(work)
            } else {
                XCTAssertEqual(try store.signOut(work), .signedOut)
            }

            XCTAssertEqual(try store(copyA).readChallenge(work), .absent, "the same user's unchanged copy, purging: \(purging)")
            for pools in [copyC, copyG, Self.otherIdentityPool] {
                XCTAssertNotEqual(try store(pools).readChallenge(work), .absent, "\(pools.keyComponent), purging: \(purging)")
            }
        }
    }

    /// Stores `record` for `work` under `pools` as bytes, touching no marker. Returns the bytes.
    private func plant(_ record: SessionRecord, under pools: PoolNamespace) throws -> Data {
        let data = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: createdAt, record: record).encoded()
        keychain.put(data, SessionRecordKey.account(for: work, in: pools, kind: .session))
        return data
    }

    /// A copy's namespace is swept only for that copy's user (copy-forward: the marker keeps other users'
    /// copies). Every copy here is unchanged since it was carried, so only the user decides.
    ///
    /// - Given: bob signed in to `work` at B (this namespace); a marker at B remembering alice's copy at A, a copy
    ///   with no recorded user at U, and bob's own copy at O, each with its real session record and matching digest,
    ///   and a challenge record under each
    /// - When: bob signs out at B; then, in a fresh keychain with the same setup, bob's session is purged at B
    /// - Then:
    ///    - alice's interrupted sign-in at A, and the one at U, are left both times
    ///    - bob's own at O is deleted both times
    func testAnotherUsersInterruptedSignInIsLeft() throws {
        let unknown = PoolNamespace.userPool("us-east-1_Unknown9")
        let own = PoolNamespace.userPool("us-east-1_BobsOld1")
        for purging in [false, true] {
            keychain = TestKeychain()
            store = keychain.recordStore(for: StorageFixtures.namespace)
            _ = try store.write(FakePayload.signedIn("bob").record(), for: work, expecting: nil, recordingMarker: false)
            let aliceData = try plant(FakePayload.signedIn("alice", kind: .userPoolOnly).record(), under: Self.userPoolOnly)
            let unknownData = try plant(FakePayload.signedIn("carol", kind: .userPoolOnly).record(), under: unknown)
            let bobData = try plant(FakePayload.signedIn("bob", kind: .userPoolOnly).record(), under: own)
            try store.writeMarker(.init(
                poolNamespace: StorageFixtures.pools.keyComponent,
                copies: [
                    .init(poolNamespace: Self.userPoolOnly.keyComponent, sha256: SessionRecordStore.digest(aliceData), user: "user:sub-alice"),
                    .init(poolNamespace: unknown.keyComponent, sha256: SessionRecordStore.digest(unknownData), user: nil),
                    .init(poolNamespace: own.keyComponent, sha256: SessionRecordStore.digest(bobData), user: "user:sub-bob")
                ],
                user: "user:sub-bob"
            ), for: work)
            for pools in [Self.userPoolOnly, unknown, own] {
                try store(pools).writeChallenge(record(), for: work)
            }

            if purging {
                try store.purge(work)
            } else {
                XCTAssertEqual(try store.signOut(work), .signedOut)
            }

            XCTAssertNotEqual(try store(Self.userPoolOnly).readChallenge(work), .absent, "alice's, purging: \(purging)")
            XCTAssertNotEqual(try store(unknown).readChallenge(work), .absent, "no recorded user, purging: \(purging)")
            XCTAssertEqual(try store(own).readChallenge(work), .absent, "bob's own, purging: \(purging)")
        }
    }

    /// A copy whose session record is already gone is left: nothing shows its namespace is still only this session's.
    ///
    /// - Given: alice signed in to `work` here, a marker remembering alice's copy at A with no session record there
    ///   any more, and a challenge record at A
    /// - When: alice signs out here; then, in a fresh keychain with the same setup, the session is purged
    /// - Then:
    ///    - the challenge record at A is left both times
    func testACopyWhoseRecordIsGoneIsLeft() throws {
        for purging in [false, true] {
            keychain = TestKeychain()
            store = keychain.recordStore(for: StorageFixtures.namespace)
            _ = try store.write(FakePayload.signedIn("alice").record(), for: work, expecting: nil, recordingMarker: false)
            try store.writeMarker(.init(
                poolNamespace: StorageFixtures.pools.keyComponent,
                copies: [.init(poolNamespace: Self.userPoolOnly.keyComponent, sha256: "gone", user: "user:sub-alice")],
                user: "user:sub-alice"
            ), for: work)
            try store(Self.userPoolOnly).writeChallenge(record(), for: work)

            if purging {
                try store.purge(work)
            } else {
                XCTAssertEqual(try store.signOut(work), .signedOut)
            }

            XCTAssertNotEqual(try store(Self.userPoolOnly).readChallenge(work), .absent, "purging: \(purging)")
        }
    }

    /// Sign-out is best effort about the previous namespaces' challenges; purge is not.
    ///
    /// - Given: `work` carried from the user pool alone, with a challenge record left there whose delete fails,
    ///   twice over
    /// - When: `work` is signed out the first time, purged the second
    /// - Then:
    ///    - the sign-out still signs the session out, and leaves that record
    ///    - the purge throws `storageUnavailable` before the session's own record is deleted
    func testAFailedDeleteUnderARememberedNamespace() throws {
        for purging in [false, true] {
            keychain = TestKeychain()
            store = keychain.recordStore(for: StorageFixtures.namespace)
            let old = store(Self.userPoolOnly)
            _ = try old.write(FakePayload.signedIn("alice", kind: .userPoolOnly).record(), for: work, expecting: nil)
            try old.writeChallenge(record(), for: work)
            _ = try store.readCarryingForward(work)
            keychain.failingRemovals(of: challengeAccount(Self.userPoolOnly), with: errSecInteractionNotAllowed)

            if purging {
                assertUnavailable { try store.purge(work) }
                XCTAssertNotEqual(try store.read(work), .absent, "the purge stopped before the session's own record")
            } else {
                XCTAssertEqual(try store.signOut(work), .signedOut)
                XCTAssertNotEqual(try old.readChallenge(work), .absent)
            }
        }
    }

    // MARK: Listing

    /// An interrupted sign-in is not a picker row: only the session record is listed.
    ///
    /// - Given: `work` with only a challenge record, and `home` signed in with one
    /// - When: the sessions are listed, signed-out rows included
    /// - Then:
    ///    - only `home` is listed
    func testAChallengeOnlySessionIsNotListed() throws {
        try store.writeChallenge(record(), for: work)
        _ = try store.write(StorageFixtures.signedIn(), for: home, expecting: nil)
        try store.writeChallenge(record(), for: home)

        XCTAssertEqual(try store.storedSessions(includingSignedOut: true).map(\.sessionId), [home])
    }

    /// A listing sweeps this namespace's challenge records past the ceiling.
    ///
    /// - Given: `work`'s record created 16 minutes ago, `home`'s 5 minutes ago, a third session's corrupt bytes, and
    ///   an expired record under another namespace
    /// - When: the sessions are listed with the sweep at now
    /// - Then:
    ///    - `work`'s is deleted; `home`'s, the corrupt bytes and the other namespace's are kept
    ///    - a listing without the sweep deletes nothing
    func testTheListingSweepsExpiredChallenges() throws {
        let now = createdAt
        let other = ClientFixtures.id("other")
        try store.putChallenge(record(at: now.addingTimeInterval(-16 * 60)), for: work)
        try store.putChallenge(record(at: now.addingTimeInterval(-5 * 60)), for: home)
        try store.putChallengeBytes(Data("corrupt".utf8), for: other)
        try store(Self.userPoolOnly).putChallenge(record(at: now.addingTimeInterval(-60 * 60)), for: work)

        _ = try store.storedSessions()
        XCTAssertNotEqual(try store.readChallenge(work), .absent, "no sweep without a clock")

        _ = try store.storedSessions(sweepingChallengesAt: now)

        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertNotEqual(try store.readChallenge(home), .absent)
        XCTAssertEqual(try store.readChallenge(other), .corrupt)
        XCTAssertNotEqual(try store(Self.userPoolOnly).readChallenge(work), .absent)
    }

    /// The sweep is best effort: the listing never fails on it.
    ///
    /// - Given: an expired record whose delete fails, and a signed-in session
    /// - When: the sessions are listed with the sweep
    /// - Then:
    ///    - the listing returns the signed-in session, and the record is still there
    func testAFailedSweepDoesNotFailTheListing() throws {
        try store.putChallenge(record(at: createdAt.addingTimeInterval(-16 * 60)), for: work)
        _ = try store.write(StorageFixtures.signedIn(), for: home, expecting: nil)
        keychain.failingRemovals(of: store.challengeAccount(for: work), with: errSecInteractionNotAllowed)

        XCTAssertEqual(try store.storedSessions(sweepingChallengesAt: createdAt).map(\.sessionId), [home])
        XCTAssertNotEqual(try store.readChallenge(work), .absent)
    }
}

extension ChallengeRecord.State {
    /// The same state with another Cognito session string.
    func withSession(_ session: String) -> ChallengeRecord.State {
        switch self {
        case .challenge(var challenge):
            challenge.session = session
            return .challenge(challenge)
        case .totpSetup(var setup):
            setup.session = session
            return .totpSetup(setup)
        }
    }
}
