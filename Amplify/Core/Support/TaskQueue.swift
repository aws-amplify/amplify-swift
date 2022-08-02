//
//  Created by Ameter, Chris on 5/23/22.
//
#if swift(>=5.5.2)

import Foundation

@available(iOS 13.0, *)
actor TaskQueue<Success> {
    
    private var previousTask: Task<Success, Error>?

    func sync(block: @Sendable @escaping () async throws -> Success) async throws {
        previousTask = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        _ = try await previousTask?.value
    }

    nonisolated func async(block: @Sendable @escaping () async throws -> Success) rethrows {
        Task {
            try await sync(block: block)
        }
    }
}

#endif
