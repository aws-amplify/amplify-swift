//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Schedules automatic flushing of records at a specified interval
actor AutoFlushScheduler {
    private let interval: TimeInterval
    private let recordClient: RecordClient
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AutoFlushScheduler.self)
    private var flushTask: Task<Void, Never>?

    init(interval: TimeInterval, recordClient: RecordClient) {
        self.interval = interval
        self.recordClient = recordClient
    }

    /// Starts the automatic flush scheduler
    func start() {
        flushTask?.cancel()

        flushTask = Task { [weak self, interval] in
            let nanoseconds = UInt64(interval * 1_000_000_000)
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    break // Task was cancelled
                }
                guard let self, !Task.isCancelled else { break }
                do {
                    let data = try await self.recordClient.flush()
                    self.logger.debug("Auto-flush completed: \(data.recordsFlushed) records flushed")
                } catch {
                    // Will retry on next cycle
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
