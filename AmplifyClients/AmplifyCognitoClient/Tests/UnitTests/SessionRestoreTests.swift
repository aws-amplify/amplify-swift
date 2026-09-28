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

/// The bounded, uncached restore.
final class SessionRestoreTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: a stored, signed-in session, and construction that schedules the warm restore as the
    ///   live client does
    /// - When: its state is read straight after construction, with no sequencing by the caller
    /// - Then:
    ///    - it reports the stored user
    func testOperationRightAfterConstructionSucceeds() async throws {
        harness = ClientHarness(restoresOnConstruction: true)
        try harness.signIn(work, .signedIn("alice"))

        let state = try await harness.client(work).currentSessionState()

        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// The bound is real only because what is raced is abandonable: the stuck read carries on, and the
    /// caller stops waiting. Nothing here measures time — the stall is released only after the answer
    /// arrives, which proves the answer did not wait for it.
    ///
    /// - Given: a stored session whose record read blocks until released, and a short restore bound
    /// - When: the session's state is read
    /// - Then:
    ///    - it is `.unavailable(.interrupted)` while the read is still stuck — never `.signedOut`
    ///    - once storage recovers, the next read reports the user
    func testStalledRestoreSurfacesUnavailableAndRecovers() async throws {
        harness.setRestoreBound(nanoseconds: 200_000_000)
        try harness.signIn(work, .signedIn("alice"))
        let stall = Stall()
        defer { stall.release() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { stall.block() }
        let client = try harness.client(work)

        let stalled = await client.currentSessionState()

        XCTAssertEqual(stalled, .unavailable(.interrupted))
        XCTAssertTrue(stall.hasBeenReached, "the read was still stuck when the state came back")
        stall.release()
        let recovered = await client.currentSessionState()
        XCTAssertEqual(recovered, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// - Given: a stored session whose reads fail as if entitlements were missing
    /// - When: its state is read twice, and again once storage recovers
    /// - Then:
    ///    - both failures are `.unavailable(.denied)`, each from one fresh read (the failure is not
    ///      cached, and no call retries on its own)
    ///    - the read after recovery reports the user
    func testDeniedStorageSurfacesDeniedWithOneReadPerOperation() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecMissingEntitlement)

        let first = await client.currentSessionState()
        XCTAssertEqual(first, .unavailable(.denied))
        XCTAssertEqual(harness.recordReads(work), 1)

        let second = await client.currentSessionState()
        XCTAssertEqual(second, .unavailable(.denied))
        XCTAssertEqual(harness.recordReads(work), 2)

        harness.keychain.clearFailures()
        let recovered = await client.currentSessionState()
        XCTAssertEqual(recovered, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A storage failure must never be answered with sign-in.
    ///
    /// - Given: one session with nothing stored, and one whose storage is locked
    /// - When: both states are read
    /// - Then:
    ///    - the first is `.signedOut`, the second `.unavailable(.locked)`, and the two are not equal
    func testAbsentIsSignedOutButFailureIsUnavailable() async throws {
        let absent = try await harness.client(ClientFixtures.id("empty")).currentSessionState()
        harness.keychain.failingReads(of: harness.store().sessionAccount(for: work), with: errSecInteractionNotAllowed)
        let locked = try await harness.client(work).currentSessionState()

        XCTAssertEqual(absent, .signedOut)
        XCTAssertEqual(locked, .unavailable(.locked))
        XCTAssertNotEqual(absent, locked)
    }

    /// - Given: a stored session with nothing restored yet
    /// - When: fifty callers read its state at once
    /// - Then:
    ///    - they all get the user, from exactly one read of the record
    func testConcurrentFirstCallersShareOneRead() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)

        let states = await withTaskGroup(of: AuthSessionState.self) { group in
            for _ in 0 ..< 50 {
                group.addTask { await client.currentSessionState() }
            }
            var states: [AuthSessionState] = []
            for await state in group {
                states.append(state)
            }
            return states
        }

        XCTAssertEqual(states.count, 50)
        XCTAssertTrue(states.allSatisfy { $0 == .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")) })
        XCTAssertEqual(harness.recordReads(work), 1)
    }

    /// Restore decodes a record; it does not check expiry or touch the network.
    ///
    /// - Given: a stored session whose credentials need a refresh
    /// - When: its state is read
    /// - Then:
    ///    - it reports the user without any engine refresh
    func testRestoreDoesNotRefresh() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 0)
    }

    /// - Given: a restored session, and a record then changed by another process
    /// - When: the state is read again
    /// - Then:
    ///    - it answers from memory, without reading storage again
    func testStateIsAnsweredFromMemoryAfterRestore() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try harness.store().write(FakePayload.signedIn("bob").record(), for: work, expecting: 1)
        harness.keychain.resetLogs()

        let again = await client.currentSessionState()

        XCTAssertEqual(again, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(harness.recordReads(work), 0)
    }
}
