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

final class SessionRecordStoreTests: XCTestCase {

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!
    private var work: SessionID!

    private var workAccount: String { store.sessionAccount(for: work) }
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUpWithError() throws {
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
        work = try SessionID.named("work")
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

    /// The envelope a named session's write committed, as stored for `work`; the outcome must report the same record.
    private func committedEnvelope(_ outcome: SessionRecordStore.CommitOutcome) throws -> SessionRecordEnvelope {
        guard case .committed(let committed) = outcome,
              let data = keychain.value(workAccount),
              case .envelope(let envelope) = SessionRecordEnvelope.decode(data) else {
            throw UnexpectedResult("expected a commit, got \(outcome)")
        }
        XCTAssertEqual(committed, VersionedSessionRecord(envelope))
        return envelope
    }

    private func storedEnvelope(_ sessionId: SessionID) throws -> VersionedSessionRecord {
        let result = try store.read(sessionId)
        guard case .record(let envelope) = result else {
            throw UnexpectedResult("expected a readable record for \(sessionId), got \(result)")
        }
        return envelope
    }

    // MARK: Service and key identity

    /// The services are part of key identity: records are siblings of the plugin's only while these
    /// strings match the plugin's exactly.
    ///
    /// - Given: the store's service names
    /// - When: they are read, with and without an access group
    /// - Then:
    ///    - they equal the Auth plugin's literals
    func testServicesMatchThePlugin() {
        XCTAssertEqual(SessionRecordStore.service(forAccessGroup: nil), "com.amplify.awsCognitoAuthPlugin")
        XCTAssertEqual(SessionRecordStore.service(forAccessGroup: "group.acme"), "com.amplify.awsCognitoAuthPluginShared")
    }

    /// - Given: two stores for the same pools, one per access group, over one keychain
    /// - When: each writes a record for the same session ID
    /// - Then:
    ///    - each reads back only its own, because every operation is scoped to the access group
    func testAccessGroupScopesEveryOperation() throws {
        let groupA = keychain.recordStore(for: SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: "group.a"))
        let groupB = keychain.recordStore(for: SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: "group.b"))

        try groupA.write(StorageFixtures.signedIn(username: "alice"), for: work, expecting: nil)
        XCTAssertEqual(try groupB.read(work), .absent)
        try groupB.write(StorageFixtures.signedIn(username: "bob"), for: work, expecting: nil)
        try groupA.purge(work)

