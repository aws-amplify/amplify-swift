//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class SessionRegistryTests: XCTestCase {

    private final class FakeSession: Sendable {}

    private typealias Registry = SessionRegistry<String, Int, FakeSession>

    /// Decision 1: two handles with the same session ID and configuration are one session.
    ///
    /// - Given: a live session registered under an ID
    /// - When: the same ID is requested with the same namespace and fingerprint
    /// - Then:
    ///    - the existing instance is returned and `make` is not called again
    func testSameIDAndConfigurationSharesOneSession() throws {
        let registry = Registry()
        let id = try SessionID.named("work")
        var makes = 0
        let make = { () -> FakeSession in
            makes += 1
            return FakeSession()
        }
        let first = try registry.session(for: id, namespace: "pool-a", fingerprint: 1, make: make)
        let second = try registry.session(for: id, namespace: "pool-a", fingerprint: 1, make: make)
        XCTAssertTrue(first === second)
        XCTAssertEqual(makes, 1)
    }

    /// The case the previous design wording would have missed: keying by configuration made this a
    /// silent second session. Keyed by session ID, it has to throw.
    ///
    /// - Given: a live session under one pool namespace
    /// - When: the same ID is requested under a different namespace
    /// - Then:
    ///    - it throws `sessionConfigurationMismatch` naming the session, and no second session exists
    func testSameIDDifferentNamespaceThrows() throws {
        let registry = Registry()
        let id = try SessionID.named("work")
        let live = try registry.session(for: id, namespace: "pool-a", fingerprint: 1) { FakeSession() }

        XCTAssertThrowsError(try registry.session(for: id, namespace: "pool-b", fingerprint: 1) { FakeSession() }) { error in
            guard case AuthClientError.sessionConfigurationMismatch(let reported, _, _, _) = error else {
                return XCTFail("Expected sessionConfigurationMismatch, got \(error)")
            }
            XCTAssertEqual(reported, id)
        }
        XCTAssertTrue(try registry.session(for: id, namespace: "pool-a", fingerprint: 1) { FakeSession() } === live)
    }

    /// - Given: a live session
    /// - When: the same ID is requested with the same namespace but a different fingerprint
    /// - Then:
    ///    - it throws `sessionConfigurationMismatch`
    func testSameIDSameNamespaceDifferentFingerprintThrows() throws {
        let registry = Registry()
        let id = try SessionID.named("work")
        let live = try registry.session(for: id, namespace: "pool-a", fingerprint: 1) { FakeSession() }
        XCTAssertThrowsError(try registry.session(for: id, namespace: "pool-a", fingerprint: 2) { FakeSession() })
        withExtendedLifetime(live) {}
    }

    /// - Given: two different session IDs on the same pool
    /// - When: both are requested
    /// - Then:
    ///    - they are independent sessions
    func testDifferentIDsAreIndependent() throws {
        let registry = Registry()
        let work = try registry.session(for: try .named("work"), namespace: "pool-a", fingerprint: 1) { FakeSession() }
        let home = try registry.session(for: try .named("home"), namespace: "pool-a", fingerprint: 1) { FakeSession() }
        XCTAssertFalse(work === home)
    }

    /// Entries are weak, so a released session does not linger, and a released session's
    /// configuration no longer constrains a new one.
    ///
    /// - Given: a session whose last handle has been released
    /// - When: the same ID is requested again, even with a different namespace
    /// - Then:
    ///    - a fresh session is built rather than throwing or returning a dead one
    func testReleasedSessionIsRebuiltAndNoLongerConstrains() throws {
        let registry = Registry()
        let id = try SessionID.named("work")
        weak var released: FakeSession?
        do {
            let session = try registry.session(for: id, namespace: "pool-a", fingerprint: 1) { FakeSession() }
            released = session
        }
        XCTAssertNil(released, "The registry must not keep a session alive")
        XCTAssertFalse(registry.liveSessionIDs.contains(id))

        var rebuilt = false
        _ = try registry.session(for: id, namespace: "pool-b", fingerprint: 2) {
            rebuilt = true
            return FakeSession()
        }
        XCTAssertTrue(rebuilt)
    }

    /// - Given: a released entry and a live one
    /// - When: `pruneIfReleased` is called on each
    /// - Then:
    ///    - only the released entry is removed
    func testPruneRemovesOnlyReleasedEntries() throws {
        let registry = Registry()
        let liveID = try SessionID.named("live")
        let deadID = try SessionID.named("dead")
        let live = try registry.session(for: liveID, namespace: "pool-a", fingerprint: 1) { FakeSession() }
        do { _ = try registry.session(for: deadID, namespace: "pool-a", fingerprint: 1) { FakeSession() } }

        registry.pruneIfReleased(deadID)
        registry.pruneIfReleased(liveID)

        XCTAssertEqual(registry.liveSessionIDs, [liveID])
        XCTAssertTrue(try registry.session(for: liveID, namespace: "pool-a", fingerprint: 1) { FakeSession() } === live)
    }

    /// Concurrent construction of one session ID must yield one session, never two. Asserts on the
    /// number of `make` calls rather than on timing, so a CI retry cannot mask a race.
    ///
    /// Every handle is kept alive for the whole test. Without that, a thread's handle can be
    /// released before another thread looks up, and the registry then correctly builds a fresh
    /// session — which is release behaviour, not a race, and would make the count flaky.
    ///
    /// - Given: many threads constructing the same session ID at once, each holding its handle
    /// - When: all complete
    /// - Then:
    ///    - `make` ran exactly once and every caller received the same instance
    func testConcurrentConstructionBuildsExactlyOneSession() throws {
        let registry = Registry()
        let id = try SessionID.named("work")
        let tally = Tally()

        DispatchQueue.concurrentPerform(iterations: 64) { _ in
            let session = try? registry.session(for: id, namespace: "pool-a", fingerprint: 1) {
                tally.recordMake()
                return FakeSession()
            }
            if let session {
                tally.recordResult(session)
            }
        }

        XCTAssertEqual(tally.makes, 1)
        XCTAssertEqual(tally.results.count, 64)
        XCTAssertEqual(Set(tally.results.map(ObjectIdentifier.init)).count, 1)
    }

    private final class Tally: @unchecked Sendable {
        private let lock = NSLock()
        private var _makes = 0
        private var _results: [FakeSession] = []

        func recordMake() {
            lock.lock()
            defer { lock.unlock() }
            _makes += 1
        }

        func recordResult(_ session: FakeSession) {
            lock.lock()
            defer { lock.unlock() }
            _results.append(session)
        }

        var makes: Int {
            lock.lock()
            defer { lock.unlock() }
            return _makes
        }

        var results: [FakeSession] {
            lock.lock()
            defer { lock.unlock() }
            return _results
        }
    }

    /// - Given: a `make` closure that throws
    /// - When: the session is requested
    /// - Then:
    ///    - the error propagates and no entry is left behind
    func testThrowingMakeLeavesNoEntry() throws {
        struct Boom: Error {}
        let registry = Registry()
        let id = try SessionID.named("work")
        XCTAssertThrowsError(try registry.session(for: id, namespace: "pool-a", fingerprint: 1) { throw Boom() })
        XCTAssertTrue(registry.liveSessionIDs.isEmpty)
    }
}
