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

/// The static `setSessionLabel(_:sessionId:configuration:accessGroup:)`: labelling a saved session without
/// building a client for it, and through the live client when there is one.
///
/// The instance call, and how a label follows its user, are `SessionRecordOperationsTests`; a session carried
/// from a previous configuration is `SessionCopyForwardTests` and `DefaultSessionConfigurationChangeTests`.
final class StoredSessionLabelTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }
    private var sidecarAccount: String { SessionRecordKey.metaAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Helpers

    private func setLabel(
        _ label: String?,
        _ sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration = ClientFixtures.configuration
    ) async throws {
        try await AmplifyCognitoClient.setSessionLabel(
            label,
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
    }

    private func listedLabels() async throws -> [String?] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: harness.dependencies
        ).map(\.label)
    }

    /// The label on `.default`'s sidecar and the user it is bound to, or `nil` if there is no readable sidecar.
    private func sidecar() throws -> [String?]? {
        guard let bytes = harness.keychain.value(sidecarAccount), case .meta(let meta) = DefaultSessionMeta.decode(bytes) else {
            return nil
        }
        return [meta.label, meta.username, meta.userId]
    }

    // MARK: No client holds the session

    /// - Given: a saved, signed-in session that no client holds
    /// - When: its label is set through the static call, then cleared
    /// - Then:
    ///    - only the label changes each time, and the listing shows it; the credentials are kept, nothing is
    ///      revoked and no engine is built
    func testLabellingASavedSessionNoClientHolds() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice, label: "Old")

        try await setLabel("Work", work)
        let labelled = try harness.storedRecord(work)
        let listed = try await listedLabels()
        try await setLabel(nil, work)

        XCTAssertEqual(labelled, alice.record(label: "Work"))
        XCTAssertEqual(listed, ["Work"])
        XCTAssertEqual(try harness.storedRecord(work), alice.record(label: nil))
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        XCTAssertNil(harness.engine(for: work))
    }

    /// - Given: a saved, signed-in session that no client holds, labelled through the static call
    /// - When: a client is then built for it and restores
    /// - Then:
    ///    - the client is signed in, and its copy of the record has the label
    func testAClientBuiltAfterTheStaticLabelRestoresIt() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try await setLabel("Work", work)

        let client = try harness.client(work)
        let state = await client.currentSessionState()

        guard case .signedIn = state else {
            return XCTFail("\(state)")
        }
        let held = await client.core.restoredSnapshotIfAny?.ownRecord?.label
        XCTAssertEqual(held, "Work")
    }

    /// - Given: the same session ID saved, signed in, in the app's own keychain and in an access group
    /// - When: its label is set through the static call with the access group
    /// - Then:
    ///    - only the access group's record has the label
    func testALabelWithAnAccessGroupWritesThatGroupsRecordOnly() async throws {
        let group = "group.example.shared"
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        try harness.signIn(work, alice, accessGroup: group)

        try await AmplifyCognitoClient.setSessionLabel(
            "Shared",
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: group,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(try harness.storedRecord(work, accessGroup: group), alice.record(label: "Shared"))
        XCTAssertEqual(try harness.storedRecord(work), alice.record(label: nil))
    }

    /// - Given: a session with nothing saved
    /// - When: its label is cleared, then set, through the static call
    /// - Then:
    ///    - clearing writes nothing: there is no label to clear
    ///    - setting creates a labelled signed-out row, listed only with `includingSignedOut: true`
    func testLabellingASessionWithNothingSavedCreatesALabelledSignedOutRow() async throws {
        try await setLabel(nil, work)
        let writtenByClearing = harness.keychain.writtenAccounts

        try await setLabel("Work", work)

        XCTAssertEqual(writtenByClearing, [])
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: nil))
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: false), [])
        let listed = try await listedLabels()
        XCTAssertEqual(listed, ["Work"])
    }

    /// `.default`'s label lives in its sidecar, from the static call too: the plugin's record is never rewritten.
    ///
    /// - Given: `.default` on the plugin's record, holding alice, under the plugin's last configuration, with no
    ///   client live
    /// - When: its label is set through the static call
    /// - Then:
    ///    - only the sidecar is written, bound to alice, with the label; the plugin's record is byte-identical
    func testLabellingTheDefaultSessionWritesOnlyTheSidecar() async throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        harness.keychain.resetLogs()

        try await setLabel("Main", .default)

        XCTAssertEqual(harness.keychain.writtenAccounts, [sidecarAccount])
        XCTAssertEqual(harness.keychain.value(pluginAccount), alice.data)
        XCTAssertEqual(try sidecar(), ["Main", "alice", "sub-alice"])
        XCTAssertEqual(try harness.storedRecord(.default), alice.record(label: "Main"))
    }

    /// A record this build cannot read is never overwritten.
    ///
    /// - Given: under the session's key, in turn, corrupt bytes and a record a newer version saved (schema 2),
    ///   and no client live
    /// - When: a label is set through the static call
    /// - Then:
    ///    - it throws `.unknown`, and the bytes are untouched
    func testLabellingAnUnreadableRecordThrowsAndWritesNothing() async throws {
        let account = harness.store().sessionAccount(for: work)
        let dependencies = harness.dependencies
        let work = work
        for unreadable in [StorageFixtures.corruptRecord, StorageFixtures.futureSchemaRecord] {
            harness.keychain.put(unreadable, account)

            await assertThrowsAsync({
                try await AmplifyCognitoClient.setSessionLabel(
                    "Work",
                    sessionId: work,
                    configuration: ClientFixtures.configuration,
                    accessGroup: nil,
                    dependencies: dependencies
                )
            }) { error in
                guard case .unknown = error as? AmplifyCognitoClientError else {
                    return XCTFail("\(error)")
                }
            }
            XCTAssertEqual(harness.keychain.value(account), unreadable)
        }
    }

    /// A lost race is rebased, not forced, as the instance's is.
    ///
    /// - Given: saved, signed-in sessions no client holds, and for each another writer that refreshes its
    ///   credentials once, right after the call's first, second or third read of the record (so before the label
    ///   write's read for one, and between its read and its write for another)
    /// - When: each label is set through the static call
    /// - Then:
    ///    - every label lands on the fresh record, and the fresh credentials are the ones kept: an older payload is
    ///      never written back
    func testALabelSurvivesAConcurrentWriteAndKeepsTheFreshCredentials() async throws {
        let fresh = FakePayload.signedIn("alice", version: 2)
        // The call's reads of the record: the carry-forward read, the label write's read, then the write's own
        // guard read. Renumber if a read is added before the label write.
        for occurrence in 1 ... 3 {
            let sessionId = ClientFixtures.id("work-\(occurrence)")
            try harness.signIn(sessionId, .signedIn("alice", version: 1))
            let rival = ConcurrentWriter(store: harness.store(), sessionId: sessionId) { envelope in
                var record = envelope.record
                record.credentials = fresh.data
                return record
            }
            harness.keychain.onceAfterReading(harness.store().sessionAccount(for: sessionId), occurrence: occurrence) {
                rival.move()
            }

            try await setLabel("Work", sessionId)

            harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: sessionId), nil)
            XCTAssertEqual(rival.commits, 1, "read \(occurrence)")
            XCTAssertEqual(try harness.storedRecord(sessionId), fresh.record(label: "Work"), "read \(occurrence)")
        }
    }

    /// - Given: a saved, signed-in session no client holds, and another writer that moves the record after every
    ///   read
    /// - When: a label is set through the static call
    /// - Then:
    ///    - it throws `storageUnavailable(.interrupted)` rather than forcing, and the label is not written
    func testALabelGivesUpWhenTheRecordKeepsChanging() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work, budget: 100) { envelope in
            var record = envelope.record
            record.label = "rival-\(envelope.generation)"
            return record
        }
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work)) { rival.move() }
        let dependencies = harness.dependencies
        let work = work

        await assertThrowsAsync({
            try await AmplifyCognitoClient.setSessionLabel(
                "Work",
                sessionId: work,
                configuration: ClientFixtures.configuration,
                accessGroup: nil,
                dependencies: dependencies
            )
        }) { error in
            XCTAssertEqual((error as? AmplifyCognitoClientError)?.storageUnavailableReason, .interrupted, "\(error)")
        }
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        XCTAssertNotEqual(try harness.storedRecord(work)?.label, "Work")
    }

    // MARK: A live client holds the session

    /// - Given: a signed-in session with a live, restored client
    /// - When: its label is set through the static call, then the client signs out
    /// - Then:
    ///    - the saved record and the listing have the label, and so does the client's own copy of the record
    ///    - no event is sent for the label, and the client's sign-out keeps it on the signed-out row
    func testLabellingASessionALiveClientHoldsGoesThroughTheClient() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        try await setLabel("Work", work)
        let held = await client.core.restoredSnapshotIfAny?.ownRecord?.label
        let listed = try await listedLabels()
        let eventsAfterLabel = events.received
        await client.signOut()

        XCTAssertEqual(held, "Work")
        XCTAssertEqual(listed, ["Work"])
        XCTAssertEqual(eventsAfterLabel, [])
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
    }

    /// - Given: `.default` on the plugin's record, holding alice, with a live, restored client
    /// - When: its label is set through the static call
    /// - Then:
    ///    - only the sidecar is written, bound to alice, and the client's own copy of the record has the label
    func testLabellingTheDefaultSessionALiveClientHolds() async throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        harness.keychain.resetLogs()

        try await setLabel("Main", .default)

        let held = await client.core.restoredSnapshotIfAny?.ownRecord?.label
        XCTAssertEqual(held, "Main")
        XCTAssertEqual(harness.keychain.writtenAccounts, [sidecarAccount])
        XCTAssertEqual(try sidecar(), ["Main", "alice", "sub-alice"])
        XCTAssertEqual(harness.keychain.value(pluginAccount), alice.data)
    }

    /// - Given: a live, signed-in client for `"work"` built with a user-pool-only configuration
    /// - When: `"work"` is labelled with a configuration that adds an identity pool
    /// - Then:
    ///    - the call throws `sessionConfigurationMismatch` naming the session, and nothing is written under
    ///      either configuration
    func testALabelUnderAnotherConfigurationThanTheLiveClientsIsRefused() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
        _ = try await client.signInForTest()
        harness.keychain.resetLogs()
        let dependencies = harness.dependencies
        let work = work

        await assertThrowsAsync({
            try await AmplifyCognitoClient.setSessionLabel(
                "Work",
                sessionId: work,
                configuration: ClientFixtures.configuration,
                accessGroup: nil,
                dependencies: dependencies
            )
        }) { error in
            guard case .sessionConfigurationMismatch(let sessionId)? = (error as? AmplifyCognitoClientError)?.kind else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(sessionId, work)
        }

        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        let held = await client.core.restoredSnapshotIfAny?.ownRecord?.label
        XCTAssertNil(held)
    }
}
