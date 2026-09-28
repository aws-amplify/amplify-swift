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

/// The projection from a stored record to `AuthSessionState`, and `currentSessionState()`.
///
/// There is deliberately no `isSignedIn` in the API: it would answer `false` for `.guest` and for
/// `.unavailable`, conflating "no usable credentials" with "could not look". These tests switch over
/// the state instead.
final class SessionStateProjectionTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    private func state(of sessionId: SessionID) async throws -> AuthSessionState {
        try await harness.client(sessionId).currentSessionState()
    }

    private func put(_ record: SessionRecord, for sessionId: SessionID) throws {
        try harness.store().write(record, for: sessionId, expecting: nil)
        harness.keychain.resetLogs()
    }

    private func assertFailed(_ state: AuthSessionState, mentioning fragment: String, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failed(let error) = state else {
            return XCTFail("expected .failed, got \(state)", file: file, line: line)
        }
        XCTAssertTrue(error.errorDescription.contains(fragment), error.errorDescription, file: file, line: line)
    }

    // MARK: Rows that need no engine

    /// - Given: nothing stored for the session
    /// - When: its state is read
    /// - Then:
    ///    - it is `.signedOut`
    func testAbsentIsSignedOut() async throws {
        let state = try await state(of: work)
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a signed-out row kept after sign-out, with a label
    /// - When: its state is read
    /// - Then:
    ///    - it is `.signedOut`
    func testSignedOutRowIsSignedOut() async throws {
        try put(.signedOut(label: "Work", username: "alice", userId: "sub-alice"), for: work)
        let state = try await state(of: work)
        XCTAssertEqual(state, .signedOut)
    }

    /// Once the record carries the user ID, reporting the user needs no engine at all.
    ///
    /// - Given: a signed-in record with a username and user ID
    /// - When: its state is read
    /// - Then:
    ///    - it is `.signedIn` as that user, and the engine was never asked to describe the credentials
    func testSignedInRecordNeedsNoEngine() async throws {
        try put(FakePayload.signedIn("alice").record(), for: work)

        let state = try await state(of: work)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(harness.engine(for: work)?.describeCount, 0)
    }

    /// - Given: a guest record
    /// - When: its state is read
    /// - Then:
    ///    - it is `.guest`, with no engine call
    func testGuestRecordIsGuest() async throws {
        try put(FakePayload.guest().record(), for: work)

        let state = try await state(of: work)

        XCTAssertEqual(state, .guest)
        XCTAssertEqual(harness.engine(for: work)?.describeCount, 0)
    }

    /// - Given: a record whose kind says it holds credentials, but which has none
    /// - When: its state is read
    /// - Then:
    ///    - it is `.failed`, naming the inconsistency — never `.signedOut`
    func testInconsistentRecordIsFailed() async throws {
        try put(SessionRecord(label: nil, username: "alice", kind: .userPoolOnly, credentials: nil), for: work)
        let state = try await state(of: work)
        assertFailed(state, mentioning: "inconsistent")
    }

    /// - Given: a record written by a newer schema, and corrupt bytes, under two sessions' keys
    /// - When: their states are read
    /// - Then:
    ///    - both are `.failed(.unknown)`, the first naming a newer version, the second saying it is
    ///      unreadable; the two failures are not equal
    func testUnreadableRecordsAreFailedAndTellWhich() async throws {
        let home = ClientFixtures.id("home")
        harness.keychain.put(StorageFixtures.futureSchemaRecord, harness.store().sessionAccount(for: work))
        harness.keychain.put(StorageFixtures.corruptRecord, harness.store().sessionAccount(for: home))

        let newer = try await state(of: work)
        let corrupt = try await state(of: home)

        assertFailed(newer, mentioning: "newer version")
        assertFailed(corrupt, mentioning: "unreadable")
        XCTAssertNotEqual(newer, corrupt, "two different failures must not compare equal")
    }

    // MARK: Rows that need the engine

    /// - Given: a signed-in record written before records carried the user ID
    /// - When: its state is read
    /// - Then:
    ///    - the engine describes the credentials, and the state is `.signedIn` as the user they name
    func testRecordWithoutUserIdIsDescribedByTheEngine() async throws {
        try put(FakePayload.signedIn("alice").record(includeUserId: false), for: work)

        let state = try await state(of: work)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertGreaterThan(harness.engine(for: work)?.describeCount ?? 0, 0)
    }

    /// - Given: `.default` with no record of its own, and the Auth plugin's record holding a user
    /// - When: its state is read
    /// - Then:
    ///    - it reads through: the engine describes the plugin's payload and the state is that user
    func testDefaultReadsThroughToThePluginRecord() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools))

        let state = try await state(of: .default)

        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: the plugin's record holding bytes the engine cannot read
    /// - When: `.default`'s state is read
    /// - Then:
    ///    - it is `.failed`, never `.signedOut`, since a record is present
    func testUndescribablePluginRecordIsFailed() async throws {
        harness.keychain.put(Data("opaque".utf8), SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools))
        let state = try await state(of: .default)
        assertFailed(state, mentioning: "could not be read")
    }

    /// - Given: a session whose engine has a sign-in waiting on the user
    /// - When: its state is read
    /// - Then:
    ///    - the challenge overlays the stored state: `.awaitingChallenge(step)`
    func testPendingChallengeOverlaysTheState() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.setPendingChallenge(.confirmSignInWithTOTPCode)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// Restore reads the engine's pending challenge across a suspension. A newer challenge recorded on the
    /// session meanwhile must win over the value the restore read earlier.
    ///
    /// - Given: an engine reporting one challenge, and a newer challenge recorded on the session while the
    ///   restore is suspended reading the engine's
    /// - When: the session restores
    /// - Then:
    ///    - the state is the newer challenge
    func testRestoreDoesNotOverwriteANewerChallenge() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.setPendingChallenge(.confirmSignInWithTOTPCode)
        let core = client.core
        engine.duringPendingChallengeRead {
            engine.duringPendingChallengeRead(nil)
            await core.setPendingChallenge(.confirmSignInWithPassword)
        }

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithPassword))
    }

    /// - Given: a pending challenge, over storage that cannot be read
    /// - When: the state is read
    /// - Then:
    ///    - the storage failure wins: `.unavailable`, since what is stored is unknown
    func testStorageFailureIsNotHiddenByAChallenge() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.setPendingChallenge(.confirmSignInWithTOTPCode)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)
        defer { harness.keychain.clearFailures() }

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .unavailable(.locked))
    }

    /// The projection itself, as the core calls it, for each source kind at once.
    ///
    /// - Given: snapshots for every source, and the fake engine
    /// - When: each is projected with and without a challenge
    /// - Then:
    ///    - each maps to its row, and a challenge overlays only the states that are not failures
    func testProjectionTable() throws {
        let engine = try harness.client(work).core.engine
        let signedIn = FakePayload.signedIn("alice").record()
        let rows: [(SessionSnapshot, AuthSessionState)] = [
            (.absent, .signedOut),
            (SessionSnapshot(generation: 1, source: .own(.signedOut(label: nil, username: nil))), .signedOut),
            (SessionSnapshot(generation: 1, source: .own(signedIn)), .signedIn(alice)),
            (SessionSnapshot(generation: 1, source: .own(FakePayload.guest().record())), .guest),
            (SessionSnapshot(generation: nil, source: .pluginReadThrough(FakePayload.signedIn("alice").data)), .signedIn(alice))
        ]
        for (snapshot, expected) in rows {
            XCTAssertEqual(snapshot.state(engine: engine, challenge: nil), expected, "\(snapshot)")
            XCTAssertEqual(snapshot.state(engine: engine, challenge: .confirmSignInWithPassword), .awaitingChallenge(.confirmSignInWithPassword))
        }
        let corrupt = SessionSnapshot(generation: nil, source: .unreadable(.corrupt))
        guard case .failed = corrupt.state(engine: engine, challenge: .confirmSignInWithPassword) else {
            return XCTFail("a challenge must not hide an unreadable record")
        }
    }
}
