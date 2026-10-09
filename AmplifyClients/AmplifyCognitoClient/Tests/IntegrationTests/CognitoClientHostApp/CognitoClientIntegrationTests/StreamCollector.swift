//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

/// Collects every element of a session's state or event stream, from the moment it is made.
///
/// Subscribe before the operation under test, then read `elements` or wait for a count. The collecting
/// task holds no client handle, so it never keeps a session alive; `stop()` ends it.
///
/// - Note: `@unchecked Sendable`: `received` and `waiters` are only touched while holding `lock`.
final class StreamCollector<Element: Sendable>: @unchecked Sendable {

    private struct Waiter {
        let id: UUID
        let count: Int
        let continuation: CheckedContinuation<Void, Error>
    }

    private let lock = NSLock()
    private var received: [Element] = []
    private var waiters: [Waiter] = []
    private var task: Task<Void, Never>?

    init(_ stream: AsyncStream<Element>) {
        self.task = Task { [weak self] in
            for await element in stream {
                self?.append(element)
            }
        }
    }

    deinit {
        task?.cancel()
    }

    /// Everything received so far, in order.
    var elements: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return received
    }

    /// Waits until at least `count` elements arrived: resumed by the arrival itself, not by polling. The
    /// bound only stops a missing element from hanging the run; nothing asserts on how long the wait takes.
    func waitFor(_ count: Int, timeout: TimeInterval = 10) async throws {
        let id = UUID()
        let timer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            self?.expire(id)
        }
        defer { timer.cancel() }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            if received.count >= count {
                lock.unlock()
                continuation.resume()
                return
            }
            waiters.append(Waiter(id: id, count: count, continuation: continuation))
            lock.unlock()
        }
    }

    func stop() {
        task?.cancel()
    }

    private func append(_ element: Element) {
        lock.lock()
        received.append(element)
        let total = received.count
        let ready = waiters.filter { $0.count <= total }
        waiters.removeAll { $0.count <= total }
        lock.unlock()
        for waiter in ready {
            waiter.continuation.resume()
        }
    }

    private func expire(_ id: UUID) {
        lock.lock()
        let expired = waiters.first { $0.id == id }
        waiters.removeAll { $0.id == id }
        let total = received.count
        lock.unlock()
        expired?.continuation.resume(throwing: HarnessError.timedOut("\(expired?.count ?? 0) stream elements; received \(total)"))
    }
}

/// A token's SHA-256, hex: what tests compare, so a failing assertion never prints a sandbox token.
func fingerprint(_ token: String) -> String {
    SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
}
