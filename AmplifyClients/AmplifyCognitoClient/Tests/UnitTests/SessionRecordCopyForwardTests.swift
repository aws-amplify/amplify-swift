//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Carrying a session forward across a pool configuration change, at the storage layer
/// (`SessionRecordStore+CopyForward.swift`): only from the namespace the session's marker records, on the
/// plugin's accepted changes, as a copy that keeps the old record; what is and is not carried; the marker;
/// failures and races; and how sign-out, purge and listing treat the copies left behind.
final class SessionRecordCopyForwardTests: XCTestCase {

    private typealias Marker = SessionRecordStore.NamespaceMarker

    private static let userPoolId = StorageFixtures.userPoolId
    private static let identityPoolId = StorageFixtures.identityPoolId
    private static let otherIdentityPoolId = "us-east-1:11111111-2222-3333-4444-555555555555"

    private static let bothPools = PoolNamespace.userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId)
    private static let userPoolOnly = PoolNamespace.userPool(userPoolId)
    private static let identityPoolOnly = PoolNamespace.identityPool(identityPoolId)
    private static let otherIdentityPool = PoolNamespace.userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: otherIdentityPoolId)

    private let work = ClientFixtures.id("work")
    private var keychain: TestKeychain!

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
    }

    // MARK: Helpers

    private func store(_ pools: PoolNamespace, scope: String = TestKeychain.markerScope) -> SessionRecordStore {
        keychain.recordStore(for: SessionStorageNamespace(pools: pools, accessGroup: nil), markerScope: scope)
    }

    private func account(_ pools: PoolNamespace, _ sessionId: SessionID? = nil) -> String {
        SessionRecordKey.account(for: sessionId ?? work, in: pools, kind: .session)
    }

    private var markerAccount: String {
        SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
    }

    /// Stores `payload` for `work` under `pools`, as this app running with that configuration left it: the record,
    /// whose creation writes the marker naming `pools`. Returns the stored bytes.
    @discardableResult
    private func ran(_ payload: FakePayload, label: String? = "Work", under pools: PoolNamespace) throws -> Data {
        guard case .committed(let envelope) = try store(pools).write(payload.record(label: label), for: work, expecting: nil) else {
            throw FakeEngineError.unreadablePayload
        }
        XCTAssertEqual(try store(pools).marker(for: work)?.poolNamespace, pools.keyComponent)
        return try envelope.encoded()
    }

    /// Stores `payload` for `sessionId` under `pools` without touching any marker: a record this app did not
    /// write (another app's, or an earlier build's). Returns the stored bytes.
    @discardableResult
    private func plant(_ payload: FakePayload, label: String? = nil, for sessionId: SessionID? = nil, under pools: PoolNamespace) throws -> Data {
        let data = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: Date(), record: payload.record(label: label)).encoded()
        keychain.put(data, account(pools, sessionId))
        return data
    }

    /// The session's marker, as stored: its namespace, its copies (each with its recorded user) and its own user.
    private func marker(_ pools: PoolNamespace = bothPools) throws -> Marker? {
        try store(pools).marker(for: work)
    }

    /// The copy a marker records of the record `data` under `pools`: its digest, and its user as the store keys it
    /// (`unrecorded`: none, as an earlier build's marker has).
    private func copy(_ pools: PoolNamespace, _ data: Data, unrecorded: Bool = false) -> Marker.Copy {
        var user: String?
        if !unrecorded, case .envelope(let envelope) = SessionRecordEnvelope.decode(data) {
            user = store(pools).userKey(envelope.record)
        }
        return Marker.Copy(poolNamespace: pools.keyComponent, sha256: SessionRecordStore.digest(data), user: user)
    }

    private func assertStorageUnavailable(
        _ reason: StorageUnavailableReason,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () throws -> some Any
    ) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, reason, "\(error)", file: file, line: line)
        }
    }

    private func carriedRecord(_ result: SessionRecordStore.ReadResult, file: StaticString = #filePath, line: UInt = #line) -> SessionRecordEnvelope? {
        guard case .record(let envelope) = result else {
            XCTFail("expected a record, got \(result)", file: file, line: line)
            return nil
        }
        return envelope
    }

    // MARK: The plugin's branches, from the recorded namespace

    /// User pool → user pool + identity pool.
    ///
    /// - Given: alice's record under the user pool alone, the marker naming it
    /// - When: the user pool + identity pool store reads the session
    /// - Then:
    ///    - the tokens are carried as a user-pool-only record with `identityPending`, label, username and user ID
    ///      kept, at generation 1
    ///    - the old record is kept, byte for byte, and the marker names the new namespace and remembers the old
    ///      record as a copy, with the digest of its bytes
    func testUserPoolRecordIsCarriedIntoAConfigurationWithAnIdentityPool() throws {
        let old = try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        XCTAssertEqual(envelope.generation, 1)
        XCTAssertEqual(envelope.record.kind, .userPoolOnly)
        XCTAssertTrue(envelope.record.identityPending)
        XCTAssertEqual(envelope.record.label, "Work")
        XCTAssertEqual(envelope.record.username, "alice")
        XCTAssertEqual(envelope.record.userId, "sub-alice")
        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), old, "the old record is kept")
        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, old)], user: "user:sub-alice"))
    }

    /// Identity pool → user pool + the same identity pool.
    ///
    /// - Given: a guest's record under the identity pool alone, the marker naming it
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it is carried as it is (same credentials, guest, not pending), and the old record is kept
    func testGuestRecordIsCarriedAsItIs() throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        let old = try ran(guest, under: Self.identityPoolOnly)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        XCTAssertEqual(envelope.record.kind, .guest)
        XCTAssertEqual(envelope.record.credentials, guest.data)
        XCTAssertFalse(envelope.record.identityPending)
        XCTAssertEqual(keychain.value(account(Self.identityPoolOnly)), old)
    }

    /// - Given: a federated identity's record under the identity pool alone, the marker naming it
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it is carried as it is
    func testFederatedRecordIsCarriedAsItIs() throws {
        let federated = FakePayload.federated()
        try ran(federated, under: Self.identityPoolOnly)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        XCTAssertEqual(envelope.record.kind, .federated)
        XCTAssertEqual(envelope.record.credentials, federated.data)
    }

    /// The plugin's `:138` branch with a changed identity pool, and the deliberate difference.
    ///
    /// - Given: alice's record under the user pool + another identity pool, holding that pool's identity
    /// - When: the user pool + identity pool store reads the session
    /// - Then: only the tokens are carried (no identity ID, no AWS credentials, `identityPending`); the old record
    ///   is kept
    func testChangedIdentityPoolCarriesTheTokensOnly() throws {
        let old = try ran(.signedIn("alice", identityId: "us-east-1:old-identity"), under: Self.otherIdentityPool)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        let payload = try XCTUnwrap(FakePayload.decode(try XCTUnwrap(envelope.record.credentials)))
        XCTAssertEqual(payload.kind, SessionKind.userPoolOnly.storedValue)
        XCTAssertNil(payload.identityId, "no identity crosses a changed identity pool")
        XCTAssertFalse(payload.aws, "no AWS credentials cross a changed identity pool")
        XCTAssertTrue(envelope.record.identityPending)
        XCTAssertEqual(keychain.value(account(Self.otherIdentityPool)), old)
    }

    /// The plugin's `:138` branch the other way.
    ///
    /// - Given: alice's record under the user pool + identity pool
    /// - When: the user-pool-only store reads the session
    /// - Then: the tokens are carried, with no identity and not pending (there is no identity pool)
    func testRemovingTheIdentityPoolCarriesTheTokensOnly() throws {
        try ran(.signedIn("alice", identityId: "us-east-1:identity"), under: Self.bothPools)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.userPoolOnly).readCarryingForward(work)))

        XCTAssertEqual(envelope.record.kind, .userPoolOnly)
        XCTAssertFalse(envelope.record.identityPending)
        XCTAssertNil(FakePayload.decode(try XCTUnwrap(envelope.record.credentials))?.identityId)
    }

    /// The plugin's third branch removes its record (`removeSession(for:)`); the client keeps it, since an app may
    /// switch its configuration at runtime under one session ID, and deleting would end the other configuration's
    /// session unrevoked.
    ///
    /// - Given: a guest under another identity pool, the marker naming it
    /// - When: an identity-pool-only store reads the session, then the other identity pool's store does (switching
    ///   back, or a rollback)
    /// - Then:
    ///    - `.absent`; the guest's record and the marker are untouched, and nothing is written
    ///    - switching back reads the guest as it was
    func testAChangeTheClientDoesNotCarryKeepsTheOldRecord() throws {
        let other = PoolNamespace.identityPool(Self.otherIdentityPoolId)
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try ran(guest, under: other)
        keychain.resetLogs()

        XCTAssertEqual(try store(Self.identityPoolOnly).readCarryingForward(work), .absent)

        XCTAssertNotNil(keychain.value(account(other)))
        XCTAssertEqual(try marker(Self.identityPoolOnly), Marker(poolNamespace: other.keyComponent, user: "identity:us-east-1:guest-1"))
        XCTAssertEqual(keychain.writtenAccounts, [])
        XCTAssertEqual(carriedRecord(try store(other).readCarryingForward(work))?.record.credentials, guest.data)
    }

    /// After a change the client does not carry, the first record started under the new configuration remembers
    /// the old one as a copy with its own user, so that user's sign-out there sweeps it.
    ///
    /// - Given: alice under another user pool with both pools' identity pool (the marker naming it), with the same
    ///   `userId` as the alice about to sign in
    /// - When: the user pool + identity pool store reads the session (not carried), alice signs in there, then signs
    ///   out
    /// - Then: the read leaves the old record; the sign-in remembers it as a copy with its digest; the sign-out
    ///   deletes it
    func testASignInAfterAnUncarriedChangeRemembersTheOldRecordForTheSweep() throws {
        let otherUserPool = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Other9999", identityPoolId: Self.identityPoolId)
        let old = try ran(.signedIn("alice"), under: otherUserPool)
        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
        XCTAssertEqual(keychain.value(account(otherUserPool)), old)

        try store(Self.bothPools).write(FakePayload.signedIn("alice", version: 2).record(), for: work, expecting: nil)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(otherUserPool, old)], user: "user:sub-alice"))
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)
        XCTAssertNil(keychain.value(account(otherUserPool)))
    }

    /// - Given: alice under another user pool (the marker naming it)
    /// - When: bob signs in under both pools, then signs out
    /// - Then: alice's record is remembered at the sign-in as hers, and bob's sign-out leaves it
    func testASignInOfAnotherUserAfterAnUncarriedChangeLeavesTheOldRecord() throws {
        let otherUserPool = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Other9999", identityPoolId: Self.identityPoolId)
        let old = try ran(.signedIn("alice"), under: otherUserPool)

        try store(Self.bothPools).write(FakePayload.signedIn("bob").record(), for: work, expecting: nil)
        XCTAssertEqual(try marker()?.copies.map(\.user), ["user:sub-alice"], "remembered as alice's")
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(otherUserPool, old)], user: "user:sub-bob"), "kept for alice")
        XCTAssertEqual(keychain.value(account(otherUserPool)), old)
    }

    /// - Given: corrupt bytes under another identity pool, the marker naming it
    /// - When: an identity-pool-only store reads the session (a change the client does not carry)
    /// - Then: `.absent`, and the unreadable record and the marker are left as they are
    func testAnUncarriedChangeLeavesAnUnreadableRecord() throws {
        let other = PoolNamespace.identityPool(Self.otherIdentityPoolId)
        keychain.put(StorageFixtures.corruptRecord, account(other))
        try store(other).writeMarker(Marker(poolNamespace: other.keyComponent), for: work)

        XCTAssertEqual(try store(Self.identityPoolOnly).readCarryingForward(work), .absent)

        XCTAssertEqual(keychain.value(account(other)), StorageFixtures.corruptRecord)
        XCTAssertEqual(try marker()?.poolNamespace, other.keyComponent)
    }

    /// - Given: every pair of namespaces
    /// - When: `carry(from:into:)` is asked
    /// - Then: only the plugin's accepted changes carry, each as the table in `SessionRecordStore+CopyForward.swift`
    func testTheCarryTable() {
        typealias Store = SessionRecordStore
        XCTAssertEqual(Store.carry(from: Self.identityPoolOnly, into: Self.bothPools), .asIs)
        XCTAssertEqual(Store.carry(from: Self.userPoolOnly, into: Self.bothPools), .userPoolTokensOnly(identityPending: true))
        XCTAssertEqual(Store.carry(from: Self.otherIdentityPool, into: Self.bothPools), .userPoolTokensOnly(identityPending: true))
        XCTAssertEqual(Store.carry(from: Self.bothPools, into: Self.userPoolOnly), .userPoolTokensOnly(identityPending: false))
        XCTAssertNil(Store.carry(from: .identityPool(Self.otherIdentityPoolId), into: Self.bothPools), "a different identity pool")
        XCTAssertNil(Store.carry(from: .userPool("us-east-1_Other9999"), into: Self.bothPools), "a different user pool")
        XCTAssertNil(Store.carry(from: Self.bothPools, into: Self.identityPoolOnly), "into identity pool only")
        XCTAssertNil(Store.carry(from: Self.userPoolOnly, into: Self.identityPoolOnly))
        XCTAssertNil(Store.carry(from: Self.identityPoolOnly, into: Self.userPoolOnly))
        XCTAssertNil(Store.carry(from: .identityPool(Self.otherIdentityPoolId), into: Self.identityPoolOnly))
    }

    /// - Given: each carry
    /// - When: asked whether it takes each kind of record
    /// - Then: the tokens carry takes user pool sessions only, the as-is carry guests and federated identities only
    func testWhichKindsEachCarryTakes() {
        let tokens = SessionRecordStore.Carry.userPoolTokensOnly(identityPending: true)
        XCTAssertTrue(tokens.accepts(.userPoolOnly))
        XCTAssertTrue(tokens.accepts(.userPoolAndIdentityPool))
        XCTAssertFalse(tokens.accepts(.guest))
        XCTAssertFalse(tokens.accepts(.federated))
        XCTAssertFalse(tokens.accepts(.signedOut))
        XCTAssertTrue(SessionRecordStore.Carry.asIs.accepts(.guest))
        XCTAssertTrue(SessionRecordStore.Carry.asIs.accepts(.federated))
        XCTAssertFalse(SessionRecordStore.Carry.asIs.accepts(.userPoolOnly))
        XCTAssertFalse(SessionRecordStore.Carry.asIs.accepts(.userPoolAndIdentityPool))
    }

    /// A deliberate difference from the plugin, whose own row-146 test data stores a guest under a
    /// user-pool-only configuration and carries it byte for byte.
    ///
    /// - Given: a guest's record under the user pool alone, the marker naming it
    /// - When: the user pool + identity pool store reads the session
    /// - Then: `.absent`, and the guest's record is left alone
    func testAGuestUnderAUserPoolOnlyNamespaceIsNotCarried() throws {
        try ran(.guest(), under: Self.userPoolOnly)

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    // MARK: Only the recorded namespace

    /// - Given: alice's record under the user pool alone, and no marker (another app's record, or an earlier
    ///   build's)
    /// - When: the user pool + identity pool store reads the session
    /// - Then: `.absent`, and the record is left alone
    func testWithoutAMarkerNothingIsCarried() throws {
        try plant(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// An app and its extension share the access group and `.default`, with different configurations.
    ///
    /// - Given: the app signed in under both pools (its marker), and the extension, another marker scope, never
    ///   run
    /// - When: the extension, under the user pool alone, reads `.default`, then signs it out
    /// - Then: it reads `.absent`, and the app's record and marker are untouched
    func testAnExtensionNeverTouchesTheAppsRecord() throws {
        let app = store(Self.bothPools)
        try app.write(FakePayload.signedIn().record(), for: .default, expecting: nil)
        let appRecord = keychain.value(account(Self.bothPools, .default))
        let appMarker = try app.marker(for: .default)
        let extensionStore = store(Self.userPoolOnly, scope: "fedcba9876543210")

        XCTAssertEqual(try extensionStore.readCarryingForward(.default), .absent)
        XCTAssertEqual(try extensionStore.signOut(.default), .noRecord)

        XCTAssertEqual(keychain.value(account(Self.bothPools, .default)), appRecord)
        XCTAssertEqual(try app.marker(for: .default), appMarker)
    }

    /// A rollback A → B → A never revives a signed-out session.
    ///
    /// - Given: alice carried from the user pool into both pools (the old record kept), then signed out there
    /// - When: the user-pool-only store reads the session again (the rollback)
    /// - Then: the kept copy was swept at sign-out (untouched since the carry), so it reads `.absent`
    func testARollbackDoesNotReviveASignedOutSession() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(try store(Self.userPoolOnly).readCarryingForward(work), .absent)
    }

    /// The copy is kept, so rolling back an added user pool keeps the guest's identity (the plugin's behaviour).
    ///
    /// - Given: a guest carried from the identity pool alone into both pools
    /// - When: the identity-pool-only store reads the session again (the rollback)
    /// - Then: it reads the kept guest record, with its identity
    func testARollbackOfAnAddedUserPoolKeepsTheGuestIdentity() throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try ran(guest, under: Self.identityPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.identityPoolOnly).readCarryingForward(work)))

        XCTAssertEqual(envelope.record.credentials, guest.data)
    }

    /// A kept copy that another writer changed is that writer's.
    ///
    /// - Given: alice carried from the user pool into both pools, then her user-pool record rewritten (an extension
    ///   still on the user-pool-only configuration refreshed it)
    /// - When: the session signs out under both pools
    /// - Then: the rewritten record is left, and the marker no longer remembers it
    func testASweepLeavesACopyAnotherWriterChanged() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        let rewritten = try SessionRecordEnvelope(
            generation: 2,
            lastWriteTimestamp: Date(),
            record: FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2).record()
        ).encoded()
        keychain.put(rewritten, account(Self.userPoolOnly))

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), rewritten)
        XCTAssertEqual(try marker()?.copies, [])
    }

    /// - Given: alice under the user pool (a stale record from an older configuration), and the marker naming
    ///   another identity pool's namespace, where the session has no record
    /// - When: the user pool + identity pool store reads the session
    /// - Then: `.absent`: alice is not revived from the older namespace
    func testAnOlderNamespaceIsNeverASource() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try store(Self.otherIdentityPool).writeMarker(Marker(poolNamespace: Self.otherIdentityPool.keyComponent), for: work)

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// The tombstone: the latest recorded state is signed out, so an older one is not brought back.
    ///
    /// - Given: alice at the user pool; then a guest at the identity pool alone (nothing carried there), signed out
    ///   with removals of alice's record failing, so her record is certainly still there
    /// - When: the user pool + identity pool store reads the session
    /// - Then: `.absent`: alice is not revived
    func testASignedOutLatestStateCarriesNothing() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try store(Self.identityPoolOnly).write(FakePayload.guest().record(), for: work, expecting: nil)
        keychain.failingRemovals(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)
        XCTAssertEqual(try store(Self.identityPoolOnly).signOut(work), .signedOut)
        keychain.clearFailures()
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent, "alice's record is still there")

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
    }

    /// A signed-out row here is the session's own answer, which also blocks carrying back on a rollback.
    ///
    /// - Given: alice's record under the user pool with the marker, and a signed-out row under both pools
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it reads the signed-out row, and the old record is left alone
    func testASignedOutRowHereIsNeverOvertaken() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try store(Self.bothPools).write(.signedOut(label: "Work", username: "alice"), for: work, expecting: nil)

        let result = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertTrue(try XCTUnwrap(carriedRecord(result)).record.isSignedOut)
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// - Given: under the recorded namespace, in turn: a signed-out row, corrupt bytes, a newer schema's record, and
    ///   a record whose payload the tokens rewrite cannot read
    /// - When: the user pool + identity pool store reads the session
    /// - Then: `.absent` each time, and the record is left alone
    func testUnusableRecordsAreNotCarriedAndLeftAlone() throws {
        let cases: [(String, Data)] = [
            ("signed out", try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: Date(), record: .signedOut(label: nil, username: "alice")).encoded()),
            ("corrupt", StorageFixtures.corruptRecord),
            ("newer schema", StorageFixtures.futureSchemaRecord),
            ("undecodable payload", try SessionRecordEnvelope(
                generation: 1,
                lastWriteTimestamp: Date(),
                record: SessionRecord(label: nil, username: "alice", kind: .userPoolOnly, credentials: Data("opaque".utf8))
            ).encoded())
        ]
        for (name, data) in cases {
            keychain = TestKeychain()
            keychain.put(data, account(Self.userPoolOnly))
            try store(Self.userPoolOnly).writeMarker(Marker(poolNamespace: Self.userPoolOnly.keyComponent), for: work)

            XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent, name)
            XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), data, "\(name) is left alone")
        }
    }

    // MARK: The marker

    /// - Given: a record under both pools written by an earlier build (no marker)
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the marker records this namespace, with no copies
    func testARestoreWithNoMarkerRecordsThisNamespace() throws {
        try plant(.signedIn(), under: Self.bothPools)

        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, user: "user:sub-alice"))
    }

    /// - Given: alice's record under both pools (this app is back here: a rollback), and the marker naming the user
    ///   pool, which also holds a record of alice
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the marker records this namespace, and remembers the user-pool record as a copy, with its digest
    func testARestoreBackUnderAnotherNamespaceRemembersItsRecord() throws {
        let userPoolRecord = try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn(), under: Self.bothPools)

        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, userPoolRecord)], user: "user:sub-alice"))
    }

    /// Another user's record is remembered as a copy with its own user, so a sign-out here never deletes it.
    ///
    /// - Given: alice's record under both pools, and the marker naming the user pool, whose record is bob's
    /// - When: the user pool + identity pool store reads the session, then alice signs out there
    /// - Then: the marker records this namespace and remembers bob's record as his; alice's sign-out leaves it
    func testARestoreBackRemembersAnotherUsersRecordAsHis() throws {
        let bob = try ran(.signedIn("bob", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn("alice"), under: Self.bothPools)

        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, bob)], user: "user:sub-alice"))
        XCTAssertEqual(try marker()?.copies.first?.user, "user:sub-bob")
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)
        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), bob)
    }

    /// Two guests are the same user only with the same identity: the copy records its own.
    ///
    /// - Given: a guest's record under both pools, and the marker naming the identity pool alone, whose record is a
    ///   guest with another identity, then (a second run) with the same identity
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the identity-pool record is remembered each time, with its own identity as its user
    func testARestoreBackTellsGuestsApartByTheirIdentity() throws {
        for identityId in ["us-east-1:other-guest", "us-east-1:guest-1"] {
            keychain = TestKeychain()
            let there = try ran(.guest(identityId: identityId), under: Self.identityPoolOnly)
            try plant(.guest(identityId: "us-east-1:guest-1"), under: Self.bothPools)

            _ = try store(Self.bothPools).readCarryingForward(work)

            XCTAssertEqual(try marker()?.copies, [copy(Self.identityPoolOnly, there)], identityId)
            XCTAssertEqual(try marker()?.copies.first?.user, "identity:" + identityId, identityId)
        }
    }

    /// - Given: records of each kind of principal
    /// - When: each record's user key is taken (what the marker records for a copy, and compares)
    /// - Then: the same `userId`, or the same identity, is the same key; a user pool user and a guest never share
    ///   one, even with the same identity; a signed-out guest row has none
    func testWhichRecordsHaveTheSameUserKey() {
        let store = store(Self.bothPools)
        let alice = FakePayload.signedIn("alice").record()
        let aliceElsewhere = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 7).record()
        let bob = FakePayload.signedIn("bob").record()
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1").record()
        let sameGuest = FakePayload.guest(version: 3, identityId: "us-east-1:guest-1").record()
        let otherGuest = FakePayload.guest(identityId: "us-east-1:guest-2").record()
        let aliceWithTheGuestsIdentity = FakePayload.signedIn("alice", identityId: "us-east-1:guest-1").record()
        XCTAssertEqual(store.userKey(alice), "user:sub-alice")
        XCTAssertEqual(store.userKey(alice), store.userKey(aliceElsewhere))
        XCTAssertNotEqual(store.userKey(alice), store.userKey(bob))
        XCTAssertEqual(store.userKey(guest), "identity:us-east-1:guest-1")
        XCTAssertEqual(store.userKey(guest), store.userKey(sameGuest))
        XCTAssertNotEqual(store.userKey(guest), store.userKey(otherGuest))
        XCTAssertNotEqual(store.userKey(guest), store.userKey(aliceWithTheGuestsIdentity))
        XCTAssertEqual(store.userKey(.signedOut(label: nil, username: "alice", userId: "sub-alice")), "user:sub-alice")
        XCTAssertNil(store.userKey(.signedOut(label: nil, username: nil)))
    }

    /// Signing in over a signed-out row makes the marker name this namespace again, so a later change carries from
    /// here, not from where the session was kept before.
    ///
    /// - Given: alice's record under the user pool alone (the marker naming it), and a signed-out row under both
    ///   pools
    /// - When: bob's record is written over the signed-out row under both pools
    /// - Then: the marker names both pools
    func testASignInOverASignedOutRowNamesThisNamespace() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        guard case .committed(let row) = try store(Self.bothPools).write(.signedOut(label: nil, username: "alice"), for: work, expecting: nil) else {
            return XCTFail("the row was not written")
        }
        XCTAssertEqual(try marker()?.poolNamespace, Self.userPoolOnly.keyComponent, "a signed-out row writes no marker")

        try store(Self.bothPools).write(FakePayload.signedIn("bob").record(), for: work, expecting: row.generation)

        XCTAssertEqual(try marker()?.poolNamespace, Self.bothPools.keyComponent)
    }

    // MARK: Rollbacks after an ended session

    /// A rollback after a sign-out whose sweep failed: the copy is still the untouched copy the marker remembers,
    /// and the session is signed out where the marker names, so the copy reads as swept.
    ///
    /// - Given: alice carried from the user pool into both pools, then signed out there with deletes of the copy
    ///   failing, so the copy is left
    /// - When: the user-pool-only store reads the session (the rollback)
    /// - Then: `.absent`; the copy is deleted, and the marker no longer remembers it
    func testARollbackAfterASignOutWhoseSweepFailedReadsSwept() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        keychain.failingRemovals(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)
        keychain.clearFailures()
        XCTAssertNotNil(keychain.value(account(Self.userPoolOnly)), "the copy is left")

        XCTAssertEqual(try store(Self.userPoolOnly).readCarryingForward(work), .absent)

        XCTAssertNil(keychain.value(account(Self.userPoolOnly)))
        XCTAssertEqual(try marker()?.copies, [])
    }

    /// A rollback after another app (another marker scope, which does not know this app's copies) purged the
    /// session under the configuration the marker names.
    ///
    /// - Given: alice carried from the user pool into both pools, then purged under both pools by another app
    /// - When: the user-pool-only store reads the session (the rollback)
    /// - Then: `.absent`, and the copy is deleted
    func testARollbackAfterAnotherAppsPurgeReadsSwept() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        try store(Self.bothPools, scope: "fedcba9876543210").purge(work)

        XCTAssertEqual(try store(Self.userPoolOnly).readCarryingForward(work), .absent)

        XCTAssertNil(keychain.value(account(Self.userPoolOnly)))
    }

    /// - Given: alice carried from the user pool into both pools, signed out there by another app, and her
    ///   user-pool record rewritten since the carry (an extension on that configuration refreshed it)
    /// - When: the user-pool-only store reads the session (the rollback)
    /// - Then: it reads the rewritten record, which is another writer's; the marker names the user pool again
    func testARollbackKeepsACopyChangedSinceTheCarry() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        XCTAssertEqual(try store(Self.bothPools, scope: "fedcba9876543210").signOut(work), .signedOut)
        let rewritten = try SessionRecordEnvelope(
            generation: 2,
            lastWriteTimestamp: Date(),
            record: FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2).record()
        ).encoded()
        keychain.put(rewritten, account(Self.userPoolOnly))

        XCTAssertEqual(carriedRecord(try store(Self.userPoolOnly).readCarryingForward(work))?.record.username, "alice")

        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), rewritten)
        XCTAssertEqual(try marker()?.poolNamespace, Self.userPoolOnly.keyComponent)
    }

    /// A guest's copy is never swept: an app extension on the old configuration may use its identity.
    ///
    /// - Given: a guest carried from the identity pool alone into both pools, then signed out there by another app
    /// - When: the identity-pool-only store reads the session (the rollback)
    /// - Then: it reads the guest, with its identity
    func testARollbackNeverSweepsAGuest() throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try ran(guest, under: Self.identityPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        XCTAssertEqual(try store(Self.bothPools, scope: "fedcba9876543210").signOut(work), .signedOut)

        XCTAssertEqual(carriedRecord(try store(Self.identityPoolOnly).readCarryingForward(work))?.record.credentials, guest.data)
    }

    /// A row signed out by another writer, which does not know this app's copies, sweeps them at the next restore.
    ///
    /// - Given: alice carried from the user pool into both pools, then signed out there by another app
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it reads the signed-out row, and the untouched copy is deleted
    func testARestoreOfARowSignedOutByAnotherWriterSweepsTheCopies() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        XCTAssertEqual(try store(Self.bothPools, scope: "fedcba9876543210").signOut(work), .signedOut)
        XCTAssertNotNil(keychain.value(account(Self.userPoolOnly)), "the other app does not sweep this app's copy")

        XCTAssertTrue(try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work))).record.isSignedOut)

        XCTAssertNil(keychain.value(account(Self.userPoolOnly)))
        XCTAssertEqual(try marker()?.copies, [])
    }

    /// A session purged by another writer leaves nothing here that tells whose the copies are, so nothing is swept;
    /// the marker keeps them, and a rollback reads the untouched copy as swept.
    ///
    /// - Given: alice carried from the user pool into both pools, then purged there by another app
    /// - When: the user pool + identity pool store reads the session, then the user-pool-only store does (a rollback)
    /// - Then: the first is `.absent`, and the copy and the marker's memory of it are kept; the rollback reads
    ///   `.absent` and deletes the copy
    func testARestoreOfASessionPurgedByAnotherWriterLeavesTheCopiesForARollback() throws {
        let old = try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        try store(Self.bothPools, scope: "fedcba9876543210").purge(work)

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)

        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), old)
        XCTAssertEqual(try marker()?.copies, [copy(Self.userPoolOnly, old)])
        XCTAssertEqual(try store(Self.userPoolOnly).readCarryingForward(work), .absent)
        XCTAssertNil(keychain.value(account(Self.userPoolOnly)))
    }

    /// A different user starting under a configuration the session is not carried into never reaches the earlier
    /// user's copies, which stay remembered for her own sign-out.
    ///
    /// - Given: alice at A (both pools), carried to A' (the same user pool, another identity pool: the marker names A'
    ///   and remembers A as alice's); then, at B (another user pool, not carried), in turn bob signs in, and (a second
    ///   run) a guest under the identity pool alone
    /// - When: B's user signs out there, and another app purges the session at B; this app restores it at B, then at
    ///   A (switching back to the copy's configuration), then at A', where alice's tokens are refreshed with rotation
    ///   and she signs out; then it restores at A again
    /// - Then:
    ///    - the start at B keeps alice's copy of A in the marker, recorded as hers; neither B's sign-out nor the
    ///      restore at B deletes anything
    ///    - at A, alice is signed in: the session that ended at B was not hers, so her copy is not read as swept
    ///    - back at A', alice is signed in; her sign-out lists her A copy's refresh token to revoke (the same user
    ///      pool) and sweeps it
    ///    - at A the session then reads `.absent`
    func testAnotherUsersSessionNeverSweepsTheEarlierUsersCopies() throws {
        let starts: [(String, PoolNamespace, FakePayload)] = [
            ("bob", PoolNamespace.userPool("us-east-1_Other9999"), FakePayload.signedIn("bob", kind: .userPoolOnly)),
            ("a guest", Self.identityPoolOnly, FakePayload.guest(identityId: "us-east-1:guest-at-b"))
        ]
        for (starter, atB, start) in starts {
            for viaA in [true, false] {
                let who = viaA ? starter : "\(starter), B → A' directly"
                keychain = TestKeychain()
                let atA = try ran(.signedIn("alice"), under: Self.bothPools)
                guard case .record(let carried) = try store(Self.otherIdentityPool).readCarryingForward(work) else {
                    return XCTFail("\(who): not carried")
                }
                let atAPrime = try carried.encoded()
                XCTAssertEqual(try marker()?.copies, [Marker.Copy(poolNamespace: Self.bothPools.keyComponent, sha256: SessionRecordStore.digest(atA), user: "user:sub-alice")], who)

                XCTAssertEqual(try store(atB).readCarryingForward(work), .absent, who)
                try store(atB).write(start.record(), for: work, expecting: nil)
                XCTAssertEqual(
                    try marker()?.copies.map(\.user),
                    ["user:sub-alice", "user:sub-alice"],
                    "\(who): alice's copies, of A and of A' (the record the marker named), are kept as hers"
                )
                XCTAssertEqual(
                    try marker(),
                    Marker(poolNamespace: atB.keyComponent, copies: [copy(Self.bothPools, atA), copy(Self.otherIdentityPool, atAPrime)], user: store(atB).userKey(start.record())),
                    who
                )
                XCTAssertEqual(try store(atB).signOut(work), .signedOut, who)
                XCTAssertEqual(keychain.value(account(Self.bothPools)), atA, "\(who): B's sign-out does not sweep alice's copy")
                try store(atB, scope: "fedcba9876543210").purge(work)
                XCTAssertEqual(try store(atB).readCarryingForward(work), .absent, who)
                XCTAssertEqual(keychain.value(account(Self.bothPools)), atA, who)
                XCTAssertEqual(keychain.value(account(Self.otherIdentityPool)), atAPrime, who)
                if viaA {
                    XCTAssertEqual(
                        carriedRecord(try store(Self.bothPools).readCarryingForward(work))?.record.username,
                        "alice",
                        "\(who): at A, the ended session was not alice's"
                    )
                }

                guard case .record(let back) = try store(Self.otherIdentityPool).readCarryingForward(work) else {
                    return XCTFail("\(who): alice is gone at A'")
                }
                XCTAssertEqual(back.record.username, "alice", who)
                XCTAssertEqual(keychain.value(account(Self.bothPools)), atA, "\(who): readKept at A' keeps A")
                var rotated = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 3)
                rotated.refreshToken = "refresh-alice-rotated"
                try store(Self.otherIdentityPool).write(rotated.record(), for: work, expecting: back.generation)
                let revocable = try store(Self.otherIdentityPool).copiesToRevoke(of: work, revoking: rotated.data)
                XCTAssertEqual(revocable, [FakePayload.signedIn("alice").data], "\(who): her A copy's token is revoked")
                XCTAssertEqual(try store(Self.otherIdentityPool).signOut(work), .signedOut, who)

                XCTAssertNil(keychain.value(account(Self.bothPools)), "\(who): her A copy is swept")
                XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent, who)
            }
        }
    }

    /// The record the marker names is remembered with its own user whoever starts a session in between, so its user's
    /// later sign-out still reaches it.
    ///
    /// - Given: alice at A (both pools), carried to A' (the same user pool, another identity pool), where her tokens
    ///   are refreshed with rotation; then bob signs in at B (another user pool, not carried)
    /// - When: the app rolls back to A, where alice signs out; then it restores at A'
    /// - Then: bob's start remembers the A' record as alice's; at A, alice's sign-out lists the rotated A' token to
    ///   revoke and sweeps the A' record; at A' the session reads `.absent`
    func testAnotherUserInBetweenKeepsTheNamedRecordForItsUser() throws {
        let atB = PoolNamespace.userPool("us-east-1_Other9999")
        try ran(.signedIn("alice"), under: Self.bothPools)
        guard case .record(let carried) = try store(Self.otherIdentityPool).readCarryingForward(work) else {
            return XCTFail("not carried")
        }
        var rotated = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
        rotated.refreshToken = "refresh-alice-rotated"
        try store(Self.otherIdentityPool).write(rotated.record(), for: work, expecting: carried.generation)

        try store(atB).write(FakePayload.signedIn("bob", kind: .userPoolOnly).record(), for: work, expecting: nil)
        XCTAssertEqual(
            try marker()?.copies.first { $0.poolNamespace == Self.otherIdentityPool.keyComponent }?.user,
            "user:sub-alice",
            "the A' record is remembered as alice's"
        )
        XCTAssertEqual(carriedRecord(try store(Self.bothPools).readCarryingForward(work))?.record.username, "alice")
        let revocable = try store(Self.bothPools).copiesToRevoke(of: work, revoking: FakePayload.signedIn("alice").data)
        XCTAssertEqual(revocable, [rotated.data], "the rotated A' token is revoked")
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertNil(keychain.value(account(Self.otherIdentityPool)), "the A' record is swept")
        XCTAssertEqual(try store(Self.otherIdentityPool).readCarryingForward(work), .absent)
        XCTAssertNotEqual(try store(atB).read(work), .absent, "bob's record is his")
    }

    /// The purge variant: another user's purge at B keeps the marker with the copies it left, so the first user's
    /// later sign-out still reaches her record, and her interrupted sign-in.
    ///
    /// - Given: alice at A (both pools), carried to A' (the same user pool, another identity pool), with an interrupted
    ///   sign-in of hers left at A'; then bob signs in at B (another user pool, not carried)
    /// - When: bob's session is purged at B, in this app; the app rolls back to A, where alice signs out; then it
    ///   restores at A'
    /// - Then:
    ///    - bob's purge deletes his record, keeps the marker (naming B, where nothing is left) with alice's copies,
    ///      and leaves alice's A' record and interrupted sign-in; a restore at B reads `.absent`
    ///    - at A alice is signed in; her sign-out sweeps the A' record and her interrupted sign-in there
    ///    - at A' the session reads `.absent`
    func testAnotherUsersPurgeKeepsTheEarlierUsersCopies() throws {
        let atB = PoolNamespace.userPool("us-east-1_Other9999")
        let atA = try ran(.signedIn("alice"), under: Self.bothPools)
        guard case .record(let carried) = try store(Self.otherIdentityPool).readCarryingForward(work) else {
            return XCTFail("not carried")
        }
        let atAPrime = try carried.encoded()
        let challengeAtAPrime = SessionRecordKey.account(for: work, in: Self.otherIdentityPool, kind: .challenge)
        keychain.put(Data("interrupted".utf8), challengeAtAPrime)
        try store(atB).write(FakePayload.signedIn("bob", kind: .userPoolOnly).record(), for: work, expecting: nil)

        try store(atB).purge(work)

        XCTAssertEqual(try store(atB).read(work), .absent)
        XCTAssertEqual(
            try marker(),
            Marker(poolNamespace: atB.keyComponent, copies: [copy(Self.bothPools, atA), copy(Self.otherIdentityPool, atAPrime)], user: nil),
            "kept, naming B, with no user and only alice's copies"
        )
        XCTAssertEqual(keychain.value(account(Self.otherIdentityPool)), atAPrime)
        XCTAssertNotNil(keychain.value(challengeAtAPrime), "alice's interrupted sign-in is not bob's to delete")
        XCTAssertEqual(try store(atB).readCarryingForward(work), .absent, "the kept marker carries nothing")

        XCTAssertEqual(carriedRecord(try store(Self.bothPools).readCarryingForward(work))?.record.username, "alice")
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertNil(keychain.value(account(Self.otherIdentityPool)), "her A' record is swept")
        XCTAssertNil(keychain.value(challengeAtAPrime), "and her interrupted sign-in there")
        XCTAssertEqual(try store(Self.otherIdentityPool).readCarryingForward(work), .absent)
    }

    /// A purge with no copies left deletes the marker, as before: this guards the "always keep the marker" mutation.
    ///
    /// - Given: alice carried from the user pool alone into both pools
    /// - When: alice's session is purged under both pools
    /// - Then: her copy is swept, and the marker is deleted
    func testAPurgeWithNoCopiesLeftDeletesTheMarker() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)

        try store(Self.bothPools).purge(work)

        XCTAssertNil(keychain.value(account(Self.userPoolOnly)))
        XCTAssertNil(keychain.value(markerAccount))
    }

    /// A purge whose sweep leaves only copies with no recorded user (an earlier build's, which nothing ever sweeps)
    /// deletes the marker: those copies are inert.
    ///
    /// - Given: alice under the user pool alone and under both pools, and an earlier build's marker naming both pools
    ///   and remembering the user-pool record as a copy with no user
    /// - When: the session is purged under both pools
    /// - Then: the marker is deleted, and the user-pool record is left
    func testAPurgeLeavingOnlyCopiesWithNoUserDeletesTheMarker() throws {
        let old = try plant(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn("alice"), under: Self.bothPools)
        try store(Self.bothPools).writeMarker(
            Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, old, unrecorded: true)]),
            for: work
        )

        try store(Self.bothPools).purge(work)

        XCTAssertNil(keychain.value(markerAccount))
        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), old)
    }

    /// A purge whose sweep leaves copies with and without a recorded user keeps the marker with only the recorded
    /// ones: the others are inert.
    ///
    /// - Given: bob's record under both pools; alice's record under the user pool alone and carol's under another
    ///   identity pool; a marker naming both pools (bob's) and remembering alice's record with her user and carol's
    ///   with none
    /// - When: bob's session is purged under both pools
    /// - Then: the marker names both pools, with no user, and only alice's copy; both other records are left
    func testAPurgeKeepsOnlyTheCopiesWithARecordedUser() throws {
        let alice = try plant(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        let carol = try plant(.signedIn("carol"), under: Self.otherIdentityPool)
        try plant(.signedIn("bob"), under: Self.bothPools)
        try store(Self.bothPools).writeMarker(
            Marker(
                poolNamespace: Self.bothPools.keyComponent,
                copies: [copy(Self.userPoolOnly, alice), copy(Self.otherIdentityPool, carol, unrecorded: true)],
                user: "user:sub-bob"
            ),
            for: work
        )

        try store(Self.bothPools).purge(work)

        XCTAssertEqual(try marker(), Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, alice)], user: nil))
        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), alice)
        XCTAssertEqual(keychain.value(account(Self.otherIdentityPool)), carol)
    }

    /// A purge under an older configuration than the one the marker names rewrites the kept marker to name the purged
    /// namespace, so nothing is carried back into it.
    ///
    /// - Given: alice at A0 (a user pool alone), carried to A (that user pool with the identity pool); bob at B (the
    ///   other user pool with the identity pool), which remembers alice's A; B carried into C (bob's user pool alone)
    /// - When: the session is purged at B, with no live client (the older configuration than C)
    /// - Then:
    ///    - the marker names B, with no user, and keeps only alice's copies; a listing at B shows no row,
    ///      `signedInUserIds` counts nobody, and a restore at B reads `.absent`
    ///    - C's record is left, a session of its own: restored at C, it reads bob, and the marker then names C, with
    ///      alice's copies
    ///    - at A, alice is signed in; her sign-out there sweeps her A0 copy
    func testAPurgeUnderAnOlderConfigurationKeepsAMarkerNamingIt() throws {
        let atA0 = PoolNamespace.userPool("us-east-1_Other9999")
        let atA = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Other9999", identityPoolId: Self.identityPoolId)
        let atB = Self.bothPools
        let atC = Self.userPoolOnly
        let alice0 = try ran(.signedIn("alice", kind: .userPoolOnly), under: atA0)
        guard case .record(let carried) = try store(atA).readCarryingForward(work) else {
            return XCTFail("alice not carried to A")
        }
        let aliceAtA = try carried.encoded()
        try store(atB).write(FakePayload.signedIn("bob").record(), for: work, expecting: nil)
        XCTAssertEqual(carriedRecord(try store(atC).readCarryingForward(work))?.record.username, "bob", "B carries into C")
        XCTAssertEqual(try marker()?.poolNamespace, atC.keyComponent)

        try store(atB).purge(work)

        XCTAssertEqual(
            try marker(),
            Marker(poolNamespace: atB.keyComponent, copies: [copy(atA0, alice0), copy(atA, aliceAtA)], user: nil),
            "the kept marker names B, with no user, and only alice's copies"
        )
        XCTAssertEqual(try store(atB).storedSessions(includingSignedOut: true), [])
        XCTAssertEqual(try store(atB).signedInUserIds { _ in nil }, [:])
        XCTAssertEqual(try store(atB).readCarryingForward(work), .absent)
        XCTAssertEqual(carriedRecord(try store(atC).read(work))?.record.username, "bob", "C's record is left")
        XCTAssertEqual(carriedRecord(try store(atC).readCarryingForward(work))?.record.username, "bob", "restored at C")
        XCTAssertEqual(
            try marker(),
            Marker(poolNamespace: atC.keyComponent, copies: [copy(atA0, alice0), copy(atA, aliceAtA)], user: "user:sub-bob"),
            "the marker then names C, bob's, with alice's copies"
        )

        XCTAssertEqual(carriedRecord(try store(atA).readCarryingForward(work))?.record.username, "alice")
        XCTAssertEqual(try store(atA).signOut(work), .signedOut)
        XCTAssertNil(keychain.value(account(atA0)), "her A0 copy is still swept by her own sign-out")
    }

    /// The `readKept` side end to end: a restore over another user's existing record remembers the record the marker
    /// names as its own user's, and that user's sign-out later sweeps it.
    ///
    /// - Given: bob's record at B (another user pool), which this app did not start (no marker of it); alice at A (both
    ///   pools), carried to A' (the same user pool, another identity pool)
    /// - When: the app restores the session at B over bob's record; then rolls back to A, where alice signs out; then
    ///   restores at A'
    /// - Then: the restore at B reads bob and remembers the A' record as alice's; alice's sign-out at A sweeps it;
    ///   A' reads `.absent`; bob's record is left
    func testARestoreOverAnotherUsersRecordRemembersTheNamedRecordForItsUser() throws {
        let atB = PoolNamespace.userPool("us-east-1_Other9999")
        let bob = try plant(.signedIn("bob", kind: .userPoolOnly), under: atB)
        try ran(.signedIn("alice"), under: Self.bothPools)
        guard case .record(let carried) = try store(Self.otherIdentityPool).readCarryingForward(work) else {
            return XCTFail("not carried")
        }
        let atAPrime = try carried.encoded()

        XCTAssertEqual(carriedRecord(try store(atB).readCarryingForward(work))?.record.username, "bob")
        XCTAssertTrue(
            try marker()?.copies.contains(Marker.Copy(
                poolNamespace: Self.otherIdentityPool.keyComponent,
                sha256: SessionRecordStore.digest(atAPrime),
                user: "user:sub-alice"
            )) == true,
            "the A' record is remembered as alice's"
        )
        XCTAssertEqual(carriedRecord(try store(Self.bothPools).readCarryingForward(work))?.record.username, "alice")
        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertNil(keychain.value(account(Self.otherIdentityPool)), "her A' record is swept")
        XCTAssertEqual(try store(Self.otherIdentityPool).readCarryingForward(work), .absent)
        XCTAssertEqual(keychain.value(account(atB)), bob, "bob's record is his")
    }

    /// A revoke, like a sweep, takes only the copies recorded as the session's user's.
    ///
    /// - Given: alice at A (both pools) with her own refresh token; bob signs in at A' (the same user pool), which
    ///   remembers alice's A record as her copy
    /// - When: the copies to revoke are listed for bob's sign-out
    /// - Then: none: alice's copy is not bob's to revoke
    func testACopyOfAnotherUserIsNeverRevoked() throws {
        var alice = FakePayload.signedIn("alice")
        alice.refreshToken = "refresh-alice-at-a"
        try ran(alice, under: Self.bothPools)
        let bob = FakePayload.signedIn("bob", kind: .userPoolOnly)
        try store(Self.otherIdentityPool).write(bob.record(), for: work, expecting: nil)
        XCTAssertEqual(try marker()?.copies.map(\.user), ["user:sub-alice"], "alice's copy is remembered")

        XCTAssertEqual(try store(Self.otherIdentityPool).copiesToRevoke(of: work, revoking: bob.data), [])
    }

    /// A copy of an earlier build's marker records no user: nothing proves whose it is, so no sweep takes it.
    ///
    /// - Given: alice under the user pool alone and under both pools, and an earlier build's marker naming both pools
    ///   and remembering the user-pool record as a copy with no user
    /// - When: alice signs out under both pools
    /// - Then: the user-pool record is kept, and the marker still remembers it
    func testAnEarlierBuildsCopyWithNoUserIsNeverSwept() throws {
        let old = try plant(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn("alice"), under: Self.bothPools)
        let earlier = Data(#"{"copies":[{"poolNamespace":"\#(Self.userPoolOnly.keyComponent)","sha256":"\#(SessionRecordStore.digest(old))"}],"poolNamespace":"\#(Self.bothPools.keyComponent)","schemaVersion":1}"#.utf8)
        keychain.put(earlier, markerAccount)
        XCTAssertEqual(try marker()?.copies.first?.user, nil, "an earlier build's marker decodes, with no user")

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), old)
        XCTAssertEqual(try marker()?.copies, [copy(Self.userPoolOnly, old, unrecorded: true)])
    }

    /// The marker's users are additive keys: a marker with them decodes as the same schema, and one without them (an
    /// earlier build's) decodes with none.
    ///
    /// - Given: a marker recording users, encoded; and an earlier build's bytes
    /// - When: each is decoded
    /// - Then: the users round-trip; the earlier one reads with no users, and is readable (not `.unreadable`)
    func testTheMarkersUsersAreAdditiveKeys() throws {
        let recorded = Marker(
            poolNamespace: Self.bothPools.keyComponent,
            copies: [Marker.Copy(poolNamespace: Self.userPoolOnly.keyComponent, sha256: "digest", user: "user:sub-alice")],
            user: "user:sub-alice"
        )
        try store(Self.bothPools).writeMarker(recorded, for: work)
        XCTAssertEqual(try marker(), recorded)
        XCTAssertEqual(Marker.currentSchemaVersion, 1, "additive: the schema stays")
        keychain.put(Data(#"{"copies":[],"poolNamespace":"a","schemaVersion":1}"#.utf8), markerAccount)
        XCTAssertEqual(try store(Self.bothPools).readMarker(for: work), .marker(Marker(poolNamespace: "a")))
    }

    /// Switching between two configurations that do not carry into each other, again and again, with a sign-in and a
    /// sign-out in each, keeps each configuration's record, and the marker follows the last start.
    ///
    /// - Given: two namespaces with different user pools, P (both pools) and Q
    /// - When: alice signs in at P; the app switches to Q, where bob signs in; back to P; alice signs out; to Q; bob
    ///   signs out; back to P, where alice signs in again; to Q
    /// - Then: after every step, each namespace's record is what that configuration last wrote, and the marker names
    ///   the namespace last kept, remembering the other configuration's record, if any, as its own user's
    func testRepeatedSwitchingKeepsEachConfigurationsRecord() throws {
        let p = Self.bothPools
        let q = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Other9999", identityPoolId: Self.identityPoolId)
        func state(_ pools: PoolNamespace) throws -> String {
            switch try store(pools).read(work) {
            case .absent: return "absent"
            case .record(let envelope): return envelope.record.isSignedOut ? "signed out" : envelope.record.username ?? "?"
            default: return "other"
            }
        }
        func assertState(
            _ atP: String,
            _ atQ: String,
            marker named: PoolNamespace,
            copies expected: [PoolNamespace] = [],
            _ step: String,
            line: UInt = #line
        ) throws {
            XCTAssertEqual(try state(p), atP, step, line: line)
            XCTAssertEqual(try state(q), atQ, step, line: line)
            let stored = try XCTUnwrap(try marker(), step, line: line)
            XCTAssertEqual(stored.poolNamespace, named.keyComponent, step, line: line)
            // Exactly the expected copies, each the other configuration's, recorded as that configuration's user
            // (alice's at P, bob's at Q), at most one per namespace.
            XCTAssertEqual(stored.copies.map(\.poolNamespace), expected.map(\.keyComponent), step, line: line)
            for pools in [p, q] {
                XCTAssertLessThanOrEqual(stored.copies.count(where: { $0.poolNamespace == pools.keyComponent }), 1, step, line: line)
            }
            for copy in stored.copies {
                let user = copy.poolNamespace == p.keyComponent ? "user:sub-alice" : "user:sub-bob"
                XCTAssertEqual(copy.user, user, step, line: line)
            }
        }
        func restore(_ pools: PoolNamespace) throws {
            _ = try store(pools).readCarryingForward(work)
        }
        func signIn(_ username: String, at pools: PoolNamespace) throws {
            let expecting: UInt64?
            if case .record(let envelope) = try store(pools).read(work) {
                expecting = envelope.generation
            } else {
                expecting = nil
            }
            try store(pools).write(FakePayload.signedIn(username).record(), for: work, expecting: expecting)
        }

        try signIn("alice", at: p)
        try assertState("alice", "absent", marker: p, "alice at P")
        XCTAssertEqual(try marker()?.user, "user:sub-alice", "the marker records whose session it names")
        try restore(q)
        try assertState("alice", "absent", marker: p, "switched to Q")
        try signIn("bob", at: q)
        try assertState("alice", "bob", marker: q, copies: [p], "bob at Q: alice's record at P remembered as hers")
        try restore(p)
        try assertState("alice", "bob", marker: p, copies: [q], "back at P: bob's record at Q remembered as his")
        XCTAssertEqual(try store(p).signOut(work), .signedOut)
        try assertState("signed out", "bob", marker: p, copies: [q], "alice signed out at P: bob's copy is not hers")
        try restore(q)
        try assertState("signed out", "bob", marker: q, "switched to Q again")
        XCTAssertEqual(try store(q).signOut(work), .signedOut)
        try assertState("signed out", "signed out", marker: q, "bob signed out at Q")
        try restore(p)
        try signIn("alice", at: p)
        try assertState("alice", "signed out", marker: p, "alice again at P")
        try restore(q)
        try assertState("alice", "signed out", marker: p, "switched to Q a third time")
    }

    /// The copies a sign-out revokes are only those under this configuration's user pool: a copy under another pool
    /// is not this pool's to revoke.
    ///
    /// - Given: alice under another user pool with her own refresh token, remembered as a copy by her sign-in under
    ///   both pools (the same `userId`)
    /// - When: the copies to revoke are listed for a sign-out revoking her both-pools credentials
    /// - Then: none
    func testACopyUnderAnotherUserPoolIsNotRevoked() throws {
        let otherUserPool = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Other9999", identityPoolId: Self.identityPoolId)
        var elsewhere = FakePayload.signedIn("alice")
        elsewhere.refreshToken = "refresh-alice-other-pool"
        let old = try ran(elsewhere, under: otherUserPool)
        let own = FakePayload.signedIn("alice", version: 2)
        try store(Self.bothPools).write(own.record(), for: work, expecting: nil)
        XCTAssertEqual(try marker()?.copies, [copy(otherUserPool, old)], "remembered")

        XCTAssertEqual(try store(Self.bothPools).copiesToRevoke(of: work, revoking: own.data), [])
    }

    /// - Given: a signed-out row under both pools, and no marker
    /// - When: the row is read, and another signed-out row (a label on an absent session) is created
    /// - Then: no marker is written
    func testASignedOutRowWritesNoMarker() throws {
        try store(Self.bothPools).write(.signedOut(label: "Work", username: "alice"), for: work, expecting: nil)
        try store(Self.bothPools).write(.signedOut(label: "Home", username: nil), for: ClientFixtures.id("home"), expecting: nil)

        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertNil(keychain.value(markerAccount))
        XCTAssertNil(keychain.value(SessionRecordKey.markerAccount(for: ClientFixtures.id("home"), scope: TestKeychain.markerScope)))
    }

    /// A marker this build cannot read, from a corrupt write or a newer build, carries nothing and is never
    /// overwritten.
    ///
    /// - Given: alice's record under the user pool, and in turn a corrupt marker and a newer schema's marker naming it
    /// - When: the user pool + identity pool store reads the session, then a record is created under both pools
    /// - Then: `.absent`, and the marker bytes are unchanged throughout
    func testAnUnreadableMarkerCarriesNothingAndIsNeverOverwritten() throws {
        let markers = [
            Data("not a marker".utf8),
            Data(#"{"schemaVersion":2,"poolNamespace":"\#(Self.userPoolOnly.keyComponent)"}"#.utf8)
        ]
        for data in markers {
            keychain = TestKeychain()
            try plant(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
            keychain.put(data, markerAccount)

            XCTAssertEqual(try store(Self.bothPools).readMarker(for: work), .unreadable)
            XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)
            try store(Self.bothPools).write(FakePayload.signedIn("bob").record(), for: work, expecting: nil)
            XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

            XCTAssertEqual(keychain.value(markerAccount), data)
        }
    }

    // MARK: Failures

    /// - Given: alice's record under the user pool with the marker, and reads of that record failing
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it throws `storageUnavailable`; nothing is written, the old record and the marker are unchanged
    func testAFailedReadOfTheRecordedRecordFails() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failingReads(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).readCarryingForward(work) }

        keychain.clearFailures()
        XCTAssertEqual(try store(Self.bothPools).read(work), .absent)
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
        XCTAssertEqual(try marker()?.poolNamespace, Self.userPoolOnly.keyComponent)
    }

    /// - Given: alice's record under the user pool with the marker, and reads of the marker failing
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it throws `storageUnavailable`
    func testAFailedReadOfTheMarkerFails() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failingReads(of: markerAccount, with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).readCarryingForward(work) }
    }

    /// - Given: alice's record under the user pool with the marker, and every write failing
    /// - When: the user pool + identity pool store reads the session
    /// - Then: it throws; nothing is carried, and the old record is kept
    func testAFailedWriteWhileCarryingKeepsTheOldRecord() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failing(.write, with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).readCarryingForward(work) }

        keychain.clearFailures()
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
        XCTAssertEqual(try store(Self.bothPools).read(work), .absent)
    }

    /// A marker write that fails after the carried record committed does not fail the carry.
    ///
    /// - Given: alice's record under the user pool with the marker, and writes of the marker failing
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the record is carried, and the marker still names the user pool (logged, not thrown)
    func testAFailedMarkerWriteAfterTheCarryStillCarries() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failingSets(of: markerAccount, with: errSecInteractionNotAllowed)

        XCTAssertNotNil(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        keychain.clearFailures()
        XCTAssertEqual(try marker()?.poolNamespace, Self.userPoolOnly.keyComponent)
    }

    // MARK: Races

    /// - Given: alice's record under the user pool with the marker, rewritten right after the carry reads it
    ///   (another process still on the old configuration)
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the first version is carried; the rewritten record is kept; the marker's digest is the first
    ///   version's, so a sweep will leave the rewritten one
    func testAnOldRecordThatChangedDuringTheCarryIsKept() throws {
        let first = FakePayload.signedIn("alice", kind: .userPoolOnly)
        let firstBytes = try ran(first, under: Self.userPoolOnly)
        let rewritten = try SessionRecordEnvelope(
            generation: 9,
            lastWriteTimestamp: Date(),
            record: FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2).record()
        ).encoded()
        let oldAccount = account(Self.userPoolOnly)
        keychain.onceAfterReading(oldAccount) { [keychain] in keychain?.put(rewritten, oldAccount) }

        let envelope = try XCTUnwrap(carriedRecord(try store(Self.bothPools).readCarryingForward(work)))

        XCTAssertEqual(FakePayload.decode(try XCTUnwrap(envelope.record.credentials))?.version, first.version, "the first version is carried")
        XCTAssertEqual(keychain.value(oldAccount), rewritten)
        XCTAssertEqual(try marker()?.copies, [copy(Self.userPoolOnly, firstBytes)])
    }

    /// - Given: alice's record under the user pool with the marker, and another process purging it under the old
    ///   configuration right after the carry reads it (two stores)
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the carry is undone: `.absent`, and no record under either namespace
    func testAPurgeRacingTheCarryUndoesIt() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        let purger = store(Self.userPoolOnly, scope: "another-process-0")
        let work = work
        keychain.onceAfterReading(account(Self.userPoolOnly), occurrence: 1) { _ = try? purger.purge(work) }

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)

        XCTAssertEqual(try store(Self.bothPools).read(work), .absent, "the carried record is deleted")
        XCTAssertEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// - Given: alice's record under the user pool with the marker, and another process signing her out under the old
    ///   configuration right after the carry reads it
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the carry is undone: `.absent`, and no record under both pools
    func testASignOutRacingTheCarryUndoesIt() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        let signer = store(Self.userPoolOnly, scope: "another-process-0")
        let work = work
        keychain.onceAfterReading(account(Self.userPoolOnly), occurrence: 1) { _ = try? signer.signOut(work) }

        XCTAssertEqual(try store(Self.bothPools).readCarryingForward(work), .absent)

        XCTAssertEqual(try store(Self.bothPools).read(work), .absent, "the carried record is deleted")
    }

    /// - Given: the purge race above, and a sign-in replacing the carried record before the undo checks it
    /// - When: the user pool + identity pool store reads the session
    /// - Then: the newer record is left, and returned
    func testUndoingTheCarryLeavesANewerRecord() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        let oldAccount = account(Self.userPoolOnly)
        let newStore = store(Self.bothPools)
        let purger = store(Self.userPoolOnly, scope: "another-process-0")
        let work = work
        let reads = ReadCount()
        keychain.afterEveryRead(of: oldAccount) {
            switch reads.next() {
            case 1:
                _ = try? purger.purge(work)
            case 2:
                if case .record(let envelope) = try? newStore.read(work) {
                    _ = try? newStore.write(FakePayload.signedIn("bob").record(), for: work, expecting: envelope.generation)
                }
            default:
                break
            }
        }
        defer { keychain.afterEveryRead(of: oldAccount, nil) }

        let envelope = try XCTUnwrap(carriedRecord(try newStore.readCarryingForward(work)))

        XCTAssertEqual(envelope.record.username, "bob")
    }

    /// - Given: alice's record under the user pool with the marker, and another writer storing bob's record under
    ///   both pools right after the carry reads alice's
    /// - When: the user pool + identity pool store reads the session
    /// - Then: bob's record wins, and alice's is kept
    func testAConcurrentWriteHereWins() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        let newStore = store(Self.bothPools)
        let work = work
        keychain.onceAfterReading(account(Self.userPoolOnly)) {
            _ = try? newStore.write(FakePayload.signedIn("bob").record(), for: work, expecting: nil)
        }

        let envelope = try XCTUnwrap(carriedRecord(try newStore.readCarryingForward(work)))

        XCTAssertEqual(envelope.record.username, "bob")
        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    // MARK: Sign-out, purge, listing

    /// - Given: alice carried from the user pool into both pools, and a record of the session under another identity
    ///   pool it was never kept under
    /// - When: it is signed out under both pools
    /// - Then: the untouched copy is deleted, the other record kept, and the marker remembers no copy
    func testSignOutSweepsOnlyUntouchedRememberedCopies() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn(), under: Self.otherIdentityPool)
        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(try store(Self.userPoolOnly).read(work), .absent)
        XCTAssertNotEqual(try store(Self.otherIdentityPool).read(work), .absent, "never kept there: not swept")
        XCTAssertEqual(try marker()?.copies, [])
    }

    /// A copy of another user is never swept, even if the marker remembers it (a marker from an earlier build).
    ///
    /// - Given: alice's record under both pools, and the marker remembering bob's untouched user-pool record as a copy
    /// - When: alice is signed out under both pools
    /// - Then: bob's record is left
    func testASweepLeavesACopyOfAnotherUser() throws {
        let bob = try plant(.signedIn("bob", kind: .userPoolOnly), under: Self.userPoolOnly)
        try plant(.signedIn("alice"), under: Self.bothPools)
        try store(Self.bothPools).writeMarker(Marker(poolNamespace: Self.bothPools.keyComponent, copies: [copy(Self.userPoolOnly, bob)]), for: work)

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertEqual(keychain.value(account(Self.userPoolOnly)), bob)
    }

    /// - Given: a guest carried from the identity pool alone into both pools
    /// - When: the session is signed out under both pools, then purged
    /// - Then: the guest's record under the identity pool is left both times, with its identity
    func testASweepLeavesAGuestsCopy() throws {
        let guest = try ran(.guest(identityId: "us-east-1:guest-1"), under: Self.identityPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)
        try store(Self.bothPools).purge(work)

        XCTAssertEqual(keychain.value(account(Self.identityPoolOnly)), guest)
    }

    /// - Given: alice carried from the user pool into both pools, and deletes of the copy failing
    /// - When: it is signed out under both pools, then purged
    /// - Then: the sign-out succeeds (the row is signed out) and remembers the copy; the purge deletes it
    func testAFailedSweepDoesNotFailTheSignOut() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        keychain.failingRemovals(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)

        XCTAssertEqual(try store(Self.bothPools).signOut(work), .signedOut)

        XCTAssertTrue(try XCTUnwrap(carriedRecord(try store(Self.bothPools).read(work))).record.isSignedOut)
        XCTAssertEqual(try marker()?.copies.map(\.poolNamespace), [Self.userPoolOnly.keyComponent])
        keychain.clearFailures()
        try store(Self.bothPools).purge(work)
        XCTAssertEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// - Given: alice carried from the user pool into both pools
    /// - When: a sign-out is superseded (another sign-in replaced the credentials it would remove)
    /// - Then: the copy is kept
    func testASupersededSignOutKeepsTheCopies() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)

        XCTAssertEqual(try store(Self.bothPools).signOut(work, removing: Data("other".utf8)), .superseded)

        XCTAssertNotEqual(try store(Self.userPoolOnly).read(work), .absent)
    }

    /// - Given: alice carried from the user pool into both pools
    /// - When: the session is purged under both pools
    /// - Then: the copy is deleted before the session's own record, and the marker last
    func testPurgeRemovesUntouchedCopiesFirstAndTheMarkerLast() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        keychain.resetLogs()

        try store(Self.bothPools).purge(work)

        let removed = keychain.removedAccounts
        XCTAssertLessThan(try XCTUnwrap(removed.firstIndex(of: account(Self.userPoolOnly))), try XCTUnwrap(removed.firstIndex(of: account(Self.bothPools))))
        XCTAssertEqual(removed.last, markerAccount)
        XCTAssertNil(keychain.value(markerAccount))
    }

    /// - Given: alice carried from the user pool into both pools, and deletes of the copy failing
    /// - When: the session is purged
    /// - Then: it throws before deleting anything of its own: the session's record is intact
    func testAFailedPurgeSweepLeavesTheSessionIntact() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        _ = try store(Self.bothPools).readCarryingForward(work)
        keychain.failingRemovals(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).purge(work) }

        XCTAssertNotEqual(try store(Self.bothPools).read(work), .absent)
    }

    /// - Given: `work` under the user pool with its marker; `home` both here and marked at the identity pool;
    ///   `solo` under the user pool with no marker; `bad`, an unreadable record here with a marker naming the user
    ///   pool, which holds a record of it
    /// - When: the sessions under both pools are listed
    /// - Then: `home` once, from its own record; `work` once, as user-pool-only; no `solo`; `bad` only as
    ///   unreadable, not as a pending carry; nothing is carried
    func testListingShowsAPendingCarryOnce() throws {
        let home = ClientFixtures.id("home")
        let solo = ClientFixtures.id("solo")
        let bad = ClientFixtures.id("bad")
        try ran(.signedIn("alice", kind: .userPoolOnly), label: "Work", under: Self.userPoolOnly)
        try store(Self.bothPools).write(FakePayload.signedIn("bob").record(label: "Home"), for: home, expecting: nil)
        try plant(.guest(), for: home, under: Self.identityPoolOnly)
        try store(Self.identityPoolOnly).writeMarker(Marker(poolNamespace: Self.identityPoolOnly.keyComponent), for: home)
        try plant(.signedIn("carol", kind: .userPoolOnly), for: solo, under: Self.userPoolOnly)
        keychain.put(StorageFixtures.corruptRecord, account(Self.bothPools, bad))
        try plant(.signedIn("dave", kind: .userPoolOnly), for: bad, under: Self.userPoolOnly)
        try store(Self.userPoolOnly).writeMarker(Marker(poolNamespace: Self.userPoolOnly.keyComponent), for: bad)

        let listing = try store(Self.bothPools).listing()

        XCTAssertEqual(listing.sessions, [
            StoredSession(sessionId: home, label: "Home", username: "bob", kind: .userPoolAndIdentityPool),
            StoredSession(sessionId: work, label: "Work", username: "alice", kind: .userPoolOnly)
        ])
        XCTAssertEqual(listing.unreadable, [bad: .corrupt])
        XCTAssertEqual(try store(Self.bothPools).read(work), .absent, "listing carries nothing")
    }

    /// - Given: a pending carry whose marker cannot be read
    /// - When: the sessions under both pools are listed
    /// - Then: the listing throws
    func testAFailedMarkerReadFailsTheListing() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failingReads(of: markerAccount, with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).storedSessions() }
    }

    /// - Given: a pending carry whose recorded record cannot be read
    /// - When: the sessions under both pools are listed
    /// - Then: the listing throws: a missing row could be the only signed-in one
    func testAFailedPendingRecordReadFailsTheListing() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)
        keychain.failingReads(of: account(Self.userPoolOnly), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store(Self.bothPools).storedSessions() }
    }

    /// - Given: alice under the user pool with the marker, waiting to be carried into both pools
    /// - When: the signed-in user IDs under both pools are listed (a hosted-UI sign-in's distinctness check)
    /// - Then: `work` counts, as alice
    func testSignedInUserIdsCountAPendingCarry() throws {
        try ran(.signedIn("alice", kind: .userPoolOnly), under: Self.userPoolOnly)

        let userIds = try store(Self.bothPools).signedInUserIds { _ in nil }

        XCTAssertEqual(userIds, [work: "sub-alice"])
    }

    // MARK: Formats

    /// - Given: a marker account
    /// - When: it is parsed as a session record, and as a marker of this app and of another
    /// - Then: never a session record; a marker only for its own scope
    func testAMarkerAccountIsNeverReadAsASessionRecord() {
        let account = SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
        XCTAssertNil(SessionRecordKey.parse(account))
        XCTAssertEqual(SessionRecordKey.parseMarker(account, scope: TestKeychain.markerScope), work)
        XCTAssertNil(SessionRecordKey.parseMarker(account, scope: "another-scope-00"))
        XCTAssertNil(SessionRecordKey.parseMarker(SessionRecordKey.account(for: work, in: Self.bothPools, kind: .session), scope: TestKeychain.markerScope))
        XCTAssertEqual(SessionRecordKey.parseMarker(SessionRecordKey.markerAccount(for: .default, scope: "s"), scope: "s"), .default)
    }

    /// - Given: each namespace's rendered component, and malformed ones
    /// - When: parsed back
    /// - Then: each namespace round-trips; the malformed ones are `nil`
    func testPoolNamespaceParsesItsKeyComponent() {
        for pools in [Self.bothPools, Self.userPoolOnly, Self.identityPoolOnly] {
            XCTAssertEqual(PoolNamespace(keyComponent: pools.keyComponent), pools)
        }
        for invalid in ["", ".", "a.b.c", "\(Self.identityPoolId).\(Self.userPoolId)", "\(Self.userPoolId).", ".\(Self.identityPoolId)"] {
            XCTAssertNil(PoolNamespace(keyComponent: invalid), invalid)
        }
    }

    /// - Given: a marker, kept under one namespace after another, remembering a copy each time
    /// - When: its copies are read
    /// - Then: every one, oldest first, one per namespace (the latest), never the current namespace
    func testTheMarkerRemembersOneCopyPerNamespace() {
        var marker = Marker(poolNamespace: "a")
        for (next, previous) in [("b", "a"), ("c", "b"), ("a", "c"), ("d", "a"), ("e", "d"), ("f", "e")] {
            marker = marker.keptHere(next, user: nil, remembering: Marker.Copy(poolNamespace: previous, sha256: previous))
        }
        XCTAssertEqual(marker.poolNamespace, "f")
        XCTAssertEqual(marker.copies.map(\.poolNamespace), ["b", "c", "a", "d", "e"])
        XCTAssertEqual(marker.keptHere("f", user: nil), marker)
        XCTAssertEqual(marker.keptHere("c", user: nil).copies.map(\.poolNamespace), ["b", "a", "d", "e"])
    }

    /// - Given: the plugin's stored format in each shape
    /// - When: each is reduced to its user pool tokens
    /// - Then: user-pool-only stays as it is; user pool + identity pool becomes user-pool-only with the same
    ///   signed-in data; the identity-only shapes have none
    func testTheLiveRewriteKeepsOnlyTheUserPoolTokens() throws {
        let userPoolOnly = try EnginePayloadFixtures.data("userPoolOnly")
        let both = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        XCTAssertEqual(try CredentialSlot.userPoolTokensOnly(userPoolOnly), userPoolOnly)
        let reduced = try XCTUnwrap(CredentialSlot.userPoolTokensOnly(both))
        guard case .userPoolOnly(let signedInData) = try CredentialSlot.decode(reduced),
              case .userPoolAndIdentityPool(let original, _, _) = try CredentialSlot.decode(both) else {
            return XCTFail("expected user-pool-only credentials")
        }
        XCTAssertEqual(signedInData, original)
        for caseName in ["identityPoolOnly", "identityPoolWithFederation", "noCredentials"] {
            XCTAssertNil(try CredentialSlot.userPoolTokensOnly(EnginePayloadFixtures.data(caseName)), caseName)
        }
    }

    /// - Given: a record, not pending and then pending
    /// - When: each is encoded and decoded
    /// - Then: `identityPending` is written only when set, and round-trips
    func testIdentityPendingIsStoredOnlyWhenSet() throws {
        var record = FakePayload.signedIn(kind: .userPoolOnly).record()
        let plain = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: Date(), record: record).encoded()
        XCTAssertFalse(String(decoding: plain, as: UTF8.self).contains("identityPending"))
        record.identityPending = true
        let pending = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: Date(), record: record).encoded()
        guard case .envelope(let decoded) = SessionRecordEnvelope.decode(pending) else {
            return XCTFail("the record did not decode")
        }
        XCTAssertTrue(decoded.record.identityPending)
    }
}

/// Counts calls from a keychain hook.
private final class ReadCount: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.withLock {
            count += 1
            return count
        }
    }
}
