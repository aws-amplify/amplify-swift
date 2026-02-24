//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Result of flushing records
public struct FlushData: Sendable {
    /// The number of records successfully flushed to the remote service.
    public let recordsFlushed: Int

    /// `true` if this flush was skipped because another flush is already in progress.
    /// When `true`, `recordsFlushed` will always be `0`. The skipped records will be
    /// picked up by the next scheduled flush cycle.
    public let flushInProgress: Bool

    public init(recordsFlushed: Int, flushInProgress: Bool = false) {
        self.recordsFlushed = recordsFlushed
        self.flushInProgress = flushInProgress
    }
}

/// Result of clearing cache
public struct ClearCacheData: Sendable {
    public let recordsCleared: Int
}
