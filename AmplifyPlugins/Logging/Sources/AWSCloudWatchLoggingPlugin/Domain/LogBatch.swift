//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Tag: LogBatch
protocol LogBatch {

    /// Read the log entries for this log batch
    func readEntries() throws -> [LogEntry]

    /// Log Batches have completed, complete the batch by removing from file system
    func complete() throws
}
