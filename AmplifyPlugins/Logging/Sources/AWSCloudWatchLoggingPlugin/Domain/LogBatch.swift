//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Tag: LogBatch
protocol LogBatch {

    /// Main payload of the receiver.
    ///
    /// - Tag: LogBatch.readEntries
    func readEntries() throws -> [LogEntry]

    /// Ensures the data associated with the receiver can be cleared or deleted, if the given list of
    /// unprecessed entries is empty. If a non-empty list is given, the receiver ensures these are handled
    /// with an appropriate retry-backoff mechanism.
    ///
    /// - Tag: LogBatch.complete
    func complete(with unprocessed:[LogEntry])
}
