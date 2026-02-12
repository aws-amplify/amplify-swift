//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSKinesisStreamsPlugin

class SQLiteRecordStorageCacheAccuracyTests: XCTestCase {
    
    var storage: SQLiteRecordStorage!
    
    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(identifier: "test", maxRecords: 1000, maxBytes: 1024 * 1024)
    }
    
    override func tearDown() async throws {
        _ = try? await storage.clearRecords()
        storage = nil
        try await super.tearDown()
    }
    
    func testCachedSizeMatchesDatabaseAfterAddOperations() async throws {
        // Given
        let record1 = RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1, 2, 3]))
        let record2 = RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([4, 5, 6, 7]))
        
        // When
        try await storage.addRecord(record1)
        try await storage.addRecord(record2)
        
        // Then
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 7)
    }
    
    func testCachedSizeMatchesDatabaseAfterDeleteOperations() async throws {
        // Given: Add records
        let record1 = RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1, 2, 3]))
        let record2 = RecordInput(streamName: "stream1", partitionKey: "key2", data: Data([4, 5, 6, 7]))
        let record3 = RecordInput(streamName: "stream2", partitionKey: "key3", data: Data([8, 9]))
        
        try await storage.addRecord(record1)
        try await storage.addRecord(record2)
        try await storage.addRecord(record3)
        
        // Get record IDs for deletion - delete first two by creation order
        let recordsByStreamList = try await storage.getRecordsByStream()
        let allRecords = recordsByStreamList.flatMap { $0 }.sorted { $0.createdAt < $1.createdAt }
        let idsToDelete = Array(allRecords.prefix(2)).map { $0.id }  // Select first 2 records
        
        // When
        try await storage.deleteRecords(ids: idsToDelete)
        
        // Then
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 2)
    }
    
    func testCachedSizeMatchesDatabaseAfterClearOperations() async throws {
        // Given: Add records
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1, 2, 3])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "key2", data: Data([4, 5])))
        
        // When
        _ = try await storage.clearRecords()
        
        // Then
        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 0)
    }
    
    func testCachedSizeRemainsAccurateThroughMixedOperations() async throws {
        // Given: Complex sequence of operations
        try await storage.addRecord(RecordInput(streamName: "stream1", partitionKey: "key1", data: Data([1, 2, 3, 4, 5])))
        try await storage.addRecord(RecordInput(streamName: "stream2", partitionKey: "key2", data: Data([6, 7, 8])))
        
        var cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 8)
        
        // Delete the first record (5 bytes from stream1)
        let recordsList = try await storage.getRecordsByStream()
        let records = recordsList.flatMap { $0 }
        let firstRecord = records.first { $0.streamName == "stream1" }!
        try await storage.deleteRecords(ids: [firstRecord.id])
        
        cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 3)
        
        // Add another record
        try await storage.addRecord(RecordInput(streamName: "stream3", partitionKey: "key3", data: Data([9, 10])))
        
        cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 5)
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
        let producers = (0..<producerCount).map { producerIndex in
            Task {
                var threadRecords: Set<String> = []
                
                for recordCounter in 0..<recordsPerProducer {
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
        let consumers = (0..<consumerCount).map { consumerIndex in
            Task {
                for _ in 0..<deletionsPerConsumer {
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                    
                    if let recordsList = try? await storage.getRecordsByStream(),
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
        
        let finalRecords = try await storage.getRecordsByStream().flatMap { $0 }
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
}
