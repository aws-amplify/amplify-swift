//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSKinesisStreamsPlugin

class AutoFlushSchedulerTests: XCTestCase {
    
    var mockStorage: MockRecordStorage!
    var mockSender: MockRecordSender!
    var recordClient: RecordClient!
    var scheduler: AutoFlushScheduler!
    
    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockRecordStorage()
        mockSender = MockRecordSender()
        recordClient = RecordClient(
            sender: mockSender,
            storage: mockStorage,
            logger: nil
        )
    }
    
    override func tearDown() async throws {
        await scheduler?.disable()
        scheduler = nil
        recordClient = nil
        mockSender = nil
        mockStorage = nil
        try await super.tearDown()
    }
    
    func testStartShouldBeginPeriodicFlushing() async throws {
        // Given
        let interval: Duration = .seconds(1)
        scheduler = AutoFlushScheduler(interval: interval, recordClient: recordClient)
        
        // When
        await scheduler.start()
        try await Task.sleep(for: .seconds(2.5))
        await scheduler.disable()
        
        // Then - should have called getRecordsByStream at least 2 times (flush calls it)
        let callCount = await mockStorage.getRecordsByStreamCallCount
        XCTAssertEqual(callCount, 2,
                      "Should flush exactly 2 times in 2.5 seconds with 1 second interval")
    }
    
    func testDisableShouldStopPeriodicFlushing() async throws {
        // Given
        let interval: Duration = .seconds(1)
        scheduler = AutoFlushScheduler(interval: interval, recordClient: recordClient)
        
        // When
        await scheduler.start()
        try await Task.sleep(for: .seconds(1.5))
        await scheduler.disable()
        
        let countAfterDisable = await mockStorage.getRecordsByStreamCallCount
        try await Task.sleep(for: .seconds(2))
        
        // Then - should have flushed exactly 1 time, no more after disable
        XCTAssertEqual(countAfterDisable, 1,
                      "Should flush exactly 1 time in 1.5 seconds")
        let finalCount = await mockStorage.getRecordsByStreamCallCount
        XCTAssertEqual(finalCount, 1,
                      "Should not flush after disable")
    }
    
    func testStartShouldCancelPreviousJobAndRestart() async throws {
        // Given
        let interval: Duration = .seconds(1)
        scheduler = AutoFlushScheduler(interval: interval, recordClient: recordClient)
        
        // When
        await scheduler.start()
        try await Task.sleep(for: .milliseconds(500))
        await scheduler.start() // Restart - should cancel previous job
        try await Task.sleep(for: .seconds(1.5))
        await scheduler.disable()
        
        // Then - should flush exactly 1 time (from the restarted scheduler)
        let callCount = await mockStorage.getRecordsByStreamCallCount
        XCTAssertEqual(callCount, 1,
                      "Should flush exactly 1 time after restart")
    }
}

// MARK: - Mock Record Client

/// Mock storage that tracks operations
actor MockRecordStorage: RecordStorage {
    var addRecordCallCount = 0
    var getRecordsByStreamCallCount = 0
    var deleteRecordsCallCount = 0
    var clearRecordsCallCount = 0
    
    func addRecord(_ input: RecordInput) throws {
        addRecordCallCount += 1
    }
    
    func getRecordsByStream() throws -> [[Record]] {
        getRecordsByStreamCallCount += 1
        return []
    }
    
    func deleteRecords(ids: [Int64]) throws {
        deleteRecordsCallCount += 1
    }
    
    func incrementRetryCount(ids: [Int64]) throws {
    }
    
    func clearRecords() throws -> Int {
        clearRecordsCallCount += 1
        return 0
    }
    
    func getCurrentCacheSize() throws -> Int64 {
        return 0
    }
}

class MockRecordSender: RecordSender {
    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        return PutRecordsResponse(successfulIds: [], retryableIds: [], failedIds: [])
    }
}

/// Wrapper to track flush calls on RecordClient
class FlushTracker {
    var flushCallCount = 0
    let client: RecordClient
    
    init(storage: MockRecordStorage, sender: MockRecordSender) {
        self.client = RecordClient(
            sender: sender,
            storage: storage,
            logger: nil
        )
    }
    
    func trackFlush() async throws -> FlushData {
        flushCallCount += 1
        return try await client.flush()
    }
}
