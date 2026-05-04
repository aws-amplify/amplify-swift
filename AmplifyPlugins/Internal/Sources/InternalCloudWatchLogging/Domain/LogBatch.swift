//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a batch of log that has a series of log entries to produce/consume
package protocol LogBatch {
    /// Log Batches have completed, complete the batch by removing from file system
    func complete() throws
}
