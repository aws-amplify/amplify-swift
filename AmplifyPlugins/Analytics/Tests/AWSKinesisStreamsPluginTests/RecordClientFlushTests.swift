//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyKinesisClient
import SQLite

class RecordClientFlushTests: XCTestCase {

    private var storage: SQLiteRecordStorage!
    private var sender: ConfigurableMockSender!
    private var recordClient: RecordClient!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test_flush",
            maxRecords: 1000,
            maxBytes: 1024 * 1024,
            connection: Connection(.inMemory)
        )
        sender = ConfigurableMockSender()
        recordClient = RecordClient(sender: sender, storage: storage)
    }

    override func tearDown() async throws {
        recordClient = nil
        sender = nil
        storage = nil
        try await super.tearDown()
    }

    func testFlushShouldHandleMixedRecordStatesCorrectly() async throws {
        // Given: Records with different states
        let streamName = "test-stream"

        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key3", data: Data([3])))

        // Get all records and set retry count for record 3 to max (3)
        let allRecordsByStream = try await storage.getRecordsByStream()
        let allRecords = allRecordsByStream.flatMap { $0 }
        let record3Id = allRecords[2].id
        try await storage.incrementRetryCount(ids: [record3Id])
        try await storage.incrementRetryCount(ids: [record3Id])
        try await storage.incrementRetryCount(ids: [record3Id]) // Now at max retries (3)

        // Configure mock sender to return mixed results
        await sender.setResponse { records in
            PutRecordsResponse(
                successfulIds: [records[0].id],
                retryableIds: [records[1].id],
                failedIds: [records[2].id]
            )
        }

        // When
        let result = try await recordClient.flush()

        // Then
        XCTAssertEqual(result.recordsFlushed, 1)

        // Verify final state: only the retryable record should remain
        let remainingRecordsByStream = try await storage.getRecordsByStream()
        let remainingRecords = remainingRecordsByStream.flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertEqual(remainingRecords[0].id, allRecords[1].id)
        XCTAssertEqual(remainingRecords[0].retryCount, 1)
    }
}

// MARK: - Configurable Mock Sender

final class ConfigurableMockSender: RecordSender {
    private let responseHolder = ResponseHolder()

    func setResponse(_ handler: @escaping @Sendable ([Record]) -> PutRecordsResponse) async {
        responseHolder.set(handler)
    }

    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        guard let handler = responseHolder.get() else {
            return PutRecordsResponse(successfulIds: [], retryableIds: [], failedIds: [])
        }
        return handler(records)
    }
}

private final class ResponseHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (([Record]) -> PutRecordsResponse)?

    func set(_ handler: @escaping @Sendable ([Record]) -> PutRecordsResponse) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func get() -> (([Record]) -> PutRecordsResponse)? {
        lock.lock()
        defer { lock.unlock() }
        return handler
    }
}
