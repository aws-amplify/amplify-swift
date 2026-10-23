//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// Calls started at once, each in its own unstructured task, as the plugin's stress and race tests start
/// theirs, and awaited with `fulfillment(of:timeout:)` and the plugin's timeout: so a call that hangs, or a
/// batch slower than the plugin allows, fails the test instead of hanging the run.
///
/// Start them with `init`, do anything that must happen while they run, then `await` them with
/// `XCTestCase.results(of:timeout:)`. Each call's result or error is kept by index.
final class ConcurrentCalls<Value: Sendable>: @unchecked Sendable {

    let expectation: XCTestExpectation
    private let count: Int
    private let lock = NSLock()
    private var outcomes: [Int: Result<Value, Error>] = [:]

    init(_ description: String, count: Int, _ body: @escaping @Sendable (Int) async throws -> Value) {
        self.count = count
        self.expectation = XCTestExpectation(description: description)
        expectation.expectedFulfillmentCount = count
        for index in 0 ..< count {
            Task { [self] in
                let outcome: Result<Value, Error>
                do {
                    outcome = try await .success(body(index))
                } catch {
                    outcome = .failure(error)
                }
                lock.withLock { outcomes[index] = outcome }
                expectation.fulfill()
            }
        }
    }

    /// Every call's result, in index order. Throws the first call's error, or `timedOut` naming how many
    /// calls had not finished.
    func values() throws -> [Value] {
        let finished: [Int: Result<Value, Error>] = lock.withLock { outcomes }
        guard finished.count == count else {
            throw HarnessError.timedOut("\(expectation.description): \(count - finished.count) of \(count) calls had not finished")
        }
        return try (0 ..< count).map { try finished[$0]!.get() }
    }
}

/// `operation`'s result, or `HarnessError.timedOut` if it has not finished within `seconds`. The operation runs
/// in an unstructured task, which a timeout abandons (it may still finish later): a deadlock fails the caller
/// instead of hanging it. For code outside an `XCTestCase`, such as teardown's cleanup.
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
            once.resume(with: .failure(HarnessError.timedOut("\(what) within \(Int(seconds)) s")))
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

extension XCTestCase {

    /// Waits for `calls` at most `timeout` (`fulfillment(of:timeout:)`, which fails the test on a timeout),
    /// and returns their results in index order.
    func results<Value>(of calls: ConcurrentCalls<Value>, timeout: TimeInterval) async throws -> [Value] {
        await fulfillment(of: [calls.expectation], timeout: timeout)
        return try calls.values()
    }

    /// Runs `body` `count` times at once and waits for all of them at most `timeout`.
    func concurrently<Value: Sendable>(
        _ count: Int,
        timeout: TimeInterval,
        _ description: String = "the concurrent calls",
        _ body: @escaping @Sendable (Int) async throws -> Value
    ) async throws -> [Value] {
        try await results(of: ConcurrentCalls(description, count: count, body), timeout: timeout)
    }
}
