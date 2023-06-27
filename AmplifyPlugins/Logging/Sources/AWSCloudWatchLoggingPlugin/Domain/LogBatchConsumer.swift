//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a general consumer for contents of a
/// [LogFile](x-source-tag://LogFile)
///
protocol LogBatchConsumer {
    
    /// Processes the given [LogBatch](x-source-tag://LogBatch) and ensures to call
    /// [LogBatch.complete](x-source-tag://LogBatch.complete) on the given `batch` when
    /// done.
    ///
    func consume(batch: LogBatch) async throws
}
