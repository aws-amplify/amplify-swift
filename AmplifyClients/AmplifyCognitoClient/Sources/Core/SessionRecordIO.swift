//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Dispatch
import Foundation

/// The session record store, with every blocking keychain call moved off Swift's cooperative thread pool.
///
/// `SessionRecordStore` is synchronous: each call is a `SecItem*` call that blocks its thread, sometimes for
/// a long time (a locked device, a busy `securityd`). Run on the cooperative pool, a stuck call pins one of
/// its few threads — the pool is as wide as the core count, two on a watch. With one session restoring per
/// ID at launch, enough stuck calls pin every thread, and then nothing in the app's Swift concurrency runs:
/// not the restore bound's timer, not the cancellation that abandons a waiter. The bound only holds if the
/// blocking work is somewhere else.
///
/// **So this is a deliberate exception to the rule against new `DispatchQueue`s.** The queue does not
/// carry the design's concurrency — the gate, the actors and `SingleFlight` still do. It only isolates
/// blocking I/O, and each call is bridged back with a continuation, so the caller suspends instead of
/// blocking. Each record has its own serial queue (owned by its `SessionRecordGate`), so one record's stuck
/// call never delays another record; calls on one record are already serialized by its gate.
///
/// A stuck call still occupies its queue's thread until the keychain returns. That cannot be reclaimed, but
/// it is a Dispatch thread, not a cooperative one, so every bound and cancellation keeps working.
struct SessionRecordIO: Sendable {

    /// The queue for listings, which take no record's gate.
    static let listingQueue = DispatchQueue(label: "com.amazonaws.amplify.cognito-client.listing-io", attributes: .concurrent)

    static func makeRecordQueue() -> DispatchQueue {
        DispatchQueue(label: "com.amazonaws.amplify.cognito-client.record-io")
    }

    let store: SessionRecordStore
    let queue: DispatchQueue

    /// Runs `work` against the store on the I/O queue; the caller suspends until it returns.
    func perform<T: Sendable>(_ work: @escaping @Sendable (SessionRecordStore) throws -> T) async throws -> T {
        let store = store
        return try await runBlocking(on: queue) { try work(store) }
    }

    func read(_ sessionId: SessionID) async throws -> SessionRecordStore.ReadResult {
        try await perform { try $0.read(sessionId) }
    }

    func load(_ sessionId: SessionID) async throws -> SessionSnapshot {
        try await SessionSnapshot(read(sessionId))
    }

    /// `load`, carrying the session's record forward from a previous configuration's namespace when this
    /// one holds none (`SessionRecordStore.readCarryingForward`). What a restore reads.
    func loadCarryingForward(_ sessionId: SessionID, heldSource: PoolNamespace?? = nil) async throws -> SessionSnapshot {
        try await SessionSnapshot(perform { try $0.readCarryingForward(sessionId, heldSource: heldSource) })
    }

    func write(
        _ record: SessionRecord,
        for sessionId: SessionID,
        expecting generation: UInt64?
    ) async throws -> SessionRecordStore.CommitOutcome {
        try await perform { try $0.write(record, for: sessionId, expecting: generation) }
    }

    func signOut(_ sessionId: SessionID) async throws -> SessionRecordStore.SignOutOutcome {
        try await perform { try $0.signOut(sessionId) }
    }

    func signOut(_ sessionId: SessionID, removing credentials: Data) async throws -> SessionRecordStore.SignOutOutcome {
        try await perform { try $0.signOut(sessionId, removing: credentials) }
    }

    func purge(_ sessionId: SessionID) async throws {
        try await perform { try $0.purge(sessionId) }
    }

    func pluginRecord(for sessionId: SessionID) async throws -> Data? {
        try await perform { try $0.pluginRecord(for: sessionId) }
    }

    func removePluginRecord(for sessionId: SessionID) async throws {
        try await perform { try $0.removePluginRecord(for: sessionId) }
    }

    func storedSessions(includingSignedOut: Bool, sweepingChallengesAt now: Date? = nil) async throws -> [StoredSession] {
        try await perform { try $0.storedSessions(includingSignedOut: includingSignedOut, sweepingChallengesAt: now) }
    }

    // MARK: The challenge record

    func readChallenge(_ sessionId: SessionID) async throws -> SessionRecordStore.ChallengeRead {
        try await perform { try $0.readChallenge(sessionId) }
    }

    @discardableResult
    func writeChallenge(_ record: ChallengeRecord, for sessionId: SessionID) async throws -> ChallengeRecord {
        try await perform { try $0.writeChallenge(record, for: sessionId) }
    }

    func deleteChallenge(_ sessionId: SessionID) async throws {
        try await perform { try $0.deleteChallenge(sessionId) }
    }

    func signedInUserIds(describe: @escaping @Sendable (Data) -> CredentialSummary?) async throws -> [SessionID: String] {
        try await perform { try $0.signedInUserIds(describe: describe) }
    }
}
