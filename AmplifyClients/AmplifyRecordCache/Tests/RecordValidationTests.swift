//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest
@testable import AmplifyRecordCache

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
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class RecordValidationTests: XCTestCase, @unchecked Sendable {

    private let maxRecordSize: Int64 = 1_000

    /// Kinesis's PutRecords partition-key limit: 1–256 Unicode characters. `AmplifyKinesisClient` passes it to
    /// the storage as `maxPartitionKeyLength`; it is repeated here because this target does not depend on Kinesis.
    private static let kinesisMaxPartitionKeyLength = 256

    private var storage: SQLiteRecordStorage!

    override func setUp() async throws {
        try await super.setUp()
        storage = try SQLiteRecordStorage(
            identifier: "test_validation",
            maxRecords: 500,
            cacheMaxBytes: 10_000,
            maxRecordSizeBytes: maxRecordSize,
            maxBytesPerStream: 10_000,
            maxPartitionKeyLength: Self.kinesisMaxPartitionKeyLength,
            connection: Connection(.inMemory)
        )
    }

    override func tearDown() async throws {
        _ = try? await storage.clearRecords()
        storage = nil
        try await super.tearDown()
    }

    // MARK: - Per-record size limit (partition key + data blob)

    /// - Given: a storage with a 1,000-byte record limit
    /// - When: a record of a 1-byte partition key and 999 bytes of data is added
    /// - Then:
    ///    - it is accepted: a record exactly at the limit is valid
    func testRecordExactlyAtMaxSizeIsAccepted() async throws {
        // "k" = 1 byte, data = 999 bytes → total 1000 = maxRecordSize
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: "k", data: Data(repeating: 0x41, count: 999))
        )
    }

    /// - Given: a storage with a 1,000-byte record limit
    /// - When: a record of a 1-byte partition key and 1,000 bytes of data is added
    /// - Then:
    ///    - it throws `RecordCacheError.validation`
    func testRecordExceedingMaxSizeByOneByteIsRejected() async throws {
        // "k" = 1 byte, data = 1000 bytes → total 1001 > maxRecordSize
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: "k", data: Data(repeating: 0x41, count: 1_000))
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

    /// - Given: an empty storage
    /// - When: a record with a 10-byte partition key and 50 bytes of data is added
    /// - Then:
    ///    - the cache size is 60: the partition key counts towards the record's size
    func testDataSizeAccountsForPartitionKeyBytes() async throws {
        let partitionKey = String(repeating: "k", count: 10) // 10 bytes UTF-8
        let data = Data(repeating: 0x41, count: 50)

        try await storage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 60) // 50 + 10
    }

    /// - Given: an empty storage
    /// - When: a record with a partition key of two emoji (8 bytes in UTF-8) and 10 bytes of data is added
    /// - Then:
    ///    - the cache size is 18: the partition key counts by its UTF-8 bytes
    func testDataSizeWithMultiByteUnicodePartitionKey() async throws {
        // Each emoji is 4 bytes in UTF-8, 2 emojis = 8 bytes
        let partitionKey = String(repeating: "😀", count: 2)
        let data = Data(repeating: 0x41, count: 10)

        try await storage.addRecord(RecordInput(streamName: "stream", partitionKey: partitionKey, data: data))

        let cachedSize = try await storage.getCurrentCacheSize()
        XCTAssertEqual(cachedSize, 18) // 10 + 8
    }

    // MARK: - Cache size limit respects full record size

    /// - Given: a storage with an 80-byte cache limit, and records of a 10-byte partition key and 30 bytes of data
    /// - When: three such records are added
    /// - Then:
    ///    - the first two (80 bytes in total) are accepted, and the third throws
    ///      `RecordCacheError.limitExceeded`, because the partition keys count towards the cache size
    func testCacheLimitAccountsForPartitionKeyInCumulativeSize() async throws {
        let tightStorage = try SQLiteRecordStorage(
            identifier: "test_tight",
            maxRecords: 500,
            cacheMaxBytes: 80,
            maxRecordSizeBytes: maxRecordSize,
            maxBytesPerStream: 10_000,
            maxPartitionKeyLength: Self.kinesisMaxPartitionKeyLength,
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

    /// - Given: an empty storage
    /// - When: a record with an empty partition key is added
    /// - Then:
    ///    - it throws `RecordCacheError.validation`
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

    /// - Given: a storage with a 256-character partition key limit
    /// - When: a record with a 256-character partition key is added
    /// - Then:
    ///    - it is accepted
    func testPartitionKeyAtMaxLength256IsAccepted() async throws {
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: String(repeating: "k", count: Self.kinesisMaxPartitionKeyLength), data: Data([1]))
        )
    }

    /// - Given: a storage with a 256-character partition key limit
    /// - When: a record with a 257-character partition key is added
    /// - Then:
    ///    - it throws `RecordCacheError.validation`
    func testPartitionKeyExceeding256CharactersIsRejected() async throws {
        do {
            try await storage.addRecord(
                RecordInput(streamName: "stream", partitionKey: String(repeating: "k", count: Self.kinesisMaxPartitionKeyLength + 1), data: Data([1]))
            )
            XCTFail("Expected validation error")
        } catch let error as RecordCacheError {
            guard case .validation = error else {
                XCTFail("Expected RecordCacheError.validation, got \(error)")
                return
            }
        }
    }

    /// - Given: a storage with a 256-character partition key limit
    /// - When: a record with a partition key of 10 emoji (10 Unicode scalars, 40 bytes) is added
    /// - Then:
    ///    - it is accepted: the key's length is counted in Unicode scalars, not bytes
    func testPartitionKeyWithMultiByteUnicodeCountsScalarsNotBytes() async throws {
        // Each emoji (😀) is 1 Unicode scalar but 4 bytes in UTF-8.
        // 10 emoji = 10 scalars (within 256 limit).
        let partitionKey = String(repeating: "😀", count: 10)
        try await storage.addRecord(
            RecordInput(streamName: "stream", partitionKey: partitionKey, data: Data([1]))
        )
    }

    // MARK: - Recovery after rejection

    /// - Given: a storage with a 1,000-byte record limit
    /// - When: a 1,010-byte record is added, and then a valid 4-byte record
    /// - Then:
    ///    - the first throws, the second is accepted, and the cache size is 4: the rejected record left
    ///      nothing behind
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
