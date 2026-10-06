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

/// `setSessionLabel`: task T9. And how a named session's label follows its user when another principal takes the
/// session (as `.default`'s sidecar binding).
final class SessionRecordOperationsTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: .default), nil)
        await harness.waitForBaseline()
        harness = nil
    }

    private func envelope(_ sessionId: SessionID) throws -> VersionedSessionRecord? {
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

    /// `.default`'s label lives in its sidecar: the plugin's record is never rewritten for a label.
    ///
    /// - Given: `.default` on the plugin's record, holding alice, under the plugin's last configuration
    /// - When: a label is set
    /// - Then:
    ///    - only the sidecar is written, bound to alice, with the label; the plugin's record is byte-identical and
    ///      the session reads the label back
    func testLabelOnTheDefaultSessionWritesOnlyTheSidecar() async throws {
        let payload = FakePayload.signedIn("alice")
        harness.keychain.put(payload.data, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)

        try await client.setSessionLabel("Main")

        let sidecarAccount = SessionRecordKey.metaAccount(in: StorageFixtures.pools)
        XCTAssertEqual(harness.keychain.writtenAccounts, [sidecarAccount])
        XCTAssertEqual(harness.keychain.value(pluginAccount), payload.data)
        guard case .meta(let meta) = DefaultSessionMeta.decode(try XCTUnwrap(harness.keychain.value(sidecarAccount))) else {
            return XCTFail("the sidecar must be readable")
        }
        XCTAssertEqual([meta.label, meta.username, meta.userId], ["Main", "alice", "sub-alice"])
        XCTAssertEqual(try harness.storedRecord(.default), payload.record(label: "Main"))
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

    /// A shared record this build cannot read is never overwritten, and gets no label.
    ///
    /// - Given: `.default` on a plugin record that is not the plugin's format, under the plugin's last configuration
    /// - When: a label is set
    /// - Then:
    ///    - it throws `AuthClientError.unknown`, and nothing is written
    func testLabelOnAnUnrecognisedDefaultRecordThrowsAndWritesNothing() async throws {
        harness.keychain.put(Data("opaque".utf8), pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)

        await assertThrowsAsync({ try await client.setSessionLabel("Main") }) { error in
            guard case .unknown = error as? AuthClientError else {
                return XCTFail("expected AuthClientError.unknown, got \(error)")
            }
        }
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertEqual(harness.keychain.value(pluginAccount), Data("opaque".utf8))
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

    // MARK: Label binding

    /// A guest that takes over a signed-out row left by a user never takes that user's label, so it cannot pass
    /// it on to the next user.
    ///
    /// - Given: a named session where alice signs in, sets a label, and signs out
    /// - When:
    ///    - its session is fetched, which makes it a guest
    ///    - then bob signs in over the guest
    /// - Then:
    ///    - alice's signed-out row keeps her label and username
    ///    - the guest record has no label
    ///    - bob's record has no label, and nor does the listed row
    func testAGuestOverAnotherUsersSignedOutRowDropsTheLabelSoTheNextUserHasNone() async throws {
        let client = try harness.client(work)
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Alice's work")
        _ = await client.signOut()
        XCTAssertEqual(
            try harness.storedRecord(work),
            .signedOut(label: "Alice's work", username: "alice", userId: "sub-alice")
        )

        _ = try await client.fetchAuthSession()

        let guest = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(guest.kind, .guest)
        XCTAssertNil(guest.label)

        try await client.signInForTest("bob")

        let bob = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(bob.username, "bob")
        XCTAssertNil(bob.label)
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true).map(\.label), [nil])
    }

    /// "No user yet": a label set while the session is a guest names no user, so the first user who signs
    /// in keeps it.
    ///
    /// - Given: a guest session, whose label is set while it is a guest
    /// - When: a user signs in over the guest
    /// - Then:
    ///    - the user's record keeps the label
    func testAGuestsOwnLabelIsKeptWhenAUserSignsIn() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        try await client.setSessionLabel("Kiosk")

        try await client.signInForTest("alice")

        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(record.username, "alice")
        XCTAssertEqual(record.label, "Kiosk")
    }

    /// "No user yet": a label set before anyone signed in is kept by the guest that takes the row, and then
    /// by the first user.
    ///
    /// - Given: a named session with nothing stored, labelled
    /// - When:
    ///    - its session is fetched, which makes it a guest
    ///    - then a user signs in over the guest
    /// - Then:
    ///    - the guest record and then the user's record keep the label
    func testALabelSetBeforeAnyoneSignedInPassesThroughAGuestToTheFirstUser() async throws {
        let client = try harness.client(work)
        try await client.setSessionLabel("Shared iPad")

        _ = try await client.fetchAuthSession()

        let guest = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(guest.kind, .guest)
        XCTAssertEqual(guest.label, "Shared iPad")

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(work)?.label, "Shared iPad")
    }

    /// A federation never takes a label from a signed-out row left by a user, directly or through a guest, so
    /// clearing it and signing another user in leaves no label either.
    ///
    /// - Given: a named session where alice signs in, sets a label, and signs out
    /// - When:
    ///    - it federates; it clears the federation, and bob signs in
    ///    - then, after alice signs in, labels it and signs out again, its session is fetched (a guest) and it
    ///      federates
    /// - Then:
    ///    - each federated record has no label; the cleared row and bob's record have none
    func testAFederationOverAnotherUsersSignedOutRowHasNoLabel() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Alice's work")
        _ = await client.signOut()
        engine.scriptAccountOperation(.federateToIdentityPool) { _ in FakePayload.federated(identityId: "us-east-1:fed").data }

        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)

        let direct = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(direct.kind, .federated)
        XCTAssertNil(direct.label)
        try await client.clearFederationToIdentityPool()
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: nil, username: nil))
        try await client.signInForTest("bob")
        XCTAssertNil(try harness.storedRecord(work)?.label)
        _ = await client.signOut()

        try await client.signInForTest("alice")
        try await client.setSessionLabel("Alice's work")
        _ = await client.signOut()
        _ = try await client.fetchAuthSession()
        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)

        let throughGuest = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(throughGuest.kind, .federated)
        XCTAssertNil(throughGuest.label)
    }

    /// "No user yet": a federated identity names no user, so its own label survives clearing the federation
    /// and is kept by the first user who signs in, as `.default`'s sidecar keeps it.
    ///
    /// - Given: a federated session, labelled while federated
    /// - When: it clears the federation, then a user signs in
    /// - Then:
    ///    - the signed-out row keeps the label with no user, and the user's record keeps it
    func testAFederatedIdentitysOwnLabelSurvivesClearingAndIsKeptByTheFirstUser() async throws {
        try harness.signIn(work, .federated(identityId: "us-east-1:fed"))
        let client = try harness.client(work)
        try await client.setSessionLabel("Tablet")

        try await client.clearFederationToIdentityPool()

        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Tablet", username: nil))
        try await client.signInForTest("alice")
        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(record.username, "alice")
        XCTAssertEqual(record.label, "Tablet")
    }
}
