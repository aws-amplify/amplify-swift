//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest
@testable import AmplifyKinesisClient

class SQLiteRecordStorageCacheAccuracyTests: XCTestCase {

    var storage: SQLiteRecordStorage!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test",
            maxRecords: 1_000,
            cacheMaxBytes: 1_024 * 1_024,
            maxRecordSizeBytes: 10 * 1_024 * 1_024,
            maxBytesPerStream: 10 * 1_024 * 1_024,
            maxPartitionKeyLength: 256
        )
    }

    override func tearDown() async throws {
        _ = try? await storage.clearRecords()
        storage = nil
        try await super.tearDown()
    }

    func testCachedSizeMatchesDatabaseAfterAddOperations() async throws {
        // Given
        let record1 = RecordInput(streamName: "stream1", partitionKey: "a", data: Data([1, 2, 3]))
        let record2 = RecordInput(streamName: "stream1", partitionKey: "b", data: Data([4, 5, 6, 7]))

        // When
        try await storage.addRecord(record1)
        try await storage.addRecord(record2)

        // Then — "a"(1) + data(3) + "b"(1) + data(4) = 9
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 9)
    }

    func testCachedSizeMatchesDatabaseAfterDeleteOperations() async throws {
        // Given: Add records
        let record1 = RecordInput(streamName: "stream1", partitionKey: "a", data: Data([1, 2, 3]))
        let record2 = RecordInput(streamName: "stream1", partitionKey: "b", data: Data([4, 5, 6, 7]))
        let record3 = RecordInput(streamName: "stream2", partitionKey: "c", data: Data([8, 9]))

        try await storage.addRecord(record1)
        try await storage.addRecord(record2)
        try await storage.addRecord(record3)

        // Get record IDs for deletion - delete first two by creation order
        let recordsByStreamList = try await storage.getRecordsByStream(afterIdByStream: [:])
        let allRecords = recordsByStreamList.flatMap { $0 }.sorted { $0.createdAt < $1.createdAt }
        let idsToDelete = Array(allRecords.prefix(2)).map { $0.id }

        // When
        try await storage.deleteRecords(ids: idsToDelete)

        // Then — remaining: "c"(1) + data(2) = 3
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 3)
    }

    func testCachedSizeMatchesDatabaseAfterClearOperations() async throws {
        // Given: Add records
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "a", data: Data([1, 2, 3])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "b", data: Data([4, 5])))

        // When
        _ = try await storage.clearRecords()

        // Then
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 0)
    }

    func testCachedSizeRemainsAccurateThroughMixedOperations() async throws {
        // "a"(1) + data(5) = 6
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "a", data: Data([1, 2, 3, 4, 5])))
        // "b"(1) + data(3) = 4
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "b", data: Data([6, 7, 8])))

        var cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 10) // 6 + 4

        // Delete the first record (6 bytes from stream1)
        let recordsList = try await storage.getRecordsByStream(afterIdByStream: [:])
        let records = recordsList.flatMap { $0 }
        let firstRecord = try XCTUnwrap(records.first { $0.streamName == "stream1" })
        try await storage.deleteRecords(ids: [firstRecord.id])

        cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 4)

        // Add another record: "c"(1) + data(2) = 3
        try await storage.addRecord(RecordInput(streamName: "stream3", partitionKey: "c", data: Data([9, 10])))

        cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 7) // 4 + 3
    }

    func testConcurrentProducerConsumerOperationsAreThreadSafe() async throws {
        // Given
        let recordSize = 10
        let producerCount = 4
        let recordsPerProducer = 400
        let consumerCount = 2
        let deletionsPerConsumer = 100

        // Use actor for thread-safe tracking of test data
        // The actual thread-safety test is on the storage actor itself
        actor TestTracker {
            var createdRecords: [String: Set<String>] = [:]
            var deletedRecords: Set<String> = []

            func recordCreated(producer: String, records: Set<String>) {
                createdRecords[producer] = records
            }

            func recordDeleted(keys: [String]) {
                deletedRecords.formUnion(keys)
            }

            func getCounts() -> (created: Int, deleted: Int) {
                let created = createdRecords.values.reduce(0) { $0 + $1.count }
                let deleted = deletedRecords.count
                return (created, deleted)
            }

            func getTrackingData() -> ([String: Set<String>], Set<String>) {
                return (createdRecords, deletedRecords)
            }
        }

        let tracker = TestTracker()

        // Create producers - these will hammer the storage concurrently
        let producers = (0 ..< producerCount).map { producerIndex in
            Task {
                var threadRecords: Set<String> = []

                for recordCounter in 0 ..< recordsPerProducer {
                    let recordKey = "producer\(producerIndex)_record\(recordCounter)"
                    let record = RecordInput(
                        streamName: "stream\(producerIndex)",
                        partitionKey: recordKey,
                        data: Data(repeating: UInt8(producerIndex), count: recordSize)
                    )

                    try? await storage.addRecord(record)
                    threadRecords.insert(recordKey)

                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }

                await tracker.recordCreated(producer: "producer\(producerIndex)", records: threadRecords)
            }
        }

        // Create consumers - these will delete concurrently with producers
        let consumers = (0 ..< consumerCount).map { consumerIndex in
            Task {
                for _ in 0 ..< deletionsPerConsumer {
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

                    if let recordsList = try? await storage.getRecordsByStream(afterIdByStream: [:]),
                       let records = recordsList.first,
                       !records.isEmpty {
                        let recordsToDelete = Array(records.prefix(1))
                        let idsToDelete = recordsToDelete.map { $0.id }
                        let keysToDelete = recordsToDelete.map { $0.partitionKey }

                        try? await storage.deleteRecords(ids: idsToDelete)

                        await tracker.recordDeleted(keys: keysToDelete)
                    }
                }
            }
        }

        // Wait for all tasks to complete
        for producer in producers {
            _ = await producer.result
        }
        for consumer in consumers {
            _ = await consumer.result
        }

        // Verify data integrity
        let (totalCreated, totalDeleted) = await tracker.getCounts()

        let finalRecords = try await storage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
        print("Created \(totalCreated) records, deleted \(totalDeleted) records, found in DB \(finalRecords.count)")

        let finalCacheSize = try await storage.getCurrentCacheSize()
        let expectedCacheSize = finalRecords.reduce(0) { $0 + $1.dataSize }

        XCTAssertEqual(finalCacheSize, Int64(expectedCacheSize))

        // Get tracking data from actor
        let (createdRecords, deletedRecords) = await tracker.getTrackingData()

        let remainingKeys = Set(finalRecords.map { $0.partitionKey })
        let allCreatedKeys = Set(createdRecords.values.flatMap { $0 })

        // Verify each created key is either in DB or was deleted
        for createdKey in allCreatedKeys {
            let isInDb = remainingKeys.contains(createdKey)
            let wasDeleted = deletedRecords.contains(createdKey)

            XCTAssertTrue(isInDb || wasDeleted, "Key \(createdKey) should be in DB or deleted")
            XCTAssertFalse(isInDb && wasDeleted, "Key \(createdKey) cannot be both in DB and deleted")
        }

        // Verify all remaining keys were created
        for remainingKey in remainingKeys {
            XCTAssertTrue(allCreatedKeys.contains(remainingKey), "Remaining key \(remainingKey) should have been created")
        }

        XCTAssertFalse(allCreatedKeys.isEmpty)
        XCTAssertFalse(deletedRecords.isEmpty)
        XCTAssertFalse(remainingKeys.isEmpty)
    }

    func testGetRecordsByStreamRespectsPerStreamByteLimitAcrossMultipleStreams() async throws {
        // Storage with a large cache but a tight 200-byte per-stream limit
        let perStreamStorage = try SQLiteRecordStorage(
            identifier: "test_per_stream",
            maxRecords: 100,
            cacheMaxBytes: 10_000,
            maxRecordSizeBytes: 1_024,
            maxBytesPerStream: 200,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )

        // Each record: "a" (1 byte key) + 50 bytes data = 51 bytes per record
        // 200 / 51 = 3.9 → at most 3 records per stream fit under 200 bytes (3 × 51 = 153)
        for i in 0 ..< 6 {
            try await perStreamStorage.addRecord(
                RecordInput(streamName: "stream-A", partitionKey: "a", data: Data(repeating: UInt8(i), count: 50))
            )
        }
        for i in 0 ..< 6 {
            try await perStreamStorage.addRecord(
                RecordInput(streamName: "stream-B", partitionKey: "b", data: Data(repeating: UInt8(i), count: 50))
            )
        }

        let recordsByStream = try await perStreamStorage.getRecordsByStream(afterIdByStream: [:])
        XCTAssertEqual(recordsByStream.count, 2)

        for records in recordsByStream {
            let streamName = try XCTUnwrap(records.first?.streamName)
            let totalSize = records.reduce(0) { $0 + $1.dataSize }

            // Each stream should return at most 3 records (153 bytes ≤ 200)
            XCTAssertEqual(records.count, 3, "Stream \(streamName) should have 3 records")
            XCTAssertEqual(totalSize, 153, "Stream \(streamName) total size should be 153")

            // Verify all records belong to the same stream
            for record in records {
                XCTAssertEqual(record.streamName, streamName)
            }
        }
    }

    func testGetRecordsByStreamWithEmptyAfterIdByStreamReturnsAllRecords() async throws {
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "key3", data: Data([3])))

        let result = try await storage.getRecordsByStream(afterIdByStream: [:])
        let allRecords = result.flatMap { $0 }

        XCTAssertEqual(allRecords.count, 3)
    }

    func testGetRecordsByStreamExcludesRecordsUpToLastIdPerStream() async throws {
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key3", data: Data([3])))

        let allRecords = try await storage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
        XCTAssertEqual(allRecords.count, 3)

        // Exclude records up to the first record's ID — should return the remaining 2
        let afterId = allRecords[0].id
        let filtered = try await storage.getRecordsByStream(afterIdByStream: ["stream1": afterId]).flatMap { $0 }

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.id > afterId })
    }

    func testGetRecordsByStreamWithAllRecordsExcludedReturnsEmpty() async throws {
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([2])))

        let allRecords = try await storage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
        let maxId = allRecords.map(\.id).max()!

        let result = try await storage.getRecordsByStream(afterIdByStream: ["stream1": maxId])
        XCTAssertEqual(result.count, 0)
    }

    func testGetRecordsByStreamExcludesPerStreamAcrossMultipleStreams() async throws {
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1])))
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([2])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "key3", data: Data([3])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "key4", data: Data([4])))

        let allRecords = try await storage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
        let stream1First = try XCTUnwrap(allRecords.first { $0.streamName == "stream1" })
        let stream2First = try XCTUnwrap(allRecords.first { $0.streamName == "stream2" })

        // Exclude up to the first record in each stream — should return 1 per stream
        let filtered = try await storage.getRecordsByStream(
            afterIdByStream: ["stream1": stream1First.id, "stream2": stream2First.id]
        )
        let remaining = filtered.flatMap { $0 }

        XCTAssertEqual(remaining.count, 2)
        XCTAssertTrue(remaining.allSatisfy { $0.id != stream1First.id })
        XCTAssertTrue(remaining.allSatisfy { $0.id != stream2First.id })
    }

    func testGetRecordsByStreamRespectsBatchLimitWithAfterIdByStream() async throws {
        let batchStorage = try SQLiteRecordStorage(
            identifier: "test_batch_exclude",
            maxRecords: 2,
            cacheMaxBytes: 1_024 * 1_024,
            maxRecordSizeBytes: 10 * 1_024 * 1_024,
            maxBytesPerStream: 10 * 1_024 * 1_024,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )

        // Add 4 records to one stream
        try await batchStorage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1])))
        try await batchStorage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([2])))
        try await batchStorage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key3", data: Data([3])))
        try await batchStorage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key4", data: Data([4])))

        // First batch: 2 records (batch limit)
        let batch1 = try await batchStorage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
        XCTAssertEqual(batch1.count, 2)

        // Second batch: skip past the max ID from batch 1, get next 2
        let maxIdBatch1 = batch1.map(\.id).max()!
        let batch2 = try await batchStorage.getRecordsByStream(afterIdByStream: ["stream1": maxIdBatch1]).flatMap { $0 }
        XCTAssertEqual(batch2.count, 2)
        XCTAssertTrue(batch2.allSatisfy { $0.id > maxIdBatch1 })

        // Third batch: skip past all 4, get nothing
        let maxIdBatch2 = batch2.map(\.id).max()!
        let batch3 = try await batchStorage.getRecordsByStream(afterIdByStream: ["stream1": maxIdBatch2])
        XCTAssertEqual(batch3.count, 0)
    }
}
