//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Dispatch

/// Runs blocking work — a `SecItem*` call — on `queue`, off Swift's cooperative thread pool. The caller
/// suspends until it returns.
///
/// The one bridge every blocking keychain call in the client goes through (`SessionRecordIO`,
/// `DeviceRecordIO`, `LazyUserPoolAnalytics.prepare()`). See `SessionRecordIO` for why the client makes
/// this exception to the rule against new `DispatchQueue`s: a stuck keychain call must pin a Dispatch
/// thread, never one of the pool's few cooperative threads.
///
/// **Cancellation is ignored.** A blocking `SecItem*` call cannot be interrupted, so a cancelled caller
/// still waits for `work` to return, and gets its result. For the same reason it is not abandonable, so
/// racing it directly in `withBound` bounds nothing (see `withBound`).
func runBlocking<T: Sendable>(on queue: DispatchQueue, _ work: @escaping @Sendable () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        queue.async {
            continuation.resume(with: Result { try work() })
        }
    }
}
