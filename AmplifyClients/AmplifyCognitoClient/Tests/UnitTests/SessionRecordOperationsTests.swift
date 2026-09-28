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

/// `setSessionLabel` and `completeAdoption()`.
final class SessionRecordOperationsTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: .default), nil)
        await harness.waitForBaseline()
        harness = nil
    }

    private func envelope(_ sessionId: SessionID) throws -> SessionRecordEnvelope? {
        guard case .record(let envelope) = try harness.store().read(sessionId) else {
            return nil
        }
        return envelope
    }

    // MARK: Label

    /// - Given: a session with nothing stored
    /// - When: a label is set
    /// - Then:
    ///    - a labelled signed-out row is created, listed only with `includingSignedOut: true`
    ///    - the state stays `.signedOut`
    func testLabelOnAnAbsentSessionCreatesALabelledSignedOutRow() async throws {
        let client = try harness.client(work)

        try await client.setSessionLabel("Work")

        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: nil))
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: false), [])
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true).map(\.label), ["Work"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a session with nothing stored
    /// - When: the label is cleared
    /// - Then:
    ///    - nothing is written: there is no label to clear
    func testClearingTheLabelOfAnAbsentSessionWritesNothing() async throws {
        let client = try harness.client(work)

        try await client.setSessionLabel(nil)

        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: a signed-in record
    /// - When: its label is set, then cleared
    /// - Then:
    ///    - only the label changes each time, one generation on; the credentials are kept
    func testLabelReplacesOnlyTheLabel() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload, label: "Old")
        let client = try harness.client(work)

        try await client.setSessionLabel("New")
        XCTAssertEqual(try envelope(work)?.record, payload.record(label: "New"))
        XCTAssertEqual(try envelope(work)?.generation, 2)

        try await client.setSessionLabel(nil)
        XCTAssertEqual(try envelope(work)?.record, payload.record(label: nil))
        XCTAssertEqual(try envelope(work)?.generation, 3)
    }

    /// The storage layer's defined first write after read-through: it lands on `.default`'s own key and
    /// leaves the plugin's record byte-identical, so a rollback still finds it.
    ///
    /// - Given: `.default` reading through to the plugin's record
    /// - When: a label is set
    /// - Then:
    ///    - `.default`'s own record now holds the plugin's credentials, described by the engine, with
    ///      the label; the plugin's record is untouched
    func testLabelOnAReadThroughSessionWritesItsOwnRecordAndKeepsThePlugins() async throws {
        let payload = FakePayload.signedIn("alice")
        harness.keychain.put(payload.data, pluginAccount)
        let client = try harness.client(.default)

        try await client.setSessionLabel("Main")

        XCTAssertEqual(try envelope(.default)?.record, payload.record(label: "Main"))
        XCTAssertEqual(harness.keychain.value(pluginAccount), payload.data)
    }

    /// A record this build cannot read is never overwritten.
    ///
    /// - Given: corrupt bytes under the session's key
    /// - When: a label is set
    /// - Then:
    ///    - it throws `.unknown`, and the bytes are untouched
    func testLabelOnAnUnreadableRecordThrowsAndWritesNothing() async throws {
        harness.keychain.put(StorageFixtures.corruptRecord, harness.store().sessionAccount(for: work))
        let client = try harness.client(work)

        await assertThrowsAsync({ try await client.setSessionLabel("Work") }) { error in
            guard case .unknown = error as? AuthClientError else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.keychain.value(harness.store().sessionAccount(for: work)), StorageFixtures.corruptRecord)
    }

    /// Public calls throw only `AuthClientError`: an engine that cannot read a payload must not leak its
    /// own error type.
    ///
    /// - Given: `.default` reading through to a plugin record the engine cannot read
    /// - When: a label is set, and adoption is attempted
    /// - Then:
    ///    - each throws `AuthClientError.unknown` carrying the engine's error as its underlying error, and
    ///      nothing is written
    func testUndescribablePayloadThrowsAuthClientErrorFromLabelAndAdoption() async throws {
        harness.keychain.put(Data("opaque".utf8), pluginAccount)
        let client = try harness.client(.default)

        for operation in [{ try await client.setSessionLabel("Main") }, { try await client.completeAdoption() }] {
            await assertThrowsAsync(operation) { error in
                guard case .unknown(_, _, let underlying) = error as? AuthClientError else {
                    return XCTFail("expected AuthClientError.unknown, got \(error)")
                }
                XCTAssertEqual(underlying as? FakeEngineError, .unreadablePayload)
            }
        }
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// A lost race is rebased, not forced: forcing would write back credentials a concurrent refresh
    /// already replaced.
    ///
    /// - Given: a signed-in, restored session, and another writer that refreshes its credentials right
    ///   after the label write reads the record
    /// - When: the label is set
    /// - Then:
    ///    - the label lands on the fresh record, and the fresh credentials are the ones kept
    func testLabelSurvivesAConcurrentWriteAndKeepsTheFreshCredentials() async throws {
        try harness.signIn(work, .signedIn("alice", version: 1))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let fresh = FakePayload.signedIn("alice", version: 2)
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { envelope in
            var record = envelope.record
            record.credentials = fresh.data
            return record
        }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { rival.move() }

        try await client.setSessionLabel("Work")

        XCTAssertEqual(rival.commits, 1)
        XCTAssertEqual(try envelope(work)?.record, fresh.record(label: "Work"))
    }

    /// - Given: another writer that moves the record after every read
    /// - When: a label is set
    /// - Then:
    ///    - after three lost races it throws `storageUnavailable(.interrupted)` rather than forcing
    func testLabelGivesUpAfterThreeLostRaces() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work, budget: 100) { envelope in
            var record = envelope.record
            record.label = "rival-\(envelope.generation)"
            return record
        }
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work)) { rival.move() }

        await assertThrowsAsync({ try await client.setSessionLabel("Work") }) { error in
            XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, .interrupted, "\(error)")
        }
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        XCTAssertNotEqual(try envelope(work)?.record.label, "Work")
    }

    // MARK: Adoption

    /// - Given: `.default` reading through to the plugin's record
    /// - When: adoption completes
    /// - Then:
    ///    - `.default`'s own record holds the plugin's bytes verbatim, described by the engine
    ///    - the own write happened before the plugin record's delete, and the plugin record is gone
    ///    - the state is unchanged
    func testAdoptionWritesTheOwnRecordThenDeletesThePlugins() async throws {
        let payload = FakePayload.signedIn("alice")
        harness.keychain.put(payload.data, pluginAccount)
        let client = try harness.client(.default)
        let before = await client.currentSessionState()

        try await client.completeAdoption()

        XCTAssertEqual(try envelope(.default)?.record, payload.record())
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(
            harness.keychain.mutationOrder,
            [
                .write(harness.store().sessionAccount(for: .default)),
                // The namespace marker of a record created with credentials (`SessionRecordStore+CopyForward.swift`).
                .write(harness.store().markerAccount(for: .default)),
                .remove(pluginAccount)
            ],
            "own record first, plugin record second"
        )
        let after = await client.currentSessionState()
        XCTAssertEqual(after, before)
    }

    /// - Given: `.default` with its own record, copied earlier from the plugin's record, which is still present
    /// - When: adoption completes, twice
    /// - Then:
    ///    - the own record is kept as it was, the plugin's is deleted, and the second call succeeds with
    ///      nothing to do
    func testAdoptionIsIdempotent() async throws {
        let alice = FakePayload.signedIn("alice")
        let envelope = try harness.signIn(.default, alice)
        harness.keychain.put(alice.data, pluginAccount)
        let client = try harness.client(.default)

        try await client.completeAdoption()
        try await client.completeAdoption()
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(try self.envelope(.default), envelope)
        XCTAssertNil(harness.keychain.value(pluginAccount))
    }

    /// The own record was refreshed since it was copied, so the plugin's copy of the same user is stale.
    ///
    /// - Given: `.default`'s own record holding alice's refreshed credentials, and the plugin's record
    ///   holding alice's older ones
    /// - When: adoption completes
    /// - Then:
    ///    - the plugin's record is deleted and the own record is kept
    func testAdoptionDeletesThePluginsOlderCopyOfTheSameUser() async throws {
        let envelope = try harness.signIn(.default, .signedIn("alice", version: 2))
        harness.keychain.put(FakePayload.signedIn("alice", version: 1).data, pluginAccount)
        let client = try harness.client(.default)

        try await client.completeAdoption()
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(try self.envelope(.default), envelope)
        XCTAssertNil(harness.keychain.value(pluginAccount))
    }

    /// An unbridged plugin running beside the client signed a different user in. Deleting that record
    /// would sign `Amplify.Auth` out of a session this call never adopted.
    ///
    /// - Given: `.default`'s own record holding alice, and the plugin's record holding bob
    /// - When: adoption completes
    /// - Then:
    ///    - it throws `.unknown`, and both records are kept
    func testAdoptionKeepsAPluginRecordHoldingADifferentUser() async throws {
        let envelope = try harness.signIn(.default, .signedIn("alice"))
        let bob = FakePayload.signedIn("bob")
        harness.keychain.put(bob.data, pluginAccount)
        let client = try harness.client(.default)

        await assertThrowsAsync({ try await client.completeAdoption() }) { error in
            guard case .unknown = error as? AuthClientError else {
                return XCTFail("\(error)")
            }
        }
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(harness.keychain.value(pluginAccount), bob.data)
        XCTAssertEqual(try self.envelope(.default), envelope)
    }

    /// - Given: `.default` reading through to alice's plugin record, and the plugin writing bob's record
    ///   while adoption copies alice's
    /// - When: adoption completes
    /// - Then:
    ///    - it throws, the own record holds the copy of alice, and bob's plugin record is kept
    func testAdoptionKeepsAPluginRecordThatChangedDuringTheCopy() async throws {
        let alice = FakePayload.signedIn("alice")
        let bob = FakePayload.signedIn("bob")
        harness.keychain.put(alice.data, pluginAccount)
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let keychain = harness.keychain
        let pluginAccount = pluginAccount
        // Own-key reads during adoption: the read, then the commit guard's re-read.
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: .default), occurrence: 2) {
            keychain.put(bob.data, pluginAccount)
        }

        await assertThrowsAsync { try await client.completeAdoption() }

        XCTAssertEqual(harness.keychain.value(pluginAccount), bob.data)
        XCTAssertEqual(try envelope(.default)?.record, alice.record())
    }

    /// - Given: `.default` reading through to the plugin's record, and a keychain that fails to delete the
    ///   plugin's record once
    /// - When: adoption is attempted, and then retried once the keychain recovers
    /// - Then:
    ///    - the first attempt throws `storageUnavailable`, with the own record committed and the session
    ///      already reading it in memory, and the plugin's record kept
    ///    - the retry deletes the plugin's record
    func testAdoptionRecoversWhenThePluginRecordDeleteFails() async throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        let client = try harness.client(.default)
        harness.keychain.failingRemovals(of: pluginAccount, with: errSecInteractionNotAllowed)

        await assertThrowsAsync({ try await client.completeAdoption() }) { error in
            XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, .locked, "\(error)")
        }
        XCTAssertEqual(try envelope(.default)?.record, alice.record())
        XCTAssertEqual(harness.keychain.value(pluginAccount), alice.data)
        let inMemory = await client.core.restoredSnapshotIfAny
        XCTAssertEqual(inMemory?.ownRecord, alice.record(), "memory follows the committed own record")

        harness.keychain.clearFailures()
        try await client.completeAdoption()
        XCTAssertNil(harness.keychain.value(pluginAccount))
    }

    /// - Given: `.default` with nothing stored
    /// - When: adoption completes
    /// - Then:
    ///    - it succeeds and writes nothing
    func testAdoptionWithNothingToAdoptSucceeds() async throws {
        let client = try harness.client(.default)

        try await client.completeAdoption()

        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: `.default` with a corrupt own record, and the plugin's record
    /// - When: adoption is attempted
    /// - Then:
    ///    - it throws, and the plugin's record is not deleted
    func testAdoptionOverAnUnreadableRecordThrowsAndKeepsThePlugins() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        harness.keychain.put(StorageFixtures.corruptRecord, harness.store().sessionAccount(for: .default))
        let client = try harness.client(.default)

        await assertThrowsAsync { try await client.completeAdoption() }

        XCTAssertEqual(harness.keychain.value(pluginAccount), FakePayload.signedIn("alice").data)
    }

    /// - Given: the plugin's record, and a named session
    /// - When: the named session completes adoption
    /// - Then:
    ///    - it is a no-op: nothing is read, written or deleted
    func testAdoptionIsANoOpForNamedSessions() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let client = try harness.client(work)

        try await client.completeAdoption()

        XCTAssertEqual(harness.keychain.readAccounts, [])
        XCTAssertFalse(harness.keychain.hasMutations)
    }
}
