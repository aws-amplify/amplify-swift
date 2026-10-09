//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class StoredSessionsTests: XCTestCase {

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!

    private let userPoolId = StorageFixtures.userPoolId
    private let identityPoolId = StorageFixtures.identityPoolId

    override func setUp() {
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
    }

    private func id(_ name: String) throws -> SessionID {
        try SessionID.named(name)
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

    /// Listing runs over a flat account namespace shared with every other record under the service.
    ///
    /// - Given: three session records for this namespace, alongside the plugin's records for other
    ///   namespaces (another pool, and this user pool alone), the stored
    ///   configuration, device metadata and ASF records, an interrupted-sign-in record, a record for
    ///   another pool, a record for this user pool alone, a `amplify.2.` record, and an account whose
    ///   session segment is not a valid ID
    /// - When: saved sessions are listed
    /// - Then:
    ///    - exactly the three are returned, ordered by session ID, and nothing is written
    func testListsOnlyThisNamespacesSessionRecords() throws {
        for name in ["work", "home", "alpha"] {
            try store.write(StorageFixtures.signedIn(username: name), for: id(name), expecting: nil)
        }
        let foreign = [
            "amplify.us-west-2_Other.\(identityPoolId).session",
            "amplify.\(userPoolId).session",
            "authConfiguration",
            "amplify.\(userPoolId).\(identityPoolId).alice.deviceMetadata",
            "amplify.1.\(userPoolId).\(identityPoolId).alice.deviceMetadata",
            "amplify.\(userPoolId).\(identityPoolId).alice.deviceASF",
            "amplify.1.\(userPoolId).\(identityPoolId).interrupted.challenge",
            "amplify.1.us-west-2_Other.\(identityPoolId).other.session",
            "amplify.1.\(userPoolId).userpoolonly.session",
            "amplify.2.\(userPoolId).\(identityPoolId).future.session",
            "amplify.1.\(userPoolId).\(identityPoolId).not valid.session"
        ]
        for account in foreign {
            keychain.put(try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: StorageFixtures.signedIn()).encoded(), account)
        }

        let sessions = try store.storedSessions()

        XCTAssertEqual(sessions.map(\.sessionId), [try id("alpha"), try id("home"), try id("work")])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// - Given: a signed-in session with a label and a guest session
    /// - When: saved sessions are listed
    /// - Then:
    ///    - each row carries the stored label, username and kind, and the guest row has no username
    func testRowsCarryTheListingMetadata() throws {
        try store.write(StorageFixtures.signedIn(label: "Acme Corp", username: "alice@corp"), for: id("work"), expecting: nil)
        try store.write(StorageFixtures.guest, for: id("browse"), expecting: nil)

        XCTAssertEqual(try store.storedSessions(), [
            StoredSession(sessionId: try id("browse"), label: nil, username: nil, kind: .guest),
            StoredSession(sessionId: try id("work"), label: "Acme Corp", username: "alice@corp", kind: .userPoolAndIdentityPool)
        ])
    }

    /// - Given: two signed-in sessions, one of which is then signed out
    /// - When: saved sessions are listed with and without `includingSignedOut`
    /// - Then:
    ///    - the default hides the signed-out row; `includingSignedOut: true` shows it with its label
    func testSignedOutRowsAreHiddenByDefault() throws {
        try store.write(StorageFixtures.signedIn(label: "Acme Corp"), for: id("work"), expecting: nil)
        try store.write(StorageFixtures.signedIn(), for: id("home"), expecting: nil)
        XCTAssertEqual(try store.signOut(id("work")), .signedOut)

        XCTAssertEqual(try store.storedSessions().map(\.sessionId), [try id("home")])
        XCTAssertEqual(try store.storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: try id("home"), label: nil, username: "alice", kind: .userPoolAndIdentityPool),
            StoredSession(sessionId: try id("work"), label: "Acme Corp", username: "alice", kind: .signedOut)
        ])
    }

    // MARK: The plugin's record, listed as `.default`

    private var pluginAccount: String {
        SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools)
    }

    private var sidecarAccount: String {
        SessionRecordKey.metaAccount(in: StorageFixtures.pools)
    }

    /// The account a development build kept `.default`'s own record under.
    private var leftoverAccount: String {
        SessionRecordKey.account(for: .default, in: StorageFixtures.pools, kind: .session)
    }

    /// The plugin fixtures' user.
    private let pluginUserId = "1234567890"
    private let pluginUsername = "alice@corp"

    private func putSidecar(label: String?, username: String?, userId: String?) throws {
        let meta = DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: label, username: username, userId: userId)
        keychain.put(try meta.encoded(), sidecarAccount)
    }

    /// `.default`'s record is the plugin's, so a migrated app's picker shows it: an empty list would offer sign-in to
    /// a signed-in user.
    ///
    /// - Given: only the plugin's record, in each of its signed-in shapes as the plugin writes them
    /// - When: saved sessions are listed
    /// - Then:
    ///    - there is one `.default` row with the mapped kind, the signed-in username for the user-pool
    ///      shapes and none otherwise, no label, and nothing is written
    func testPluginOnlyRecordIsListedAsTheDefaultSession() throws {
        let cases: [(Data, SessionKind, String?)] = [
            (PluginRecordFixtures.userPoolOnly, .userPoolOnly, "alice@corp"),
            (PluginRecordFixtures.userPoolAndIdentityPool, .userPoolAndIdentityPool, "alice@corp"),
            (PluginRecordFixtures.identityPoolOnly, .guest, nil),
            (PluginRecordFixtures.identityPoolWithFederation, .federated, nil)
        ]
        for (record, kind, username) in cases {
            keychain.put(record, pluginAccount)

            XCTAssertEqual(
                try store.storedSessions(),
                [StoredSession(sessionId: .default, label: nil, username: username, kind: kind)],
                "\(kind)"
            )
        }
        XCTAssertFalse(keychain.hasMutations)
    }

    /// - Given: the plugin's record beside named sessions
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the `.default` row sorts with the others, first since `$` precedes letters
    func testPluginRowSortsWithTheOtherRows() throws {
        try store.write(StorageFixtures.signedIn(username: "bob"), for: id("work"), expecting: nil)
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)

        XCTAssertEqual(try store.storedSessions().map(\.sessionId), [.default, try id("work")])
    }

    /// - Given: the plugin's record for alice, and a sidecar bound to alice with a label
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the `.default` row is alice's, from the plugin's record, with the sidecar's label
    func testDefaultRowComesFromTheSharedRecordWithTheSidecarsLabel() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        try putSidecar(label: "Home", username: pluginUsername, userId: pluginUserId)

        XCTAssertEqual(try store.storedSessions(), [
            StoredSession(sessionId: .default, label: "Home", username: pluginUsername, kind: .userPoolAndIdentityPool)
        ])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// The label is bound to the user: another user signed in through the plugin never shows it.
    ///
    /// - Given: the plugin's record for alice, and a sidecar bound to bob with a label
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the `.default` row is alice's, with no label, and the sidecar is left as it was
    func testDefaultRowIgnoresASidecarBoundToAnotherUser() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        try putSidecar(label: "Bob's", username: "bob", userId: "sub-bob")
        let sidecar = keychain.value(sidecarAccount)

        XCTAssertEqual(try store.storedSessions(), [
            StoredSession(sessionId: .default, label: nil, username: pluginUsername, kind: .userPoolAndIdentityPool)
        ])
        XCTAssertEqual(keychain.value(sidecarAccount), sidecar)
    }

    /// - Given: the plugin's record signed out (`{"noCredentials":{}}`), and a sidecar naming alice with a label
    /// - When: saved sessions are listed with and without `includingSignedOut`
    /// - Then:
    ///    - it is hidden by default, and shown on request as a signed-out row with the sidecar's label and alice
    func testSignedOutSharedRecordWithSidecarIsASignedOutRowWithTheLastUser() throws {
        keychain.put(PluginRecordFixtures.noCredentials, pluginAccount)
        try putSidecar(label: "Home", username: pluginUsername, userId: pluginUserId)

        XCTAssertEqual(try store.storedSessions(), [])
        XCTAssertEqual(try store.storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: .default, label: "Home", username: pluginUsername, kind: .signedOut)
        ])
    }

    /// The plugin deletes its record on its own sign-out (and on `deleteUser`); the sidecar stays.
    ///
    /// - Given: no plugin record, and a sidecar naming alice with a label
    /// - When: saved sessions are listed with `includingSignedOut: true`
    /// - Then:
    ///    - there is a signed-out `.default` row with the sidecar's label and alice
    func testAbsentSharedRecordWithSidecarIsASignedOutRow() throws {
        try putSidecar(label: "Home", username: pluginUsername, userId: pluginUserId)

        XCTAssertEqual(try store.storedSessions(), [])
        XCTAssertEqual(try store.storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: .default, label: "Home", username: pluginUsername, kind: .signedOut)
        ])
    }

    /// A development build kept `.default`'s own record under `$default`: it must never show as a ghost row.
    ///
    /// - Given: a leftover `$default.session` holding bob, a `$default` namespace marker, and no plugin record
    /// - When: saved sessions are listed with `includingSignedOut: true`
    /// - Then:
    ///    - no `.default` row is listed, and neither leftover is read
    func testLeftoverDollarDefaultRecordIsNotAGhostRow() throws {
        let envelope = SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: StorageFixtures.signedIn(username: "bob"))
        keychain.put(try envelope.encoded(), leftoverAccount)
        let marker = SessionRecordKey.markerAccount(for: .default, scope: TestKeychain.markerScope)
        keychain.put(Data(#"{"poolNamespace":"us-east-1_Other","schemaVersion":1}"#.utf8), marker)

        let listing = try store.listing()

        XCTAssertEqual(listing.sessions, [])
        XCTAssertEqual(listing.unreadable, [:])
        XCTAssertFalse(keychain.readAccounts.contains(leftoverAccount))
        XCTAssertFalse(keychain.readAccounts.contains(marker))
    }

    /// - Given: the plugin's record for alice, and a leftover `$default.session` in corrupt bytes
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the `.default` row is the plugin's record, and the leftover is neither listed nor reported unreadable
    func testALeftoverDefaultRecordNeverStandsInForThePluginRecord() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        keychain.put(StorageFixtures.corruptRecord, leftoverAccount)

        let listing = try store.listing()

        XCTAssertEqual(listing.sessions, [
            StoredSession(sessionId: .default, label: nil, username: pluginUsername, kind: .userPoolAndIdentityPool)
        ])
        XCTAssertEqual(listing.unreadable, [:])
    }

    /// - Given: only the plugin's record, holding no credentials
    /// - When: saved sessions are listed with and without `includingSignedOut`
    /// - Then:
    ///    - it is hidden by default, like any signed-out row, and shown as `.signedOut` on request
    func testPluginNoCredentialsRecordIsASignedOutRow() throws {
        keychain.put(PluginRecordFixtures.noCredentials, pluginAccount)

        XCTAssertEqual(try store.storedSessions(), [])
        XCTAssertEqual(try store.storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: .default, label: nil, username: nil, kind: .signedOut)
        ])
    }

    /// A shape this build does not know must not hide a session `.default` would read as present.
    ///
    /// - Given: a plugin record with an unknown case, with two top-level keys, that is not an object,
    ///   and that is not JSON
    /// - When: saved sessions are listed
    /// - Then:
    ///    - each is still a `.default` row, as `.userPoolOnly` with no username
    func testUnrecognisedPluginRecordIsListedConservatively() throws {
        let shapes = [
            #"{"userPoolWithPasskey":{"signedInData":{"username":"alice"}}}"#,
            #"{"userPoolOnly":{},"noCredentials":{}}"#,
            #"["userPoolOnly"]"#,
            "not json"
        ]
        for shape in shapes {
            keychain.put(Data(shape.utf8), pluginAccount)

            XCTAssertEqual(
                try store.storedSessions(),
                [StoredSession(sessionId: .default, label: nil, username: nil, kind: .userPoolOnly)],
                shape
            )
        }
        XCTAssertEqual(PluginRecordSummary.unrecognisedKind, .userPoolOnly)
    }

    /// - Given: the plugin's record, whose read fails with a locked device
    /// - When: saved sessions are listed
    /// - Then:
    ///    - it throws `.locked`, as for any row
    func testFailedPluginRecordReadThrows() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        keychain.failingReads(of: pluginAccount, with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store.storedSessions() }
    }

    /// - Given: a named session's store, and the plugin's record
    /// - When: a store for a different namespace lists
    /// - Then:
    ///    - it lists no `.default` row: only this namespace's plugin record counts
    func testAnotherNamespacesPluginRecordIsNotListed() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        let userPoolOnly = keychain.recordStore(for: SessionStorageNamespace(pools: .userPool(userPoolId), accessGroup: nil))

        XCTAssertEqual(try userPoolOnly.storedSessions(includingSignedOut: true), [])
    }

    /// - Given: an empty keychain
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the result is empty, not an error
    func testNothingSavedIsAnEmptyList() throws {
        XCTAssertEqual(try store.storedSessions(), [])
    }

    /// An empty list shows sign-in to a signed-in user, so a failed listing must never produce one.
    ///
    /// - Given: a saved session, and the listing call failing with a locked device or a misconfigured
    ///   entitlement
    /// - When: saved sessions are listed
    /// - Then:
    ///    - it throws `storageUnavailable` with the classified reason, and never returns `[]`
    func testListingFailureThrowsAndNeverReturnsEmpty() throws {
        try store.write(StorageFixtures.signedIn(), for: id("work"), expecting: nil)

        keychain.failing(.list, with: errSecInteractionNotAllowed)
        assertStorageUnavailable(.locked) { try store.storedSessions() }
        keychain.failing(.list, with: errSecMissingEntitlement)
        assertStorageUnavailable(.denied) { try store.storedSessions(includingSignedOut: true) }
    }

    /// - Given: three saved sessions, one written by a newer schema and one corrupt
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the readable one is returned, the other two are reported as unreadable with their reasons,
    ///      and nothing is written or deleted
    func testRecordsThisBuildCannotReadDoNotBlankTheList() throws {
        try store.write(StorageFixtures.signedIn(), for: id("good"), expecting: nil)
        keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: try id("future")))
        keychain.put(StorageFixtures.corruptRecord, store.sessionAccount(for: try id("broken")))
        keychain.resetLogs()

        let listing = try store.listing()

        XCTAssertEqual(listing.sessions.map(\.sessionId), [try id("good")])
        XCTAssertEqual(listing.unreadable, [
            try id("future"): .unsupportedSchema(version: 2),
            try id("broken"): .corrupt
        ])
        XCTAssertEqual(try store.storedSessions().map(\.sessionId), [try id("good")])
        XCTAssertFalse(keychain.hasMutations)
        XCTAssertEqual(keychain.value(store.sessionAccount(for: try id("future"))), StorageFixtures.futureSchemaRecord)
    }

    /// A list that silently drops a session looks complete: a picker would miss the row, or preselect
    /// nothing.
    ///
    /// - Given: two readable signed-in sessions, and a third whose read fails with a locked device
    /// - When: saved sessions are listed
    /// - Then:
    ///    - it throws `.locked` rather than returning the two
    func testOneRecordFailingToReadThrows() throws {
        try store.write(StorageFixtures.signedIn(), for: id("good"), expecting: nil)
        try store.write(StorageFixtures.signedIn(), for: id("other"), expecting: nil)
        try store.write(StorageFixtures.signedIn(), for: id("locked"), expecting: nil)
        keychain.failingReads(of: store.sessionAccount(for: try id("locked")), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store.storedSessions() }
        assertStorageUnavailable(.locked) { try store.storedSessions(includingSignedOut: true) }
        assertStorageUnavailable(.locked) { try store.listing() }
    }

    /// The only readable row is signed out, so the default filter would leave an
    /// empty list and the picker would offer sign-in to the signed-in user whose record failed to read.
    ///
    /// - Given: a readable signed-out session, and a signed-in session whose read fails with an I/O error
    /// - When: saved sessions are listed with the default filter
    /// - Then:
    ///    - it throws `.interrupted`, never `[]`
    func testFailedSignedInRowBesideAReadableSignedOutRowThrows() throws {
        try store.write(StorageFixtures.signedIn(), for: id("home"), expecting: nil)
        XCTAssertEqual(try store.signOut(id("home")), .signedOut)
        try store.write(StorageFixtures.signedIn(), for: id("work"), expecting: nil)
        keychain.failingReads(of: store.sessionAccount(for: try id("work")), with: errSecIO)

        assertStorageUnavailable(.interrupted) { try store.storedSessions() }
    }

    /// - Given: only records this build cannot read, from a newer schema
    /// - When: saved sessions are listed
    /// - Then:
    ///    - the list is empty without throwing: they are skipped, as a newer binary's records must be
    func testOnlyFutureSchemaRecordsListAsEmpty() throws {
        keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: try id("future")))

        XCTAssertEqual(try store.storedSessions(includingSignedOut: true), [])
    }

    /// An unscoped listing returns an account once per access group that holds it.
    ///
    /// - Given: two saved sessions, and a listing that returns every account twice
    /// - When: saved sessions are listed
    /// - Then:
    ///    - each session appears once
    func testDuplicateAccountsCollapseToOneRow() throws {
        try store.write(StorageFixtures.signedIn(), for: id("work"), expecting: nil)
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        keychain.listingEveryAccountTwice()

        XCTAssertEqual(try store.storedSessions().map(\.sessionId), [.default, try id("work")])
    }

    /// - Given: a session for each configuration shape sharing one user pool, over one keychain
    /// - When: each shape's store lists
    /// - Then:
    ///    - each sees only its own session, although the user-pool-only prefix is a prefix of the other
    func testNamespacesThatSharePoolIdsDoNotLeak() throws {
        let userPoolOnly = keychain.recordStore(for: SessionStorageNamespace(pools: .userPool(userPoolId), accessGroup: nil))
        try userPoolOnly.write(StorageFixtures.signedIn(), for: id("solo"), expecting: nil)
        try store.write(StorageFixtures.signedIn(), for: id("both"), expecting: nil)

        XCTAssertEqual(try userPoolOnly.storedSessions().map(\.sessionId), [try id("solo")])
        XCTAssertEqual(try store.storedSessions().map(\.sessionId), [try id("both")])
    }
}
