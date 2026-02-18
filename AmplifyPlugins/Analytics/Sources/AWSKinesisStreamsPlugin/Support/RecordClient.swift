//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Generic RecordClient that coordinates storage and sending of records
actor RecordClient {
    private let sender: RecordSender
    private let storage: RecordStorage
    private let logger: Logger?
    private var isFlushing = false

    init(
        sender: RecordSender,
        storage: RecordStorage,
        logger: Logger?
    ) {
        self.sender = sender
        self.storage = storage
        self.logger = logger
    }

    /// Records data to local storage
    func record(_ input: RecordInput) async throws {
        try await storage.addRecord(input)
    }

    /// Flushes all locally stored records
    func flush() async throws -> FlushData {
        guard !isFlushing else {
            logger?.debug("Flush already in progress, skipping")
            return FlushData(recordsFlushed: 0, flushInProgress: true)
        }

        isFlushing = true
        defer { isFlushing = false }

        var totalFlushed = 0
        let recordsByStreamList = try await storage.getRecordsByStream()

        for records in recordsByStreamList {
            guard !records.isEmpty else { continue }
            let streamName = records[0].streamName

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
            } catch {
                logger?.error("Failed to submit batch for stream \(streamName): \(error)")
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
