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

    public func sync(block: @Sendable @escaping () async throws -> Success) rethrows {
        previousTask = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
    }

    public nonisolated func async(block: @Sendable @escaping () async throws -> Success) rethrows {
        Task {
            try await sync(block: block)
        }
    }
}
