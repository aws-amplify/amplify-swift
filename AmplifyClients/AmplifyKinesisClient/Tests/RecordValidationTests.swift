//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
@testable import AmplifyKinesisClient

/// Unit tests for PutRecords record-level validation.
///
/// Uses a small maxRecordSizeBytes (1000 bytes) to keep allocations tiny while
/// exercising the same boundary logic that applies to the real 10 MiB limit.
///
/// Per the Kinesis PutRecords API spec:
/// - Each record's total size (partition key + data blob) must not exceed 10 MiB
/// - Partition key: 1–256 Unicode characters
/// - dataSize should account for both partition key and data blob
///
/// See: https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsRequestEntry.html
class RecordValidationTests: XCTestCase {

    private let maxRecordSize: Int64 = 1000

    private var storage: SQLiteRecordStorage!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test_validation",
            maxRecords: 500,
            cacheMaxBytes: 10_000,
            maxRecordSizeBytes: maxRecordSize,
            maxBytesPerStream: 10_000,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )
    }

    override func tearDown() async throws {
        _ = try? await storage.clearRecords()
        storage = nil
        try await super.tearDown()
    }

    // MARK: - Per-record size limit (partition key + data blob)

    func testRecordExactlyAtMaxSizeIsAccepted() async throws {
        // "k" = 1 byte, data = 999 bytes → total 1000 = maxRecordSize
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: "k", data: Data(repeating: 0x41, count: 999))
        )
    }

    func testRecordExceedingMaxSizeByOneByteIsRejected() async throws {
        // "k" = 1 byte, data = 1000 bytes → total 1001 > maxRecordSize
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: "k", data: Data(repeating: 0x41, count: 1000))
            )
            XCTFail("Expected validation error")
        } catch let error as RecordCacheError {
            guard case .validation = error else {
                XCTFail("Expected RecordCacheError.validation, got \(error)")
                return
            }
        }
    }

    // MARK: - dataSize includes partition key

    func testDataSizeAccountsForPartitionKeyBytes() async throws {
        let partitionKey = String(repeating: "k", count: 10) // 10 bytes UTF-8
        let data = Data(repeating: 0x41, count: 50)

        try await storage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 60) // 50 + 10
    }

    func testDataSizeWithMultiByteUnicodePartitionKey() async throws {
        // Each emoji is 4 bytes in UTF-8, 2 emojis = 8 bytes
        let partitionKey = String(repeating: "😀", count: 2)
        let data = Data(repeating: 0x41, count: 10)

        try await storage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 18) // 10 + 8
    }

    // MARK: - Cache size limit respects full record size

    func testCacheLimitAccountsForPartitionKeyInCumulativeSize() async throws {
        let tightStorage = try SQLiteRecordStorage(
            identifier: "test_tight",
            maxRecords: 500,
            cacheMaxBytes: 80,
            maxRecordSizeBytes: maxRecordSize,
            maxBytesPerStream: 10_000,
            maxPartitionKeyLength: 256,
            connection: Connection(.inMemory)
        )

        let partitionKey = String(repeating: "k", count: 10) // 10 bytes
        let data = Data(repeating: 0x41, count: 30) // 30 bytes
        // Total per record = 40 bytes

        // First record: 40 bytes — fits in 80-byte cache
        try await tightStorage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        // Second record: 40 more → total 80 — still fits
        try await tightStorage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        // Third record: 40 more → total 120 > 80 limit
        do {
            try await tightStorage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))
            XCTFail("Expected cache limit error")
        } catch let error as RecordCacheError {
            guard case .limitExceeded = error else {
                XCTFail("Expected RecordCacheError.limitExceeded, got \(error)")
                return
            }
        }
    }

    // MARK: - Partition key validation (1–256 Unicode scalars)

    func testEmptyPartitionKeyIsRejected() async throws {
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: "", data: Data([1, 2, 3]))
            )
            XCTFail("Expected validation error")
        } catch let error as RecordCacheError {
            guard case .validation = error else {
                XCTFail("Expected RecordCacheError.validation, got \(error)")
                return
            }
        }
    }

    func testPartitionKeyAtMaxLength256IsAccepted() async throws {
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: String(repeating: "k", count: 256), data: Data([1]))
        )
    }

    func testPartitionKeyExceeding256CharactersIsRejected() async throws {
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: String(repeating: "k", count: 257), data: Data([1]))
            )
            XCTFail("Expected validation error")
        } catch let error as RecordCacheError {
            guard case .validation = error else {
                XCTFail("Expected RecordCacheError.validation, got \(error)")
                return
            }
        }
    }

    func testPartitionKeyWithMultiByteUnicodeCountsScalarsNotBytes() async throws {
        // Each emoji (😀) is 1 Unicode scalar but 4 bytes in UTF-8.
        // 10 emoji = 10 scalars (within 256 limit).
        let partitionKey = String(repeating: "😀", count: 10)
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: partitionKey, data: Data([1]))
        )
    }

    func testPartitionKeyExceeding256ScalarsWithEmojiIsRejected() async throws {
        // Each emoji (😀) is 1 Unicode scalar
        // 257 emoji = 257 scalars > 256 limit
        let partitionKey = String(repeating: "😀", count: 257)
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: partitionKey, data: Data([1]))
            )
            XCTFail("Expected validation error")
        } catch let error as RecordCacheError {
            guard case .validation = error else {
                XCTFail("Expected RecordCacheError.validation, got \(error)")
                return
            }
        }
    }

    // MARK: - Recovery after rejection

    func testStorageAcceptsValidRecordsAfterRejectingOversizedOne() async throws {
        // 20 bytes key + 990 bytes data = 1010 > 1000 limit
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: String(repeating: "k", count: 20), data: Data(repeating: 0x42, count: 990))
            )
            XCTFail("Expected validation error")
        } catch is RecordCacheError {
            // expected
        }

        // Valid record should still work
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: "a", data: Data([1, 2, 3]))
        )

        let cachedSize = try await storage.getCurrentCacheSize()
        // "a" (1) + data (3) = 4
        XCTAssertEqual(cachedSize, 4)
    }
}
