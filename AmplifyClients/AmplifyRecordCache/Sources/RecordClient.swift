//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSClientRuntime
import ClientRuntime
import Foundation

/// Generic RecordClient that coordinates storage and sending of records
public actor RecordClient {
    private let sender: RecordSender
    private let storage: RecordStorage
    private let maxRetries: Int
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: RecordClient.self)
    private var isFlushing = false

    public init(
        sender: RecordSender,
        storage: RecordStorage,
        maxRetries: Int = 3
    ) {
        self.sender = sender
        self.storage = storage
        self.maxRetries = maxRetries
    }

    /// Records data to local storage
    public func record(_ input: RecordInput) async throws -> RecordData {
        try await storage.addRecord(input)
        return RecordData()
    }

    /// Flushes all locally stored records
    public func flush() async throws -> FlushData {
        guard !isFlushing else {
            logger.debug("Flush already in progress, skipping")
            return FlushData(recordsFlushed: 0, flushInProgress: true)
        }

        isFlushing = true
        defer { isFlushing = false }

        var totalFlushed = 0
        var lastIdByStream: [String: Int64] = [:]

        var recordsByStreamList: [[Record]] = try await storage.getRecordsByStream(afterIdByStream: lastIdByStream)
        while !recordsByStreamList.isEmpty {

            logger.debug("Retrieved \(recordsByStreamList.count) stream(s) with records to flush")

            for records in recordsByStreamList {
                guard !records.isEmpty else { continue }
                let streamName = records[0].streamName
                let recordCount = records.count
                logger.verbose("Flushing \(recordCount) records to stream: \(streamName)")

                // Track the last record ID per stream so subsequent batches start after it
                let maxId = records.map(\.id).max() ?? 0
                lastIdByStream[streamName] = maxId

                do {
                    let response = try await sender.putRecords(streamName: streamName, records: records)

                    totalFlushed += response.successfulIds.count

                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask { try await self.storage.deleteRecords(ids: response.successfulIds) }
                        group.addTask { try await self.storage.incrementRetryCount(ids: response.retryableIds) }
                        group.addTask { try await self.storage.deleteRecords(ids: response.failedIds) }
                        try await group.waitForAll()
                    }

                    logger.verbose(
                        "Stream \(streamName): \(response.successfulIds.count) succeeded, "
                            + "\(response.retryableIds.count) retryable, \(response.failedIds.count) failed"
                    )
                } catch {
                    // Increment retry count for retryable records and delete those at the limit
                    await handleFailedRequest(records)

                    // SDK errors are logged but not thrown — one stream shouldn't block others
                    let isSdkError = error is ModeledError || error is AWSServiceError
                    if isSdkError {
                        logger.warn(
                            "SDK error flushing stream \(streamName): \(error.localizedDescription)"
                        )
                    } else {
                        // Network errors, storage errors, and unexpected errors — throw to caller
                        logger.warn(
                            "Error flushing stream \(streamName): \(error.localizedDescription)"
                        )
                        throw error
                    }
                }
            }
            recordsByStreamList = try await storage.getRecordsByStream(afterIdByStream: lastIdByStream)
        }

        return FlushData(recordsFlushed: totalFlushed)
    }

    private func handleFailedRequest(_ records: [Record]) async {
        let retryable = records.filter { $0.retryCount < maxRetries }
        let expired = records.filter { $0.retryCount >= maxRetries }

        do {
            try await storage.incrementRetryCount(ids: retryable.map(\.id))
            try await storage.deleteRecords(ids: expired.map(\.id))

            if !expired.isEmpty {
                let streamName = records[0].streamName
                logger.warn(
                    "Deleted \(expired.count) records from stream \(streamName) "
                        + "that exceeded retry limit of \(maxRetries) after failed retries"
                )
            }
        } catch {
            logger.error("Failed to update records for failed request: \(error.localizedDescription)")
        }
    }

    /// Clears all cached records
    public func clearCache() async throws -> ClearCacheData {
        let count = try await storage.clearRecords()
        return ClearCacheData(recordsCleared: count)
    }
}
