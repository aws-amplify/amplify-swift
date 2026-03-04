//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest
@testable import AmplifyKinesisClient

class RecordClientConcurrentFlushTests: XCTestCase {

    private var storage: SQLiteRecordStorage!
    private var sender: SlowMockSender!
    private var recordClient: RecordClient!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test_concurrent",
            maxRecords: 1_000,
            cacheMaxBytes: 1_024 * 1_024,
            maxRecordSizeBytes: 10 * 1_024 * 1_024,
            maxBytesPerStream: 10 * 1_024 * 1_024,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )
        sender = SlowMockSender()
        recordClient = RecordClient(sender: sender, storage: storage, maxRetries: 3)
    }

    override func tearDown() async throws {
        recordClient = nil
        sender = nil
        storage = nil
        try await super.tearDown()
    }

    func testConcurrentFlushShouldReturnFlushInProgressForSecondCaller() async throws {
        // Given: Records in storage
        for i in 0 ..< 5 {
            try await storage.addRecord(
                RecordInput(streamName: "test-stream", partitionKey: "key\(i)", data: Data([UInt8(i)]))
            )
        }

        let allRecords = try await storage.getRecordsByStream().flatMap { $0 }

        // Make the sender slow so the first flush holds the lock
        await sender.setDelay(nanoseconds: 500_000_000) // 500ms
        await sender.setResponse(
            PutRecordsResponse(
                successfulIds: allRecords.map(\.id),
                retryableIds: [],
                failedIds: []
            )
        )

        // When: Two concurrent flushes
        async let flush1 = recordClient.flush()
        // Small delay to ensure flush1 acquires the lock first
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        async let flush2 = recordClient.flush()

        let result1 = try await flush1
        let result2 = try await flush2

        // Then: One should have done work, the other should report flushInProgress
        let results = [result1, result2]
        let anyFlushed = results.contains { $0.recordsFlushed > 0 }
        let anyInProgress = results.contains { $0.flushInProgress }

        XCTAssertTrue(anyFlushed, "At least one flush should have done work")
        XCTAssertTrue(anyInProgress, "Second flush should report flushInProgress")
    }
}

// MARK: - Slow Mock Sender

/// A mock sender that introduces a configurable delay to simulate slow network calls.
private actor SlowMockSender: RecordSender {
    private var delayNanoseconds: UInt64 = 0
    private var response = PutRecordsResponse(successfulIds: [], retryableIds: [], failedIds: [])

    func setDelay(nanoseconds: UInt64) {
        delayNanoseconds = nanoseconds
    }

    func setResponse(_ response: PutRecordsResponse) {
        self.response = response
    }

    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return response
    }
}
