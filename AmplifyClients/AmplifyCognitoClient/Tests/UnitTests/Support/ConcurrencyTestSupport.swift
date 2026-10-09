//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

/// Holds work in flight until the test opens it, so a test controls ordering with a continuation
/// instead of a sleep. Also counts arrivals, so a test can wait until work has actually reached
/// the gate rather than guessing how long that takes.
actor Gate {

    private var isOpen: Bool
    private var held: [CheckedContinuation<Void, Never>] = []
    private var arrivals = 0
    private var arrivalWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(isOpen: Bool = false) {
        self.isOpen = isOpen
    }

    /// Records an arrival, then suspends until the gate is open.
    func pass() async {
        arrivals += 1
        let reached = arrivalWaiters.filter { $0.count <= arrivals }
        arrivalWaiters.removeAll { $0.count <= arrivals }
        for waiter in reached {
            waiter.continuation.resume()
        }
        guard !isOpen else {
            return
        }
        await withCheckedContinuation { held.append($0) }
    }

    /// Opens the gate, releasing everything held and letting later arrivals straight through.
    func open() {
        isOpen = true
        let released = held
        held = []
        for continuation in released {
            continuation.resume()
        }
    }

    /// Suspends until at least `count` arrivals have been recorded.
    func waitForArrivals(_ count: Int) async {
        guard arrivals < count else {
            return
        }
        await withCheckedContinuation { arrivalWaiters.append((count, $0)) }
    }

    var arrivalCount: Int {
        arrivals
    }
}

/// A shared tally that concurrent operations can bump.
actor Counter {

    private(set) var value = 0

    @discardableResult
    func increment() -> Int {
        value += 1
        return value
    }
}

/// Suspends until `condition` holds, yielding to other tasks between checks.
///
/// For state that changes on another task with no event to await, such as a waiter registering on
/// an actor. Bounded by a number of checks rather than by a clock, and it fails the test rather
/// than passing if the bound is reached, so it can make a test slow but never makes a wrong result
/// pass.
func waitUntil(
    _ description: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: () async -> Bool
) async {
    for check in 1 ... 1_000_000 {
        if await condition() {
            return
        }
        // Mostly yield; now and then sleep briefly, so work on another thread or a later-scheduled
        // task (a deinit's prune, a blocked keychain call) gets to run on a heavily loaded machine.
        if check.isMultiple(of: 100) {
            try? await Task.sleep(nanoseconds: 1_000_000)
        } else {
            await Task.yield()
        }
    }
    XCTFail("Condition never held: \(description)", file: file, line: line)
}

/// A failure a test fixture or a scripted fake throws.
struct FixtureError: Error, CustomStringConvertible {
    let description: String
}

/// Asserts an async throwing call throws, and hands the error to `check`.
func assertThrowsAsync(
    _ body: () async throws -> some Any,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ check: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await body()
        XCTFail("expected an error", file: file, line: line)
    } catch {
        check(error)
    }
}

/// `operation`'s result, or a `FixtureError` if it has not finished within `seconds`: a deadlock fails the test
/// instead of hanging it. The operation runs in an unstructured task, which a timeout abandons.
func bounded<Value: Sendable>(
    _ seconds: TimeInterval,
    _ what: String,
    _ operation: @escaping @Sendable () async throws -> Value
) async throws -> Value {
    let once = ResumeOnce<Value>()
    return try await withCheckedThrowingContinuation { continuation in
        once.set(continuation)
        Task {
            do {
                once.resume(with: .success(try await operation()))
            } catch {
                once.resume(with: .failure(error))
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            once.resume(with: .failure(FixtureError(description: "\(what) did not finish within \(seconds) s")))
        }
    }
}

/// Resumes a continuation at most once, whichever of its racers comes first.
private final class ResumeOnce<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?

    func set(_ continuation: CheckedContinuation<Value, Error>) {
        lock.withLock { self.continuation = continuation }
    }

    func resume(with result: Result<Value, Error>) {
        let continuation: CheckedContinuation<Value, Error>? = lock.withLock {
            defer { self.continuation = nil }
            return self.continuation
        }
        continuation?.resume(with: result)
    }
}
