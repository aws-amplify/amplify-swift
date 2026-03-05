//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSKinesis
import SQLite
import XCTest
@testable import AmplifyKinesisClient

class RecordClientFlushTests: XCTestCase {

    private var storage: SQLiteRecordStorage!
    private var sender: ConfigurableMockSender!
    private var recordClient: RecordClient!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test_flush",
            maxRecords: 1_000,
            cacheMaxBytes: 1_024 * 1_024,
            maxRecordSizeBytes: 10 * 1_024 * 1_024,
            maxBytesPerStream: 10 * 1_024 * 1_024,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )
        sender = ConfigurableMockSender()
        recordClient = RecordClient(sender: sender, storage: storage, maxRetries: 3)
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
        let allRecordsByStream = try await storage.getRecordsByStream(excludingIds: [])
        let allRecords = allRecordsByStream.flatMap { $0 }
        let record3Id = allRecords[2].id
        try await storage.incrementRetryCount(ids: [record3Id])
        try await storage.incrementRetryCount(ids: [record3Id])
        try await storage.incrementRetryCount(ids: [record3Id]) // Now at max retries (3)

        await sender.setHandler { _, records in
            PutRecordsResponse(
                successfulIds: [records[0].id],
                retryableIds: [records[1].id],
                failedIds: [records[2].id]
            )
        }

        let result = try await recordClient.flush()

        XCTAssertEqual(result.recordsFlushed, 1)
        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertEqual(remainingRecords[0].id, allRecords[1].id)
        XCTAssertEqual(remainingRecords[0].retryCount, 1)
    }

    func testFlushShouldIncrementRetryCountWhenNonSdkErrorOccurs() async throws {
        let streamName = "test-stream"
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key3", data: Data([3])))

        await sender.setError(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

        do {
            _ = try await recordClient.flush()
            XCTFail("Expected flush to throw")
        } catch {
            // Expected — non-SDK errors are critical
        }

        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 3)
        for record in remainingRecords {
            XCTAssertEqual(record.retryCount, 1)
        }
    }

    func testFlushShouldDeleteRecordsAtMaxRetriesWhenNonSdkErrorOccurs() async throws {
        let streamName = "test-stream"
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key3", data: Data([3])))

        let allRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        let record2Id = allRecords[1].id
        let record3Id = allRecords[2].id

        // Increment to maxRetries (3) so they are expired on next failed flush
        try await storage.incrementRetryCount(ids: [record2Id, record3Id])
        try await storage.incrementRetryCount(ids: [record2Id, record3Id])
        try await storage.incrementRetryCount(ids: [record2Id, record3Id])

        await sender.setError(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

        do {
            _ = try await recordClient.flush()
            XCTFail("Expected flush to throw")
        } catch {
            // Expected — non-SDK errors are critical
        }

        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertEqual(remainingRecords[0].id, allRecords[0].id)
        XCTAssertEqual(remainingRecords[0].retryCount, 1)
    }

    func testFlushShouldStopProcessingStreamsWhenNonSdkErrorOccurs() async throws {
        let stream1 = "stream-1"
        let stream2 = "stream-2"
        try await storage.addRecord(RecordInput(streamName: stream1, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: stream2, partitionKey: "key2", data: Data([2])))

        // Non-SDK errors are critical and should throw
        await sender.setHandler { _, _ in
            throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        }

        do {
            _ = try await recordClient.flush()
            XCTFail("Expected flush to throw")
        } catch {
            // Expected
        }

        // The first stream processed should have retry incremented, the second should not be processed
        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 2)
        let retryCountSum = remainingRecords.map(\.retryCount).reduce(0, +)
        XCTAssertEqual(retryCountSum, 1) // Only one stream was processed before throwing
    }

    func testFlushShouldSucceedWhenSdkErrorOccurs() async throws {
        let streamName = "test-stream"
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key2", data: Data([2])))

        await sender.setError(ResourceNotFoundException(message: "Stream not found"))

        let result = try await recordClient.flush()

        XCTAssertEqual(result.recordsFlushed, 0)
        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 2)
        for record in remainingRecords {
            XCTAssertEqual(record.retryCount, 1)
        }
    }

    func testFlushShouldContinueProcessingStreamsWhenSdkErrorOccurs() async throws {
        let stream1 = "stream-1"
        let stream2 = "stream-2"
        try await storage.addRecord(RecordInput(streamName: stream1, partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: stream2, partitionKey: "key2", data: Data([2])))

        let initialRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        let stream2RecordId = try XCTUnwrap(initialRecords.first { $0.streamName == stream2 }?.id)

        await sender.setHandler { streamName, _ in
            if streamName == stream1 {
                throw ResourceNotFoundException(message: "Stream not found")
            }
            return PutRecordsResponse(
                successfulIds: [stream2RecordId],
                retryableIds: [],
                failedIds: []
            )
        }

        let result = try await recordClient.flush()

        XCTAssertEqual(result.recordsFlushed, 1)
        let remainingRecords = try await storage.getRecordsByStream(excludingIds: []).flatMap { $0 }
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertTrue(remainingRecords.allSatisfy { $0.streamName != stream2 })
        XCTAssertEqual(remainingRecords.first { $0.streamName == stream1 }?.retryCount, 1)
    }
}

// MARK: - Configurable Mock Sender

final class ConfigurableMockSender: RecordSender, @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable (String, [Record]) throws -> PutRecordsResponse)?
    private var errorToThrow: Error?

    func setHandler(_ handler: @escaping @Sendable (String, [Record]) throws -> PutRecordsResponse) async {
        lock.lock()
        self.handler = handler
        errorToThrow = nil
        lock.unlock()
    }

    func setError(_ error: Error) async {
        lock.lock()
        errorToThrow = error
        handler = nil
        lock.unlock()
    }

    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        lock.lock()
        let currentHandler = handler
        let currentError = errorToThrow
        lock.unlock()

        if let error = currentError {
            throw error
        }
        guard let handler = currentHandler else {
            return PutRecordsResponse(successfulIds: [], retryableIds: [], failedIds: [])
        }
        return try handler(streamName, records)
    }
}
