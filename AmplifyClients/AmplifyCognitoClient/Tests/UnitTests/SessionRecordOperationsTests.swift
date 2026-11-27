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

    private func envelope(_ sessionId: AmplifyCognitoClientSessionID) throws -> VersionedSessionRecord? {
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
            guard case .unknown = error as? AmplifyCognitoClientError else {
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
    ///    - it throws `AmplifyCognitoClientError.unknown`, and nothing is written
    func testLabelOnAnUnrecognisedDefaultRecordThrowsAndWritesNothing() async throws {
        harness.keychain.put(Data("opaque".utf8), pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)

        await assertThrowsAsync({ try await client.setSessionLabel("Main") }) { error in
            guard case .unknown = error as? AmplifyCognitoClientError else {
                return XCTFail("expected AmplifyCognitoClientError.unknown, got \(error)")
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
    ///    - exactly three attempts ran: the rival committed twice per attempt, once after its read and once after
    ///      the write's re-read
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
            XCTAssertEqual((error as? AmplifyCognitoClientError)?.storageUnavailableReason, .interrupted, "\(error)")
        }
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        XCTAssertEqual(rival.commits, 2 * SessionCore.maximumRecordWriteAttempts)
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

    // MARK: The session ID's label

    /// A label given when the session ID is created is the row's label once someone signs in, with no
    /// `setSessionLabel` call. Nothing is saved before that.
    ///
    /// - Given: nothing stored, and a client built with an ID created with a label
    /// - When: its state is read, then a user signs in
    /// - Then:
    ///    - building the client touches no storage, and restoring it saves nothing: no row is listed
    ///    - after the sign-in, `storedSessions` lists the row with the label
    func testALabelGivenWithTheIDIsListedAfterSignIn() async throws {
        let client = try harness.client(.named("work", label: "Work"))
        XCTAssertEqual(harness.keychain.readAccounts, [])
        XCTAssertFalse(harness.keychain.hasMutations)
        _ = await client.currentSessionState()
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [])

        try await client.signInForTest("alice")

        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: false,
            dependencies: harness.dependencies
        )
        XCTAssertEqual(listed.map(\.sessionId), [work])
        XCTAssertEqual(listed.map(\.label), ["Work"])
    }

    /// A label the row keeps wins over the ID's: the same user's, and one set before anyone signed in.
    ///
    /// - Given:
    ///    - alice's saved session, labelled, and a client of it built with an ID created with another label
    ///    - a second session with nothing stored, built with an ID created with a label, then labelled
    /// - When: alice signs out and signs in again; a user signs in to the second session
    /// - Then:
    ///    - each row keeps the label it had
    func testAnExistingLabelIsKeptOverTheIDsLabel() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Alice's work")
        let client = try harness.client(.named("work", label: "Work"))
        _ = await client.signOut()

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(work)?.label, "Alice's work")

        let home = try harness.client(.named("home", label: "Home"))
        try await home.setSessionLabel("Shared iPad")

        try await home.signInForTest("bob")

        XCTAssertEqual(try harness.storedRecord(ClientFixtures.id("home"))?.label, "Shared iPad")
    }

    /// When a different user signs in, the previous user's label is dropped, and the ID's label names the new
    /// user's row.
    ///
    /// - Given: a session whose ID was created with a label, where alice signed in, renamed the row and signed out
    /// - When: bob signs in
    /// - Then:
    ///    - alice's signed-out row kept her label; bob's row has the ID's label
    func testADifferentUsersSignInSavesTheIDsLabel() async throws {
        let client = try harness.client(.named("work", label: "Work"))
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Alice's work")
        _ = await client.signOut()
        XCTAssertEqual(
            try harness.storedRecord(work),
            .signedOut(label: "Alice's work", username: "alice", userId: "sub-alice")
        )

        try await client.signInForTest("bob")

        let bob = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(bob.username, "bob")
        XCTAssertEqual(bob.label, "Work")
    }

    /// Two handles whose IDs were created with different labels are one session, which uses the label of the
    /// handle that built it.
    ///
    /// - Given: two clients of one session, the first built with one label and the second with another
    /// - When: a user signs in through the second
    /// - Then:
    ///    - they are one session; the row has the first handle's label; each handle's `sessionId` keeps its own
    func testTwoHandlesWithDifferentIDLabelsUseTheLabelOfTheOneThatBuiltTheSession() async throws {
        let first = try harness.client(.named("work", label: "First"))
        let second = try harness.client(.named("work", label: "Second"))
        XCTAssertEqual(harness.registry.entryCount, 1)
        XCTAssertEqual(harness.engines.count, 1)

        try await second.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(work)?.label, "First")
        XCTAssertEqual(first.sessionId.label, "First")
        XCTAssertEqual(second.sessionId.label, "Second")
        let state = await first.currentSessionState()
        XCTAssertEqual(state, .signedIn(AmplifyCognitoClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A guest and a federation save the ID's label, as a sign-in does.
    ///
    /// - Given: two sessions with nothing stored, each built with an ID created with a label
    /// - When: one's session is fetched, which makes it a guest, and a user then signs in; the other federates
    /// - Then:
    ///    - the guest's row has its ID's label, and the user keeps it; the federated row has its ID's label
    func testAGuestAndAFederationSaveTheIDsLabel() async throws {
        let kiosk = try harness.client(.named("work", label: "Kiosk"))

        _ = try await kiosk.fetchAuthSession()

        let guest = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(guest.kind, .guest)
        XCTAssertEqual(guest.label, "Kiosk")
        try await kiosk.signInForTest("alice")
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Kiosk")

        let home = ClientFixtures.id("home")
        let tablet = try harness.client(.named("home", label: "Tablet"))
        try XCTUnwrap(harness.engine(for: home)).scriptAccountOperation(.federateToIdentityPool) { _ in
            FakePayload.federated(identityId: "us-east-1:fed").data
        }

        _ = try await tablet.federateToIdentityPool(withProviderToken: "token", for: .google)

        let federated = try XCTUnwrap(harness.storedRecord(home))
        XCTAssertEqual(federated.kind, .federated)
        XCTAssertEqual(federated.label, "Tablet")
    }

    /// `setSessionLabel`, instance and static, replaces the label the ID supplied; once it is cleared, only a
    /// sign-in saves the ID's again.
    ///
    /// - Given: a signed-in session whose row took the label its ID was created with
    /// - When: the instance call renames it, the static call renames it again, the instance call clears it, and
    ///   the same user signs out and in again
    /// - Then:
    ///    - each call's label is the row's; cleared, the row has none; the sign-in saves the ID's again
    func testSetSessionLabelReplacesTheIDsLabel() async throws {
        let client = try harness.client(.named("work", label: "Work"))
        try await client.signInForTest("alice")
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Work")

        try await client.setSessionLabel("Renamed")
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Renamed")

        try await AmplifyCognitoClient.setSessionLabel(
            "Picked",
            sessionId: .named("work", label: "Ignored"),
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Picked")

        try await client.setSessionLabel(nil)
        XCTAssertNil(try harness.storedRecord(work)?.label)

        _ = await client.signOut()
        try await client.signInForTest("alice")
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Work")
    }

    /// Only a sign-in saves the ID's label: a session that is already signed in keeps its row as it is.
    ///
    /// - Given: a signed-in session saved with no label, needing a refresh
    /// - When: a client built with an ID created with a label refreshes it
    /// - Then:
    ///    - the refreshed row still has no label
    func testARefreshNeverSavesTheIDsLabel() async throws {
        let alice = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, alice)
        let client = try harness.client(.named("work", label: "Work"))

        _ = try await client.userPoolTokenProvider.accessToken()

        XCTAssertEqual(try harness.storedRecord(work), alice.refreshed.record(label: nil))
    }

    /// - Given: a signed-in session saved with no label
    /// - When: a client built with an ID created with a label signs it out
    /// - Then:
    ///    - the signed-out row has no label: only a sign-in saves the ID's
    func testASignOutNeverSavesTheIDsLabel() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(.named("work", label: "Work"))

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: nil, username: "alice", userId: "sub-alice"))
    }
}
