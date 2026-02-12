//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for sending records to a remote service
protocol RecordSender: Sendable {
    /// Sends a batch of records for a specific stream
    /// - Parameters:
    ///   - streamName: The name of the stream
    ///   - records: The records to send
    /// - Returns: Response indicating success/failure/retry for each record
    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse
}