        XCTAssertEqual(try groupA.read(work), .absent)
        guard case .record(let envelope) = try groupB.read(work) else {
            return XCTFail("group B's record should survive group A's purge")
        }
        XCTAssertEqual(envelope.record.username, "bob")
    }

    // MARK: Read

    /// - Given: an empty keychain
    /// - When: a session is read
    /// - Then:
    ///    - it is `absent`, and nothing is written
    func testReadOfNothingIsAbsent() throws {
        XCTAssertEqual(try store.read(work), .absent)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A failed read must never be reported as "no session", which would show sign-in to a user who
    /// is signed in.
    ///
    /// - Given: a stored record, and each keychain failure status in turn
    /// - When: the session is read
    /// - Then:
    ///    - it throws `storageUnavailable` with the classified reason, and an unclassified status is
    ///      `.interrupted` — never `absent`
    func testReadFailureIsStorageUnavailableNeverAbsent() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let cases: [(OSStatus, StorageUnavailableReason)] = [
            (errSecInteractionNotAllowed, .locked),
            (errSecMissingEntitlement, .denied),
            (errSecNoAccessForItem, .denied),
            (errSecAuthFailed, .denied),
            (errSecIO, .interrupted),
            (errSecNotAvailable, .interrupted),
            (errSecParam, .interrupted)
        ]
        for (status, reason) in cases {
            keychain.failing(.read, with: status)
            assertStorageUnavailable(reason) { try store.read(work) }
        }
        keychain.clearFailures()
        XCTAssertNotEqual(try store.read(work), .absent)
    }

    /// - Given: a record from a newer schema under one session and corrupt bytes under another
    /// - When: each is read
    /// - Then:
    ///    - they are `unsupportedSchema` and `corrupt` respectively — distinguishable, neither absent,
    ///      and neither rewritten or deleted
    func testFutureSchemaAndCorruptRecordsArePresentAndDistinct() throws {
        let home = try SessionID.named("home")
        keychain.put(StorageFixtures.futureSchemaRecord, workAccount)
        keychain.put(StorageFixtures.corruptRecord, store.sessionAccount(for: home))

        XCTAssertEqual(try store.read(work), .unsupportedSchema(version: 2))
        XCTAssertEqual(try store.read(home), .corrupt)
        XCTAssertFalse(keychain.hasMutations)
    }

    // MARK: Commit guard

    /// - Given: no record
    /// - When: a record is written expecting none
    /// - Then:
    ///    - it commits at generation 1 with the store's clock, and reads back identically
    func testFirstWriteCommitsAtGenerationOne() throws {
        let envelope = try committedEnvelope(store.write(StorageFixtures.signedIn(label: "Acme"), for: work, expecting: nil))

        XCTAssertEqual(envelope.generation, 1)
        XCTAssertEqual(envelope.schemaVersion, SessionRecordEnvelope.currentSchemaVersion)
        XCTAssertEqual(envelope.lastWriteTimestamp, TestClock.start.addingTimeInterval(1))
        XCTAssertEqual(try store.read(work), .record(VersionedSessionRecord(envelope)))
        XCTAssertEqual(keychain.value(workAccount), try envelope.encoded())
        // And the session's namespace marker, as for every record created with credentials
        // (`SessionRecordStore+CopyForward.swift`).
        XCTAssertEqual(keychain.writtenAccounts, [workAccount, store.markerAccount(for: work)])
    }

    /// - Given: a record
    /// - When: it is rewritten five times, each expecting the generation just read
    /// - Then:
    ///    - every write commits, and the generation rises by exactly one each time
    func testGenerationRisesByOnePerCommit() throws {
        var generation = try committedEnvelope(store.write(StorageFixtures.signedIn(), for: work, expecting: nil)).generation
        for index in 1 ... 5 {
            let next = try committedEnvelope(
                store.write(StorageFixtures.signedIn(credentials: "tokens-v\(index + 1)"), for: work, expecting: .generation(generation))
            )
            XCTAssertEqual(next.generation, generation + 1)
            generation = next.generation
        }
        XCTAssertEqual(try storedEnvelope(work).generation, 6)
    }

    /// The interleaving the guard exists for: two writers load the same record, one commits, and the
    /// other must not overwrite it.
    ///
    /// - Given: writer A and writer B both read the record at generation 1
    /// - When: B commits, then A commits expecting generation 1
    /// - Then:
    ///    - A's write is discarded, not an error; B's bytes are still stored and the generation is B's
    func testWriteIsDiscardedWhenAnotherWriterCommittedFirst() throws {
        let loaded = try committedEnvelope(store.write(StorageFixtures.signedIn(), for: work, expecting: nil))
        let writerB = keychain.recordStore(for: StorageFixtures.namespace)
        try writerB.write(StorageFixtures.signedIn(credentials: "rotated-by-B"), for: work, expecting: .generation(loaded.generation))
        let bytesAfterB = keychain.value(workAccount)
        keychain.resetLogs()

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "stale-A"), for: work, expecting: .generation(loaded.generation))

        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(keychain.value(workAccount), bytesAfterB)
        XCTAssertEqual(try storedEnvelope(work).generation, 2)
        XCTAssertEqual(try storedEnvelope(work).record.credentials, Data("rotated-by-B".utf8))
        XCTAssertEqual(keychain.writtenAccounts, [])
    }

    /// - Given: a record at generation 1, and another writer that commits after the guard's first read
    ///   and before its byte comparison
    /// - When: a write expecting generation 1 runs
    /// - Then:
    ///    - it is discarded by the byte comparison, and the other writer's record survives
    func testWriteIsDiscardedWhenAnotherWriterLandsBetweenReadAndWrite() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let intruder = keychain.recordStore(for: StorageFixtures.namespace)
        let intruderCommitted = Flag()
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount) {
            if (try? intruder.write(StorageFixtures.signedIn(credentials: "intruder"), for: sessionId, expecting: .generation(1)))?.didCommit == true {
                intruderCommitted.raise()
            }
        }

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "mine"), for: work, expecting: .generation(1))

        XCTAssertTrue(intruderCommitted.isRaised)
        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(try storedEnvelope(work).record.credentials, Data("intruder".utf8))
        XCTAssertEqual(try storedEnvelope(work).generation, 2)
    }

    /// The guard is not atomic, and this pins the window it cannot close, so nobody mistakes it for a
    /// lock: a writer landing after the final byte comparison and before the replace is overwritten.
    ///
    /// - Given: a record at generation 1, and another writer that commits after the guard's final
    ///   comparison and before its replace
    /// - When: a write expecting generation 1 runs
    /// - Then:
    ///    - it commits over the other writer — the bounded, documented lost update
    func testGuardCannotSeeAWriterInsideTheReplaceWindow() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let intruder = keychain.recordStore(for: StorageFixtures.namespace)
        let intruderCommitted = Flag()
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount, occurrence: 2) {
            if (try? intruder.write(StorageFixtures.signedIn(credentials: "intruder"), for: sessionId, expecting: .generation(1)))?.didCommit == true {
                intruderCommitted.raise()
            }
        }

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "mine"), for: work, expecting: .generation(1))

        XCTAssertTrue(intruderCommitted.isRaised)
        XCTAssertTrue(outcome.didCommit)
        XCTAssertEqual(try storedEnvelope(work).record.credentials, Data("mine".utf8))
    }

    /// - Given: no record, and another writer that creates one after the guard's final check and
    ///   before its add
    /// - When: a first write expecting no record runs
    /// - Then:
    ///    - add-if-absent refuses it, so it is discarded and the other writer's record survives
    func testFirstWriteIsDiscardedWhenAnotherWriterAddsFirst() throws {
        let intruder = keychain.recordStore(for: StorageFixtures.namespace)
        let intruderCommitted = Flag()
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount, occurrence: 2) {
            if (try? intruder.write(StorageFixtures.signedIn(credentials: "intruder"), for: sessionId, expecting: nil))?.didCommit == true {
                intruderCommitted.raise()
            }
        }

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "mine"), for: work, expecting: nil)

        XCTAssertTrue(intruderCommitted.isRaised)
        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(try storedEnvelope(work).record.credentials, Data("intruder".utf8))
        XCTAssertEqual(try storedEnvelope(work).generation, 1)
    }

    /// - Given: a record exists, or a record the caller read has since been purged
    /// - When: a write expects the opposite
    /// - Then:
    ///    - both are discarded, and neither creates nor replaces anything
    func testWriteIsDiscardedWhenPresenceDiffersFromExpectation() throws {
        let home = try SessionID.named("home")
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        keychain.resetLogs()

        XCTAssertEqual(try store.write(StorageFixtures.signedIn(), for: work, expecting: nil), .discarded)
        XCTAssertEqual(try store.write(StorageFixtures.signedIn(), for: home, expecting: .generation(4)), .discarded)
        XCTAssertEqual(keychain.writtenAccounts, [])
        XCTAssertEqual(try store.read(home), .absent)
    }

    /// - Given: a newer-schema record and a corrupt record
    /// - When: a write runs against each, with any expectation
    /// - Then:
    ///    - both are discarded and the stored bytes are untouched
    func testWriteNeverOverwritesARecordItCannotRead() throws {
        let home = try SessionID.named("home")
        keychain.put(StorageFixtures.futureSchemaRecord, workAccount)
        keychain.put(StorageFixtures.corruptRecord, store.sessionAccount(for: home))

        for expected: RecordVersion? in [nil, .generation(1)] {
            XCTAssertEqual(try store.write(StorageFixtures.signedIn(), for: work, expecting: expected), .discarded)
            XCTAssertEqual(try store.write(StorageFixtures.signedIn(), for: home, expecting: expected), .discarded)
        }
        XCTAssertEqual(keychain.value(workAccount), StorageFixtures.futureSchemaRecord)
        XCTAssertEqual(keychain.value(store.sessionAccount(for: home)), StorageFixtures.corruptRecord)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// - Given: the keychain fails the guard's re-read, or the write itself
    /// - When: a write runs
    /// - Then:
    ///    - it throws `storageUnavailable`, rather than reporting a discard or a commit
    func testWriteFailuresThrowStorageUnavailable() throws {
        keychain.failing(.read, with: errSecInteractionNotAllowed)
        assertStorageUnavailable(.locked) { try store.write(StorageFixtures.signedIn(), for: work, expecting: nil) }
        keychain.clearFailures()

        keychain.failing(.write, with: errSecMissingEntitlement)
        assertStorageUnavailable(.denied) { try store.write(StorageFixtures.signedIn(), for: work, expecting: nil) }
    }

    // MARK: Sign-out

    /// - Given: a signed-in record with a label
    /// - When: the session is signed out
    /// - Then:
    ///    - the row is kept, one generation later, with no credentials, kind `.signedOut`, and the label and
    ///      username carried forward
    func testSignOutKeepsTheRowAndLabel() throws {
        try store.write(StorageFixtures.signedIn(label: "Acme Corp", username: "alice"), for: work, expecting: nil)

        XCTAssertEqual(try store.signOut(work), .signedOut)

        let envelope = try storedEnvelope(work)
        XCTAssertEqual(envelope.record, SessionRecord(label: "Acme Corp", username: "alice", kind: .signedOut, credentials: nil))
        XCTAssertEqual(envelope.generation, 2)
    }

    /// - Given: a signed-in record and an interrupted-sign-in record for the session, and another
    ///   session's interrupted-sign-in record
    /// - When: the session is signed out
    /// - Then:
    ///    - its own challenge record is deleted and the other session's is not
    func testSignOutDeletesOnlyThisSessionsChallengeRecord() throws {
        let home = try SessionID.named("home")
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        keychain.put(Data("challenge".utf8), store.challengeAccount(for: work))
        keychain.put(Data("challenge".utf8), store.challengeAccount(for: home))

        XCTAssertEqual(try store.signOut(work), .signedOut)

        XCTAssertNil(keychain.value(store.challengeAccount(for: work)))
        XCTAssertNotNil(keychain.value(store.challengeAccount(for: home)))
    }

    /// `.default`'s sign-out writes the plugin's own signed-out record, which every plugin release reads as signed
    /// out, and keeps the last user and the label in the sidecar.
    ///
    /// - Given: `.default` on the plugin's record, signed in as alice with a label
    /// - When: it is signed out
    /// - Then:
    ///    - the plugin's record is `{"noCredentials":{}}`, the sidecar holds alice and the label, and the read is
    ///      alice's signed-out row
    func testSignOutOfTheDefaultSessionWritesNoCredentialsAndKeepsTheSidecar() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        XCTAssertEqual(try store.setDefaultLabel("Main"), .written(try store.read(.default)))

        XCTAssertEqual(try store.signOut(.default), .signedOut)

        XCTAssertEqual(keychain.value(pluginAccount), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(
            try storedEnvelope(.default).record,
            .signedOut(label: "Main", username: "alice@corp", userId: "1234567890")
        )
        XCTAssertNil(keychain.value(SessionRecordKey.account(for: .default, in: StorageFixtures.pools, kind: .session)))
    }

    /// Only `.default` owns the plugin's record; signing a named session out must not sign the plugin
    /// out.
    ///
    /// - Given: the plugin's record and `.default`'s sidecar, and two signed-in named sessions
    /// - When: both are read, signed out and purged
    /// - Then:
    ///    - the plugin's record and the sidecar are untouched and were never even read
    func testNamedSessionsNeverTouchThePluginRecordOrTheSidecar() throws {
        keychain.put(StorageFixtures.pluginCredentials, pluginAccount)
        let sidecarAccount = SessionRecordKey.metaAccount(in: StorageFixtures.pools)
        let sidecar = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Home", username: nil, userId: nil).encoded()
        keychain.put(sidecar, sidecarAccount)
        for sessionId in [work!, try SessionID.named("home")] {
            try store.write(StorageFixtures.signedIn(), for: sessionId, expecting: nil)
            _ = try store.read(sessionId)
            XCTAssertEqual(try store.signOut(sessionId), .signedOut)
            try store.purge(sessionId)
            XCTAssertEqual(try store.read(sessionId), .absent)
        }

        XCTAssertEqual(keychain.value(pluginAccount), StorageFixtures.pluginCredentials)
        XCTAssertEqual(keychain.value(sidecarAccount), sidecar)
        for account in [pluginAccount, sidecarAccount] {
            XCTAssertFalse(keychain.readAccounts.contains(account))
            XCTAssertFalse(keychain.removedAccounts.contains(account))
        }
    }

    /// - Given: a session with no record, and a session already signed out
    /// - When: each is signed out
    /// - Then:
    ///    - nothing is written: no row is invented, and a signed-out row is not rewritten
    func testSignOutWritesNothingWhenThereIsNothingToSignOut() throws {
        let home = try SessionID.named("home")
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        XCTAssertEqual(try store.signOut(work), .signedOut)
        keychain.resetLogs()

        XCTAssertEqual(try store.signOut(work), .signedOut)
        XCTAssertEqual(try store.signOut(home), .noRecord)

        XCTAssertEqual(keychain.writtenAccounts, [])
        XCTAssertEqual(try store.read(home), .absent)
        XCTAssertEqual(try storedEnvelope(work).generation, 2)
    }

    /// A concurrent label write moves the generation but not the credentials, so sign-out still signs
    /// the session out, and goes through the guard so the new label is not lost.
    ///
    /// - Given: a signed-in record, and another writer that sets a new label, keeping the credentials,
    ///   between sign-out's read and its write
    /// - When: the session is signed out
    /// - Then:
    ///    - it is signed out, carrying the concurrently-set label
    func testSignOutWinsARaceAndKeepsAConcurrentlySetLabel() throws {
        try store.write(StorageFixtures.signedIn(label: "Old"), for: work, expecting: nil)
        let intruder = keychain.recordStore(for: StorageFixtures.namespace)
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount) {
            _ = try? intruder.write(StorageFixtures.signedIn(label: "New"), for: sessionId, expecting: .generation(1))
        }

        XCTAssertEqual(try store.signOut(work), .signedOut)

        let envelope = try storedEnvelope(work)
        XCTAssertEqual(envelope.record, .signedOut(label: "New", username: "alice"))
        XCTAssertEqual(envelope.generation, 3)
    }

    /// Erasing a sign-in that landed mid-sign-out would sign out a session this call never saw —
    /// here a different user, whose tokens nobody revoked.
    ///
    /// - Given: alice's signed-in record, and another process signing bob in to the same session ID
    ///   between sign-out's read and its write, with a challenge record present
    /// - When: the session is signed out
    /// - Then:
    ///    - it returns `.superseded`, and bob's record and the challenge record are untouched
    func testSignOutIsSupersededByAConcurrentSignIn() throws {
        try store.write(StorageFixtures.signedIn(username: "alice", credentials: "alice-tokens"), for: work, expecting: nil)
        keychain.put(Data("challenge".utf8), store.challengeAccount(for: work))
        let otherProcess = keychain.recordStore(for: StorageFixtures.namespace)
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount) {
            _ = try? otherProcess.write(StorageFixtures.signedIn(username: "bob", credentials: "bob-tokens"), for: sessionId, expecting: .generation(1))
        }

        XCTAssertEqual(try store.signOut(work), .superseded)

        XCTAssertEqual(try storedEnvelope(work).record, StorageFixtures.signedIn(username: "bob", credentials: "bob-tokens"))
        XCTAssertNotNil(keychain.value(store.challengeAccount(for: work)))
    }

    /// A superseded sign-out leaves the other writer's record alone: here the plugin's, holding another user.
    ///
    /// - Given: `.default` on the plugin's record for alice, and the plugin signing bob in between sign-out's read
    ///   and its write
    /// - When: it is signed out
    /// - Then:
    ///    - it returns `.superseded`, and bob's record is untouched
    func testSupersededSignOutKeepsThePluginsNewRecord() throws {
        let alice = FakePayload.signedIn("alice").data
        let bob = FakePayload.signedIn("bob").data
        keychain.put(alice, pluginAccount)
        let otherWriter = keychain!
        let account = pluginAccount
        keychain.onceAfterReading(account) {
            otherWriter.put(bob, account)
        }

        XCTAssertEqual(try store.signOut(.default), .superseded)

        XCTAssertEqual(keychain.value(pluginAccount), bob)
    }

    /// - Given: a signed-in record, and a writer that changes only its label before every one of
    ///   sign-out's guarded writes
    /// - When: the session is signed out
    /// - Then:
    ///    - after the guarded attempts are used up, sign-out replaces the record unguarded, and it ends
    ///      signed out without the generation going backwards
    func testSignOutForcesAfterRepeatedLostRacesThatKeepTheCredentials() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let rival = makeRival { envelope in
            StorageFixtures.signedIn(label: "rival-\(envelope.generation)")
        }
        keychain.afterEveryRead(of: workAccount) { rival.move() }

        let outcome = try store.signOut(work)
        keychain.afterEveryRead(of: workAccount, nil)

        XCTAssertEqual(outcome, .signedOut)
        XCTAssertEqual(rival.commits, rival.budget, "every guarded attempt lost its race")
        let envelope = try storedEnvelope(work)
        XCTAssertEqual(envelope.record, .signedOut(label: "rival-\(rival.lastCommittedGeneration - 1)", username: "alice"))
        XCTAssertGreaterThan(envelope.generation, rival.lastCommittedGeneration, "the generation never goes backwards")
    }

    /// - Given: a signed-in record, and a writer in another process that refreshes the credentials
    ///   before every one of sign-out's guarded writes
    /// - When: the session is signed out
    /// - Then:
    ///    - it returns `.superseded` rather than forcing, and the refreshed record is left alone
    func testSignOutDoesNotForceOverChangedCredentials() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let rival = makeRival { envelope in
            StorageFixtures.signedIn(credentials: "refreshed-\(envelope.generation)")
        }
        keychain.afterEveryRead(of: workAccount) { rival.move() }

        let outcome = try store.signOut(work)
        keychain.afterEveryRead(of: workAccount, nil)

        XCTAssertEqual(outcome, .superseded)
        let envelope = try storedEnvelope(work)
        XCTAssertFalse(envelope.record.isSignedOut)
        XCTAssertEqual(envelope.generation, rival.lastCommittedGeneration)
    }

    /// Each guarded attempt reads the record twice (the read, then the guard's re-read) and the rival
    /// commits after each, so this budget loses every guarded attempt and then stops.
    private func makeRival(_ change: @escaping @Sendable (VersionedSessionRecord) -> SessionRecord) -> RivalWriter {
        RivalWriter(
            store: keychain.recordStore(for: StorageFixtures.namespace),
            sessionId: work,
            budget: SessionRecordStore.maximumGuardedSignOutAttempts * 2,
            change: change
        )
    }

    /// - Given: corrupt bytes under the session's key
    /// - When: the session is signed out
    /// - Then:
    ///    - the bytes are replaced by a signed-out row, so no unreadable credentials outlive sign-out
    func testSignOutReplacesACorruptRecord() throws {
        keychain.put(StorageFixtures.corruptRecord, workAccount)

        XCTAssertEqual(try store.signOut(work), .signedOut)

        XCTAssertEqual(try storedEnvelope(work).record, .signedOut(label: nil, username: nil))
    }

    /// Sign-out's unguarded write only replaces: it must not recreate a record a concurrent purge
    /// removed, which `set` would.
    ///
    /// - Given: corrupt bytes under the session's key, and a concurrent purge that lands after sign-out
    ///   reads the record
    /// - When: the session is signed out
    /// - Then:
    ///    - the record stays absent
    func testSignOutDoesNotRecreateARecordPurgedConcurrently() throws {
        keychain.put(StorageFixtures.corruptRecord, workAccount)
        let purger = keychain.recordStore(for: StorageFixtures.namespace)
        let sessionId: SessionID = work
        keychain.onceAfterReading(workAccount) {
            try? purger.purge(sessionId)
        }

        XCTAssertEqual(try store.signOut(work), .noRecord)

        XCTAssertEqual(try store.read(work), .absent)
        XCTAssertNil(keychain.value(workAccount))
    }

    /// - Given: a signed-in record that carries a user ID
    /// - When: the session is signed out
    /// - Then:
    ///    - the kept row carries the user ID forward, like the username
    func testSignOutCarriesTheUserIdForward() throws {
        var record = StorageFixtures.signedIn(label: "Main", username: "alice")
        record.userId = "sub-alice"
        try store.write(record, for: work, expecting: nil)

        XCTAssertEqual(try store.signOut(work), .signedOut)

        XCTAssertEqual(try storedEnvelope(work).record, .signedOut(label: "Main", username: "alice", userId: "sub-alice"))
    }

    // MARK: Purge

    /// - Given: a record and a challenge record for the session, and another session's record
    /// - When: the session is purged
    /// - Then:
    ///    - its record and challenge record are gone, and the other session is untouched
    func testPurgeRemovesTheRowAndChallengeRecord() throws {
        let home = try SessionID.named("home")
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        try store.write(StorageFixtures.signedIn(), for: home, expecting: nil)
        keychain.put(Data("challenge".utf8), store.challengeAccount(for: work))

        try store.purge(work)

        XCTAssertEqual(try store.read(work), .absent)
        XCTAssertNil(keychain.value(store.challengeAccount(for: work)))
        XCTAssertNotEqual(try store.read(home), .absent)
        try store.purge(work)
    }

    /// - Given: `.default` on the plugin's record, with its sidecar and a challenge record, and a leftover
    ///   `$default.session` and `$default` marker from a development build
    /// - When: it is purged
    /// - Then:
    ///    - exactly the plugin's record, then the sidecar, then the challenge record are deleted; the leftovers
    ///      are not touched
    func testPurgeOfTheDefaultSessionDeletesTheSharedRecordTheSidecarAndTheChallenge() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        XCTAssertEqual(try store.setDefaultLabel("Main"), .written(try store.read(.default)))
        keychain.put(Data("challenge".utf8), store.challengeAccount(for: .default))
        let leftover = SessionRecordKey.account(for: .default, in: StorageFixtures.pools, kind: .session)
        keychain.put(StorageFixtures.corruptRecord, leftover)
        let leftoverMarker = SessionRecordKey.markerAccount(for: .default, scope: TestKeychain.markerScope)
        keychain.put(Data("{}".utf8), leftoverMarker)
        keychain.resetLogs()

        try store.purge(.default)

        XCTAssertEqual(keychain.removedAccounts, [
            pluginAccount,
            SessionRecordKey.metaAccount(in: StorageFixtures.pools),
            store.challengeAccount(for: .default)
        ])
        XCTAssertEqual(try store.read(.default), .absent)
        XCTAssertNotNil(keychain.value(leftover))
        XCTAssertNotNil(keychain.value(leftoverMarker))
    }

    /// A purge that fails part-way is safe to repeat.
    ///
    /// - Given: `.default` on the plugin's record with a sidecar, and the delete of each item failing in turn
    /// - When: the session is purged
    /// - Then:
    ///    - the purge throws `storageUnavailable`, and a purge afterwards leaves it absent
    func testPartlyFailedPurgeOfTheDefaultSessionIsSafeToRepeat() throws {
        let sidecarAccount = SessionRecordKey.metaAccount(in: StorageFixtures.pools)
        for failingAccount in [pluginAccount, sidecarAccount, store.challengeAccount(for: .default)] {
            keychain.clearFailures()
            keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
            keychain.put(try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Main", username: nil, userId: nil).encoded(), sidecarAccount)
            keychain.failingRemovals(of: failingAccount, with: errSecIO)

            assertStorageUnavailable(.interrupted) { try store.purge(.default) }
        }
        keychain.clearFailures()
        try store.purge(.default)
        XCTAssertEqual(try store.read(.default), .absent)
    }

    /// - Given: the keychain fails deletes
    /// - When: a session is purged
    /// - Then:
    ///    - it throws `storageUnavailable`
    func testPurgeFailureThrowsStorageUnavailable() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        keychain.failing(.remove, with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store.purge(work) }
        keychain.clearFailures()
        XCTAssertNotEqual(try store.read(work), .absent)
    }

    // MARK: `.default` on the plugin's record

    /// - Given: only the plugin's record, holding alice
    /// - When: the default session is read
    /// - Then:
    ///    - it is alice's record, versioned by the stored bytes, after reading the plugin's record and the sidecar
    ///      only, and nothing is written
    func testDefaultReadsThePluginsRecordInPlace() throws {
        keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)

        let read = try storedEnvelope(.default)

        XCTAssertEqual(read.version, .storedBytes(PluginRecordFixtures.userPoolAndIdentityPool))
        XCTAssertEqual(read.record, SessionRecord(
            label: nil,
            username: "alice@corp",
            userId: "1234567890",
            kind: .userPoolAndIdentityPool,
            credentials: PluginRecordFixtures.userPoolAndIdentityPool
        ))
        XCTAssertEqual(keychain.readAccounts, [pluginAccount, SessionRecordKey.metaAccount(in: StorageFixtures.pools)])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// - Given: no plugin record
    /// - When: the default session's first write lands, expecting none
    /// - Then:
    ///    - it lands on the plugin's record as the credentials verbatim, with the sidecar, and no marker or `$default`
    ///      session record is written
    func testFirstWriteOfTheDefaultSessionLandsOnThePluginsRecord() throws {
        let committed = try store.write(FakePayload.signedIn("alice").record(), for: .default, expecting: nil)

        XCTAssertEqual(
            committed,
            .committed(VersionedSessionRecord(
                record: FakePayload.signedIn("alice").record(),
                version: .storedBytes(FakePayload.signedIn("alice").data)
            ))
        )
        XCTAssertEqual(keychain.value(pluginAccount), FakePayload.signedIn("alice").data)
        XCTAssertEqual(keychain.writtenAccounts, [pluginAccount, SessionRecordKey.metaAccount(in: StorageFixtures.pools)])
    }

    /// The commit guard compares the stored bytes: a generation never matches the shared record.
    ///
    /// - Given: the plugin's record for alice
    /// - When: writes expect no item, other bytes, and a generation
    /// - Then:
    ///    - each is discarded and the record is untouched
    func testDefaultWritesAreGuardedOnTheStoredBytes() throws {
        let alice = FakePayload.signedIn("alice").data
        keychain.put(alice, pluginAccount)
        let bob = FakePayload.signedIn("bob").record()

        for expected: RecordVersion? in [nil, .storedBytes(FakePayload.signedIn("carol").data), .generation(1)] {
            XCTAssertEqual(try store.write(bob, for: .default, expecting: expected), .discarded, "\(String(describing: expected))")
        }
        XCTAssertEqual(keychain.value(pluginAccount), alice)
        XCTAssertEqual(keychain.writtenAccounts, [])
    }

    /// - Given: the plugin's record fails to read
    /// - When: the default session is read
    /// - Then:
    ///    - it throws `storageUnavailable`, not `absent`
    func testFailedReadOfThePluginRecordIsStorageUnavailable() throws {
        keychain.put(StorageFixtures.pluginCredentials, pluginAccount)
        keychain.failingReads(of: pluginAccount, with: errSecIO)

        assertStorageUnavailable(.interrupted) { try store.read(.default) }
    }

    /// - Given: the plugin's record, and `.default`'s sidecar failing to read
    /// - When: the default session is read
    /// - Then:
    ///    - it throws `storageUnavailable`: a failed read is never "no label"
    func testFailedReadOfTheSidecarIsStorageUnavailable() throws {
        keychain.put(StorageFixtures.pluginCredentials, pluginAccount)
        keychain.failingReads(of: SessionRecordKey.metaAccount(in: StorageFixtures.pools), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store.read(.default) }
    }

    /// - Given: a plugin record that is not the plugin's format
    /// - When: the default session is read
    /// - Then:
    ///    - it is `.corrupt`, present but unreadable
    func testUnrecognisedPluginRecordIsCorrupt() throws {
        keychain.put(StorageFixtures.corruptRecord, pluginAccount)

        XCTAssertEqual(try store.read(.default), .corrupt)
    }

    /// The development leftover is never read: `.default` is the plugin's record only.
    ///
    /// - Given: a signed-in `$default.session` envelope and no plugin record
    /// - When: the default session is read
    /// - Then:
    ///    - it is absent, and the leftover is never read
    func testLeftoverDollarDefaultRecordIsNeverRead() throws {
        let leftover = SessionRecordKey.account(for: .default, in: StorageFixtures.pools, kind: .session)
        let envelope = SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: StorageFixtures.signedIn())
        keychain.put(try envelope.encoded(), leftover)

        XCTAssertEqual(try store.read(.default), .absent)
        XCTAssertFalse(keychain.readAccounts.contains(leftover))
    }
}

