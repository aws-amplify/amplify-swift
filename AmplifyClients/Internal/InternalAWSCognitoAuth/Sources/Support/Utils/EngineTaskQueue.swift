//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of `Amplify.TaskQueue` (`Amplify/Core/Support/TaskQueue.swift`): executes asynchronous
/// work serially. `init`, `deinit` and `sync(block:)` are Amplify's bodies. Amplify's `async(block:)` is not
/// copied: the engine never calls it, and it logs through `Amplify.Logging`.
///
/// The credential store's operation client serializes its CRUD through it, so a change in ordering or in
/// error propagation would change what the store reads and writes. A differential test runs the same
/// workloads through both queues.
///
/// - Note: `Sendable` because the only stored property is a `let` `AsyncStream.Continuation`,
///   which is itself thread-safe.
package final class EngineTaskQueue<Success>: Sendable {
    typealias Block = @Sendable () async -> Void
    private let streamContinuation: AsyncStream<Block>.Continuation

    package init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Block.self)
        self.streamContinuation = continuation

        Task {
            for await block in stream {
                _ = await block()
            }
        }
    }

    deinit {
        streamContinuation.finish()
    }

    /// Serializes asynchronous requests made from an async context
    ///
    /// Given an invocation like
    /// ```swift
    /// let tq = EngineTaskQueue<Int>()
    /// let v1 = try await tq.sync { try await doAsync1() }
    /// let v2 = try await tq.sync { try await doAsync2() }
    /// let v3 = try await tq.sync { try await doAsync3() }
    /// ```
    /// EngineTaskQueue serializes this work so that `doAsync1` is performed before `doAsync2`,
    /// which is performed before `doAsync3`.
    package func sync(block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await withCheckedThrowingContinuation { continuation in
            streamContinuation.yield {
                do {
                    let value = try await block()
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
