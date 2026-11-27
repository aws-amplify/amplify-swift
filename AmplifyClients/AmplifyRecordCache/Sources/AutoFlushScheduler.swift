//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// Schedules automatic flushing of records at a specified interval
package actor AutoFlushScheduler {
    private let interval: TimeInterval
    private let recordClient: RecordClient
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AutoFlushScheduler.self)
    private var flushTask: Task<Void, Never>?

    package init(interval: TimeInterval, recordClient: RecordClient) {
        self.interval = interval
        self.recordClient = recordClient
    }

    /// The longest the scheduler waits between flushes while credentials keep failing, unless `interval` is
    /// longer.
    package static let maximumCredentialsBackoff: TimeInterval = 15 * 60

    /// How long to wait before the next flush: `interval`, doubled for each flush in a row that failed for
    /// credentials and kept its records (`RecordClient.credentialsFailureStreak`), up to
    /// `maximumCredentialsBackoff` (or `interval`, if that is longer). With no such failure it is exactly
    /// `interval`.
    package static func delay(interval: TimeInterval, credentialsFailureStreak streak: Int) -> TimeInterval {
        guard streak > 0 else {
            return interval
        }
        // 2^20 intervals is past any cap: the clamp keeps the multiplication finite.
        let backedOff = interval * pow(2, Double(min(streak, 20)))
        return min(backedOff, max(interval, maximumCredentialsBackoff))
    }

    /// Starts the automatic flush scheduler
    ///
    /// Synchronous on the actor, so a second `start()` always cancels the first's task: the streak is reset from
    /// inside the new task instead of awaited here.
    package func start() {
        flushTask?.cancel()

        flushTask = Task { [weak self, interval, recordClient] in
            await recordClient.resetCredentialsFailureStreak()
            while !Task.isCancelled {
                // While the credentials provider keeps failing and the records are kept for it (a session waiting
                // for its user to sign in again, say), flushing every tick only repeats the failure: back off
                // until a flush gets through.
                let streak = await recordClient.credentialsFailureStreak
                // The type by name: older Swift 6 compilers reject some uses of `Self` inside a `Task` closure.
                let delay = AutoFlushScheduler.delay(interval: interval, credentialsFailureStreak: streak)
                let nanoseconds = UInt64(delay * 1_000_000_000)
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    break // Task was cancelled
                }
                guard let self, !Task.isCancelled else { break }
                do {
                    let data = try await recordClient.flush()
                    logger.debug("Auto-flush completed: \(data.recordsFlushed) records flushed")
                } catch RecordCacheError.credentials(_, _, let cause) where (cause as? CredentialsError)?.disposition == .failLoudly {
                    // A misconfiguration, not a user state: no retry will fix it, so it is not a warning.
                    logger.error("Auto-flush failed: the credentials provider cannot vend credentials", cause)
                } catch {
                    // Will retry on next cycle
                    logger.warn("Auto-flush failed", error)
                }
            }
        }
    }

    /// Stops the automatic flush scheduler
    package func disable() {
        flushTask?.cancel()
        flushTask = nil
    }

    deinit {
        flushTask?.cancel()
    }
}
