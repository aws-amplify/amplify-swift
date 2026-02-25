//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AsyncAlgorithms

/// Schedules automatic flushing of records at a specified interval
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
actor AutoFlushScheduler {
    private let interval: Duration
    private let recordClient: RecordClient
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AutoFlushScheduler.self)
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
                    let data = try await self.recordClient.flush()
                    self.logger.debug("Auto-flush completed: \(data.recordsFlushed) records flushed")
                } catch {
                    // Expected failures (network, throttling, etc.) - will retry on next cycle
                    self.logger.warn("Auto-flush failed", error)
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
