//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A helper for executing asynchronous work serially.
public actor TaskQueue<Success, Failure> where Failure: Error {
    private var previousTask: Task<Success, Failure>?
    
    public init() {}
}

public extension TaskQueue where Failure == any Error {
    /// Serializes asynchronous requests made from an async context
    ///
    /// Given an invocation like
    /// ```swift
    /// let tq = TaskQueue<Int, Error>()
    /// let v1 = try await tq.sync { try await doAsync1() }
    /// let v2 = try await tq.sync { try await doAsync2() }
    /// let v3 = try await tq.sync { try await doAsync3() }
    /// ```
    /// TaskQueue serializes this work so that `doAsync1` is performed before `doAsync2`,
    /// which is performed before `doAsync3`.
    func sync(block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let currentTask: Task<Success, Failure> = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        previousTask = currentTask
        return try await currentTask.value
    }
    
    nonisolated func async(block: @Sendable @escaping () async throws -> Success) rethrows {
        Task {
            try await sync(block: block)
        }
    }
}

public extension TaskQueue where Failure == Never {
    /// Serializes asynchronous requests made from an async context
    ///
    /// Given an invocation like
    /// ```swift
    /// let tq = TaskQueue<Int, Never>()
    /// let v1 = await tq.sync { await doAsync1() }
    /// let v2 = await tq.sync { await doAsync2() }
    /// let v3 = await tq.sync { await doAsync3() }
    /// ```
    /// TaskQueue serializes this work so that `doAsync1` is performed before `doAsync2`,
    /// which is performed before `doAsync3`.
    func sync(block: @Sendable @escaping () async -> Success) async -> Success {
        let currentTask: Task<Success, Failure> = Task { [previousTask] in
            _ = await previousTask?.result
            return await block()
        }
        previousTask = currentTask
        return await currentTask.value
    }
    
    nonisolated func async(block: @Sendable @escaping () async -> Success) {
        Task {
            await sync(block: block)
        }
    }
}
