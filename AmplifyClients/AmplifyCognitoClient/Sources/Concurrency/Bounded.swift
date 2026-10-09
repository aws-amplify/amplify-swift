//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Runs `operation`, but stops waiting for it after `nanoseconds` and throws `timeout` instead.
///
/// Races the operation against a sleep in a throwing task group and cancels the loser. A task group
/// waits for all its children, so `operation` must be abandonable: it must return promptly once
/// cancelled. A `SingleFlight` waiter is, because a cancelled waiter is resumed straight away while
/// the shared work carries on. **Racing blocking work directly would not bound anything.**
///
/// Nanoseconds and `Task.sleep(nanoseconds:)`, because `Duration` and `Clock.sleep(for:)` need iOS 16.
func withBound<T: Sendable>(
    nanoseconds: UInt64,
    timeout: Error,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: nanoseconds)
            return nil
        }
        defer { group.cancelAll() }
        guard let first = try await group.next(), let value = first else {
            throw timeout
        }
        return value
    }
}