/// Thrown by a helper so the test fails, rather than skips, when a precondition does not hold.
private struct UnexpectedResult: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private extension SessionRecordStore.ReadResult {
    var isAbsent: Bool { self == .absent }
}

/// A writer in another process that moves the record every time it is asked, up to a budget.
private final class RivalWriter: @unchecked Sendable {
    let budget: Int
    private let store: SessionRecordStore
    private let sessionId: SessionID
    private let change: @Sendable (VersionedSessionRecord) -> SessionRecord
    private let lock = NSLock()
    private var moving = false
    private var committed: UInt64 = 0
    private var commitCount = 0

    init(store: SessionRecordStore, sessionId: SessionID, budget: Int, change: @escaping @Sendable (VersionedSessionRecord) -> SessionRecord) {
        self.store = store
        self.sessionId = sessionId
        self.budget = budget
        self.change = change
    }

    var lastCommittedGeneration: UInt64 {
        withLock { committed }
    }

    var commits: Int {
        withLock { commitCount }
    }

    func move() {
        // The rival's own reads fire the hook too; do not recurse.
        guard begin() else { return }
        defer { withLock { moving = false } }
        guard case .record(let envelope) = try? store.read(sessionId), !envelope.record.isSignedOut else {
            return
        }
        if case .committed(let written)? = try? store.write(change(envelope), for: sessionId, expecting: envelope.version) {
            withLock {
                committed = written.generation
                commitCount += 1
            }
        }
    }

    private func begin() -> Bool {
        withLock {
            guard !moving, commitCount < budget else { return false }
            moving = true
            return true
        }
    }

    private func withLock<Value>(_ body: () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
