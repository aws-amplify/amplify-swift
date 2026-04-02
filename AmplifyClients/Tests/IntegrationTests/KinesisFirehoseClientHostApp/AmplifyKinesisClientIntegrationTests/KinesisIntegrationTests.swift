//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AmplifyKinesisClient
import AWSPluginsCore
import XCTest

/// Kinesis-specific integration tests.
///
/// Inherits all shared stream-client tests from `BaseStreamClientIntegrationTests`
/// and adds Kinesis-specific tests for partition key validation and large-payload batching.
@available(iOS 16.0, macOS 13.0, *)
class KinesisIntegrationTests: BaseStreamClientIntegrationTests {

    override var streamName: String { "amplify-kinesis-test-stream" }

    // 10 MiB per-record limit + 1 byte to exceed it
    override var oversizedRecordSize: Int { 10 * 1_024 * 1_024 + 1 }

    override func createDefaultClient() throws -> TestableStreamClient {
        try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithSmallCache(cacheMaxBytes: Int64) throws -> TestableStreamClient {
        try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(cacheMaxBytes: cacheMaxBytes, flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithMaxRetries(maxRetries: Int) throws -> TestableStreamClient {
        try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(maxRetries: maxRetries, flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithAutoFlush(interval: TimeInterval) throws -> TestableStreamClient {
        try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(flushStrategy: .interval(interval))
        ).asTestable()
    }

    override func createClientWithBadCredentials() throws -> TestableStreamClient {
        try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: InvalidCredentialsProvider(),
            options: .init(flushStrategy: .none)
        ).asTestable()
    }

    override func assertCacheLimitExceededError(_ error: Error) {
        guard let kinesisError = error as? KinesisError,
              case .cacheLimitExceeded = kinesisError else {
            XCTFail("Expected KinesisError.cacheLimitExceeded, got \(error)")
            return
        }
    }

    override func assertValidationError(_ error: Error) {
        guard let kinesisError = error as? KinesisError,
              case .validation = kinesisError else {
            XCTFail("Expected KinesisError.validation, got \(error)")
            return
        }
    }

    // MARK: - Kinesis-specific: partition key validation

    func testRecordWithMax256EmojiScalarsAndFlush() async throws {
        let emojiPartitionKey = String(repeating: "😀", count: 256)
        XCTAssertEqual(emojiPartitionKey.unicodeScalars.count, 256)
        XCTAssertEqual(emojiPartitionKey.utf8.count, 1_024)

        let kinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(flushStrategy: .none)
        )

        try await kinesis.record(
            data: XCTUnwrap("emoji-pk-test".data(using: .utf8)),
            partitionKey: emojiPartitionKey,
            streamName: streamName
        )
        let result = try await kinesis.flush()
        XCTAssertEqual(result.recordsFlushed, 1)
        await kinesis.disable()
        try await kinesis.clearCache()
    }

    // MARK: - Kinesis-specific: large payload batching

    func testFlushLargePayloadWithLargePartitionKeys() async throws {
        let largeKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(cacheMaxBytes: 12 * 1_024 * 1_024, flushStrategy: .none)
        )
        try await largeKinesis.clearCache()

        let recordDataSize = 50 * 1_024 // 50 KB
        let recordCount = 210

        for i in 0 ..< recordCount {
            let partitionKey = String(repeating: "k", count: 200) + "-\(i)"
            let data = Data(repeating: UInt8(i % 256), count: recordDataSize)
            try await largeKinesis.record(
                data: data, partitionKey: partitionKey, streamName: streamName
            )
        }

        let result = try await largeKinesis.flush()
        XCTAssertEqual(result.recordsFlushed, recordCount)

        let empty = try await largeKinesis.flush()
        XCTAssertEqual(empty.recordsFlushed, 0)
        try await largeKinesis.clearCache()
    }

}

// MARK: - Kinesis TestableStreamClient adapter

@available(iOS 16.0, macOS 13.0, *)
private extension AmplifyKinesisClient {
    func asTestable(defaultPartitionKey: String = "test-partition") -> TestableStreamClient {
        KinesisTestableAdapter(client: self, partitionKey: defaultPartitionKey)
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct KinesisTestableAdapter: TestableStreamClient {
    let client: AmplifyKinesisClient
    let partitionKey: String

    func record(data: Data, streamName: String) async throws -> RecordData {
        try await client.record(data: data, partitionKey: partitionKey, streamName: streamName)
    }
    func flush() async throws -> FlushData { try await client.flush() }
    func clearCache() async throws -> ClearCacheData { try await client.clearCache() }
    func disable() async { await client.disable() }
    func enable() async { await client.enable() }
}
