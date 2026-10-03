//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A FIFO async mutex over one session record.
///
/// It is what serializes operations on one session: a restore, a label write, a refresh, a sign-out
/// and a static purge of the same record never interleave. The session actor cannot do this on its
/// own, because actors are re-entrant across the network `await`s an operation makes. Different
/// records are different gates, so different sessions never wait on each other.
///
/// `withLock` runs its body outside this actor, and the body's blocking keychain calls run on the
/// record's `ioQueue` through `SessionRecordIO`, so they occupy neither the gate, the session actor, nor
/// a cooperative-pool thread.
///
/// **Cancellation**, as in `SingleFlight`: a waiter cancelled while queued is removed and throws
/// `CancellationError`; a caller already cancelled when it arrives throws without queueing; and a
/// waiter granted at the moment it is cancelled releases the lock straight away and throws, so a
/// cancelled caller never runs its body and never leaves the lock held.
///
/// **Not re-entrant.** Only an operation's entry point takes it; the paths it calls take none.
actor SessionRecordGate {

    private typealias Waiter = CheckedContinuation<Void, Error>

    private var isHeld = false
    private var queue: [(id: UInt64, waiter: Waiter)] = []
    private var nextWaiterID: UInt64 = 0

    /// Where this record's blocking keychain calls run, off the cooperative pool (see `SessionRecordIO`).
    nonisolated let ioQueue = SessionRecordIO.makeRecordQueue()

    init() {}

    /// Runs `body` while holding the lock.
    ///
    /// - Throws: whatever `body` throws, or `CancellationError` if the caller is cancelled before it
    ///   holds the lock.
    nonisolated func withLock<T: Sendable>(_ body: @Sendable () async throws -> T) async throws -> T {
        try await acquire()
        if Task.isCancelled {
            await release()
            throw CancellationError()
        }
        do {
            let value = try await body()
            await release()
            return value
        } catch {
            await release()
            throw error
        }
    }

    /// Whether the lock is held. For tests.
    var isLocked: Bool {
        isHeld
    }

    /// The number of callers waiting for the lock. For tests.
    var waiterCount: Int {
        queue.count
    }

    private func acquire() async throws {
        let id = nextWaiterID
        nextWaiterID &+= 1
        try await withTaskCancellationHandler {
            // Runs synchronously on this actor, so checking, granting and queueing cannot interleave
            // with a release or with this caller's cancellation, which hops onto the actor.
            try await withCheckedThrowingContinuation { (waiter: Waiter) in
                guard !Task.isCancelled else {
                    waiter.resume(throwing: CancellationError())
                    return
                }
                if isHeld {
                    queue.append((id, waiter))
                } else {
                    isHeld = true
                    waiter.resume()
                }
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func release() {
        guard !queue.isEmpty else {
            isHeld = false
            return
        }
        // Hand the lock straight to the next waiter: it stays held, so no newcomer can barge in.
        queue.removeFirst().waiter.resume()
    }

    private func cancelWaiter(_ id: UInt64) {
        // Absent when the waiter was already granted, or cancelled before it queued. A granted waiter
        // sees its cancellation in `withLock` and releases there.
        guard let index = queue.firstIndex(where: { $0.id == id }) else {
            return
        }
        queue.remove(at: index).waiter.resume(throwing: CancellationError())
    }
}

/// The process-wide table of record gates, one per (namespace, session ID).
///
/// A session core holds its gate strongly for its lifetime, and a static session-management call holds
/// one for the duration of the call, so both always find the same gate for the same record. The table
/// holds gates weakly and forgets them once nobody holds them.
///
/// A gate's `deinit` does nothing, so a gate released while the table's lock is held (a weak load
/// promoting the last reference) is harmless: the registry's deinit hazard cannot recur here.
final class SessionRecordGates: @unchecked Sendable {

    struct Key: Hashable, Sendable {
        let namespace: SessionStorageNamespace
        let sessionId: SessionID
    }

    private final class WeakGate {
        weak var gate: SessionRecordGate?

        init(_ gate: SessionRecordGate) {
            self.gate = gate
        }
    }

    static let shared = SessionRecordGates()

    /// What a process remembers about one record across the cores that come and go for it: when its carried
    /// session may next try its identity step (`PendingIdentityRetry`), and its last reused refresh token
    /// (`RefreshTokenReuse`). Held strongly, for the life of the table (the process, for `shared`).
    final class RecordMemory: Sendable {
        let identityRetry = PendingIdentityRetry()
        let refreshTokenReuse = RefreshTokenReuse()

        /// Forgets it all (the reused refresh token included): the session was signed out or purged.
        func reset() {
            identityRetry.reset()
            refreshTokenReuse.reset()
        }
    }

    // `@unchecked Sendable`: `gates` and `memories` are only touched while holding `lock`.
    private let lock = NSLock()
    private var gates: [Key: WeakGate] = [:]
    private var memories: [Key: RecordMemory] = [:]

    init() {}

    /// The gate for one record: the live one if anybody holds it, else a new one.
    func gate(for namespace: SessionStorageNamespace, sessionId: SessionID) -> SessionRecordGate {
        let key = Key(namespace: namespace, sessionId: sessionId)
        lock.lock()
        defer { lock.unlock() }
        if let live = gates[key]?.gate {
            return live
        }
        gates = gates.filter { $0.value.gate != nil }
        let gate = SessionRecordGate()
        gates[key] = WeakGate(gate)
        return gate
    }

    /// What this table remembers about one record: the same object for every core of it.
    func memory(for namespace: SessionStorageNamespace, sessionId: SessionID) -> RecordMemory {
        let key = Key(namespace: namespace, sessionId: sessionId)
        lock.lock()
        defer { lock.unlock() }
        if let memory = memories[key] {
            return memory
        }
        let memory = RecordMemory()
        memories[key] = memory
        return memory
    }

    /// The number of gates somebody still holds. For tests that check the table returns to baseline.
    var liveGateCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return gates.values.count(where: { $0.gate != nil })
    }
}

extension SessionRecordGates {

    /// How many times a caller that must hold several records' gates takes them again when what it read
    /// before taking them changed meanwhile.
    static let maximumGateAttempts = 3

    /// One total order over record gates: by pool namespace, then access group.
    static func order(_ namespace: SessionStorageNamespace) -> String {
        "\(namespace.pools.keyComponent)\u{0}\(namespace.accessGroup ?? "")"
    }

    /// Runs `body` holding the gates of `namespaces` for `sessionId`, taken in the one global order, so two callers
    /// that each need several never deadlock.
    func holding<T: Sendable>(
        _ namespaces: [SessionStorageNamespace],
        sessionId: SessionID,
        _ body: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let ordered = Array(Set(namespaces)).sorted { Self.order($0) < Self.order($1) }
        return try await Self.holding(ordered.map { gate(for: $0, sessionId: sessionId) }, body)
    }

    private static func holding<T: Sendable>(
        _ gates: [SessionRecordGate],
        _ body: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        guard let first = gates.first else {
            return try await body()
        }
        let rest = Array(gates.dropFirst())
        return try await first.withLock { try await holding(rest, body) }
    }
}
