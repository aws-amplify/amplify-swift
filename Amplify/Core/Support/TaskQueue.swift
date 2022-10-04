//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public actor TaskQueue<Success> {
    private var previousTask: Task<Success, Error>?
    
    public init() {}

    public func sync(block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let currentTask: Task<Success, Error> = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        previousTask = currentTask
        return try await currentTask.value
    }

    public nonisolated func async(block: @Sendable @escaping () async throws -> Success) rethrows {
        Task {
            try await sync(block: block)
        }
    }
}
