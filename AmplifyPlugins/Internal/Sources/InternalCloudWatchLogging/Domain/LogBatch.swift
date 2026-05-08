//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a batch of log entries to produce/consume.
package protocol LogBatch: Sendable {
    /// Read the log entries for this log batch.
    func readEntries() throws -> [LogEntryRepresentable]

    /// Log batch has completed, complete the batch by removing from file system.
    func complete() throws
}
