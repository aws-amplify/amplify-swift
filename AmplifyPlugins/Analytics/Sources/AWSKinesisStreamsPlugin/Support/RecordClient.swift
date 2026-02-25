//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Generic RecordClient that coordinates storage and sending of records
actor RecordClient {
    private let sender: RecordSender
    private let storage: RecordStorage
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: RecordClient.self)
    private var isFlushing = false

    init(
        sender: RecordSender,
        storage: RecordStorage
    ) {
        self.sender = sender
        self.storage = storage
    }

    /// Records data to local storage
    func record(_ input: RecordInput) async throws -> RecordData {
        try await storage.addRecord(input)
        return RecordData()
    }

    /// Flushes all locally stored records
    func flush() async throws -> FlushData {
        guard !isFlushing else {
            logger.debug("Flush already in progress, skipping")
            return FlushData(recordsFlushed: 0, flushInProgress: true)
        }

        isFlushing = true
        defer { isFlushing = false }

        var totalFlushed = 0
        let recordsByStreamList = try await storage.getRecordsByStream()
        logger.debug("Retrieved \(recordsByStreamList.count) stream(s) with records to flush")

        for records in recordsByStreamList {
            guard !records.isEmpty else { continue }
            let streamName = records[0].streamName
            let recordCount = records.count
            logger.verbose("Flushing \(recordCount) records to stream: \(streamName)")

            do {
                let response = try await sender.putRecords(streamName: streamName, records: records)

                // Track successfully flushed records
                totalFlushed += response.successfulIds.count

                // Execute storage operations in parallel
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await self.storage.deleteRecords(ids: response.successfulIds) }
                    group.addTask { try await self.storage.incrementRetryCount(ids: response.retryableIds) }
                    group.addTask { try await self.storage.deleteRecords(ids: response.failedIds) }
                    try await group.waitForAll()
                }

                logger.verbose(
                    "Stream \(streamName): \(response.successfulIds.count) succeeded, " +
                    "\(response.retryableIds.count) retryable, \(response.failedIds.count) failed"
                )
            } catch {
                logger.error("Failed to submit batch for stream \(streamName)", error)
                throw error
            }
        }

        return FlushData(recordsFlushed: totalFlushed)
    }

    /// Clears all cached records
    func clearCache() async throws -> ClearCacheData {
        let count = try await storage.clearRecords()
        return ClearCacheData(recordsCleared: count)
    }
}
