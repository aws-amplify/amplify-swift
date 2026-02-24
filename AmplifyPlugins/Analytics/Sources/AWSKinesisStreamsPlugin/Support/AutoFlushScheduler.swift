//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AsyncAlgorithms
import Foundation

/// Schedules automatic flushing of records at a specified interval
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
actor AutoFlushScheduler {
    private let interval: Duration
    private let recordClient: RecordClient
    private var flushTask: Task<Void, Never>?

    init(interval: Duration, recordClient: RecordClient) {
        self.interval = interval
        self.recordClient = recordClient
    }

    /// Starts the automatic flush scheduler
    func start() {
        flushTask?.cancel()

        flushTask = Task { [weak self, interval] in
            for await _ in AsyncTimerSequence.repeating(every: interval) {
                guard let self, !Task.isCancelled else { break }
                do {
                    _ = try await self.recordClient.flush()
                } catch {
                    // logger?.error("Scheduled flush failed: \(error)")
                }
            }
        }
    }

    /// Stops the automatic flush scheduler
    func disable() {
        flushTask?.cancel()
        flushTask = nil
    }

    deinit {
        flushTask?.cancel()
    }
}
