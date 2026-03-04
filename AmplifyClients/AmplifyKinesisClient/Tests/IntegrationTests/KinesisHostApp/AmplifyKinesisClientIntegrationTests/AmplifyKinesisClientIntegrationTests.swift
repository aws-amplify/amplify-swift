//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AmplifyKinesisClient
import AWSCognitoAuthPlugin
import AWSPluginsCore
import XCTest
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
@testable import Amplify

/// Integration tests for AmplifyKinesisClient against a real
/// Kinesis Data Stream using pre-provisioned backend.
@available(iOS 16.0, macOS 13.0, *)
class AmplifyKinesisClientIntegrationTests: XCTestCase {

    static let amplifyOutputs =
        "testconfiguration/AmplifyKinesisClientIntegrationTests-amplify_outputs"
    static let credentialsResource =
        "testconfiguration/AmplifyKinesisClientIntegrationTests-credentials"
    static let streamName = "amplify-kinesis-swift-test-stream"
    static let region = "us-east-1"

    private var kinesis: AmplifyKinesisClient!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        // 1. Configure Amplify with Auth
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let data = try TestConfigHelper.retrieve(
                forResource: Self.amplifyOutputs
            )
            try Amplify.configure(with: .data(data))
        } catch {
            XCTFail("Failed to configure Amplify: \(error)")
            return
        }

        // 2. Sign in with pre-provisioned test user
        let credentials = try TestConfigHelper.retrieveCredentials(
            forResource: Self.credentialsResource
        )
        guard let username = credentials["username"],
              let password = credentials["password"] else {
            XCTFail("Missing username/password in credentials file")
            return
        }

        _ = await Amplify.Auth.signOut()
        let signInResult = try await Amplify.Auth.signIn(
            username: username,
            password: password
        )
        guard signInResult.isSignedIn else {
            XCTFail("Sign in failed")
            return
        }

        // 3. Create Kinesis client with authenticated credentials
        let credentialsProvider = SDKToFoundationCredentialsAdapter(
            resolver: AWSAuthService().getCredentialIdentityResolver()
        )

        kinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: credentialsProvider,
            options: .init(flushStrategy: .none)
        )
        try await kinesis.clearCache()
    }

    override func tearDown() async throws {
        await kinesis?.disable()
        _ = try? await kinesis?.clearCache()
        _ = await Amplify.Auth.signOut()
        await Amplify.reset()
    }

    // MARK: - Core happy path

    func testRecordAndFlush() async throws {
        try await kinesis.record(
            data: XCTUnwrap("test-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        let flushResult = try await kinesis.flush()
        XCTAssertGreaterThan(flushResult.recordsFlushed, 0)
    }

    func testFlushWhenEmpty() async throws {
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
        XCTAssertFalse(flushResult.flushInProgress)
    }

    func testRecordWhileDisabledDropsRecords() async throws {
        await kinesis.disable()
        try await kinesis.record(
            data: XCTUnwrap("dropped-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.enable()
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
    }

    func testEnableDisableLifecycle() async throws {
        try await kinesis.record(
            data: XCTUnwrap("before-disable".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.disable()
        try await kinesis.record(
            data: XCTUnwrap("while-disabled".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.enable()
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 1)
    }

    func testConcurrentFlushReturnsInProgress() async throws {
        for i in 0 ..< 10 {
            try await kinesis.record(
                data: XCTUnwrap("record-\(i)".data(using: .utf8)),
                partitionKey: "partition-1",
                streamName: Self.streamName
            )
        }

        async let flush1 = kinesis.flush()
        async let flush2 = kinesis.flush()
        let results = try await [flush1, flush2]

        let anyFlushed = results.contains { $0.recordsFlushed > 0 }
        let anyInProgress = results.contains { $0.flushInProgress }
        // Either both flushed (if first completed before second started) or one was skipped
        XCTAssertTrue(anyFlushed || anyInProgress)
    }

    // MARK: - Cache behavior

    func testClearCache() async throws {
        try await kinesis.record(
            data: XCTUnwrap("to-be-cleared".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        let clearResult = try await kinesis.clearCache()
        XCTAssertGreaterThan(clearResult.recordsCleared, 0)
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
    }

    func testCacheLimitExceeded() async throws {
        let smallKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            ),
            options: .init(cacheMaxBytes: 100, flushStrategy: .none)
        )
        // Clear first so cachedSize starts at 0
        try await smallKinesis.clearCache()

        do {
            // Fill the cache
            let bigData = Data(repeating: 0x41, count: 60) // 60 bytes
            try await smallKinesis.record(
                data: bigData,
                partitionKey: "partition-1",
                streamName: Self.streamName
            )

            // This should exceed the 100-byte limit
            try await smallKinesis.record(
                data: bigData,
                partitionKey: "partition-1",
                streamName: Self.streamName
            )
            XCTFail("Expected cache limit error")
        } catch let error as KinesisError {
            guard case .cacheLimitExceeded = error else {
                XCTFail("Expected KinesisError.cacheLimitExceeded, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected KinesisError.cacheLimitExceeded, got unexpected error: \(error)")
        }
        try await smallKinesis.clearCache()
    }

    // MARK: - Error paths

    /// Flush with a nonexistent stream name should succeed (SDK errors are handled silently).
    /// The valid stream's record should still be flushed, proving one bad stream
    /// doesn't block others.
    func testFlushWithNonexistentStreamName() async throws {
        try await kinesis.record(
            data: XCTUnwrap("wrong-stream-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: "nonexistent-stream-name"
        )
        try await kinesis.record(
            data: XCTUnwrap("valid-stream-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )

        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 1)

        try await kinesis.clearCache()
    }

    /// Flush with invalid credentials should succeed (SDK errors are handled silently).
    /// Records are incremented and potentially deleted if they exceed retry limits.
    func testFlushWithInvalidCredentials() async throws {
        let badCredentials = InvalidCredentialsProvider()

        let badKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: badCredentials,
            options: .init(flushStrategy: .none)
        )

        try await badKinesis.record(
            data: XCTUnwrap("bad-creds-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )

        // SDK exceptions are handled silently — flush returns success
        let flushResult = try await badKinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)

        try await badKinesis.clearCache()
    }

    // MARK: - Retry exhaustion

    /// Records to both a nonexistent stream and a valid stream with maxRetries = 5.
    /// On the first flush the valid record is sent and the invalid-stream record
    /// stays in the cache (retry count incremented). After 6 total flushes the
    /// invalid-stream record should be evicted (retryCount >= maxRetries) and a
    /// final flush returns 0.
    func testInvalidStreamRecordIsDroppedAfterMaxRetries() async throws {
        let maxRetries = 5
        let retryKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            ),
            options: .init(maxRetries: maxRetries, flushStrategy: .none)
        )
        try await retryKinesis.clearCache()

        // Record to a nonexistent stream and a valid stream
        try await retryKinesis.record(
            data: XCTUnwrap("invalid-stream-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: "nonexistent-stream-name"
        )
        try await retryKinesis.record(
            data: XCTUnwrap("valid-stream-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )

        // First flush: valid record should be flushed, invalid stays
        let firstFlush = try await retryKinesis.flush()
        XCTAssertEqual(firstFlush.recordsFlushed, 1)

        // Flush maxRetries more times (flushes 2–6) to exhaust retries on the invalid record
        for _ in 0 ..< maxRetries {
            let result = try await retryKinesis.flush()
            XCTAssertEqual(result.recordsFlushed, 0)
        }

        // Final flush: invalid record should have been evicted, nothing left
        let finalFlush = try await retryKinesis.flush()
        XCTAssertEqual(finalFlush.recordsFlushed, 0)

        // Confirm cache is truly empty
        let clearResult = try await retryKinesis.clearCache()
        XCTAssertEqual(clearResult.recordsCleared, 0)

        await retryKinesis.disable()
    }

    // MARK: - Stress tests

    func testHighVolumeRecordAndFlush() async throws {
        let count = 50
        for i in 0 ..< count {
            try await kinesis.record(
                data: XCTUnwrap("stress-\(i)".data(using: .utf8)),
                partitionKey: "partition-\(i % 5)",
                streamName: Self.streamName
            )
        }
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, count)
    }

    func testRepeatedFlushCycles() async throws {
        let cycles = 5
        let perCycle = 5
        var total = 0
        for cycle in 0 ..< cycles {
            for i in 0 ..< perCycle {
                try await kinesis.record(
                    data: XCTUnwrap("c\(cycle)-r\(i)".data(using: .utf8)),
                    partitionKey: "partition-1",
                    streamName: Self.streamName
                )
            }
            let result = try await kinesis.flush()
            total += result.recordsFlushed
        }
        XCTAssertEqual(total, cycles * perCycle)
    }

    /// Stress test: N producer tasks record concurrently while a flusher calls
    /// flush() every 500ms. Simulates real-world usage where the app records
    /// analytics events while the auto-flush timer fires.
    ///
    /// Asserts that every recorded event is eventually flushed — no records lost
    /// under concurrent read/write pressure on the cache.
    func testConcurrentRecordAndFlushStress() async throws {
        let producers = 5
        let recordsPerProducer = 20
        let totalExpected = producers * recordsPerProducer

        // Shared mutable state protected by an actor
        let counter = FlushCounter()

        // Flusher: calls flush() every 500ms until signalled to stop
        let flusherTask = Task {
            while !Task.isCancelled {
                let result = try await kinesis.flush()
                await counter.add(result.recordsFlushed)
                try await Task.sleep(for: .milliseconds(500))
            }
        }

        // Producers: each records M events concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for p in 0 ..< producers {
                group.addTask {
                    for i in 0 ..< recordsPerProducer {
                        try await self.kinesis.record(
                            data: XCTUnwrap("stress-p\(p)-r\(i)".data(using: .utf8)),
                            partitionKey: "partition-\(p % 3)",
                            streamName: Self.streamName
                        )
                    }
                }
            }
            try await group.waitForAll()
        }

        // Stop the periodic flusher
        flusherTask.cancel()
        _ = try? await flusherTask.value

        // Final drain flush to pick up anything the periodic flusher missed
        let drainResult = try await kinesis.flush()
        await counter.add(drainResult.recordsFlushed)

        // Second drain to confirm nothing is left
        let finalResult = try await kinesis.flush()
        XCTAssertEqual(finalResult.recordsFlushed, 0)

        let totalFlushed = await counter.value
        XCTAssertEqual(totalFlushed, totalExpected)
    }

    // MARK: - Auto-flush

    /// Verify that creating a client with default options (no explicit flushStrategy)
    /// auto-starts the scheduler. Default is `.interval(30)`, so we override
    /// to a short interval to keep the test fast.
    func testDefaultConfigAutoStartsScheduler() async throws {
        // Default options use .interval(30). We use a short interval
        // to verify the scheduler is auto-started without waiting 30 seconds.
        let defaultKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            ),
            options: .init(flushStrategy: .interval(.seconds(3)))
        )
        // Note: no explicit enable() call — scheduler should auto-start from init

        try await defaultKinesis.record(
            data: XCTUnwrap("auto-start-record".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )

        // Wait for auto-flush to trigger (3s interval + buffer)
        try await Task.sleep(for: .seconds(6))

        // After auto-flush, a manual flush should find nothing left
        let flushResult = try await defaultKinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
        await defaultKinesis.disable()
        try await defaultKinesis.clearCache()
    }

    // MARK: - Partition key validation

    /// E2E test: Record with a partition key containing exactly 256 emoji Unicode scalars
    /// (the maximum allowed), then flush to verify the record is accepted by Kinesis.
    ///
    /// Each emoji (😀) is 1 Unicode scalar but 4 bytes in UTF-8. This test validates
    /// that our Unicode scalar counting is correct and that Kinesis accepts the
    /// maximum-length partition key.
    func testRecordWithMax256EmojiScalarsAndFlush() async throws {
        // Create partition key with exactly 256 emoji Unicode scalars
        // Each emoji is 1 scalar, 4 UTF-8 bytes
        let emojiPartitionKey = String(repeating: "😀", count: 256)

        // Verify our assumptions about the partition key
        let scalarCount = emojiPartitionKey.unicodeScalars.count
        let utf8ByteCount = emojiPartitionKey.utf8.count

        print("Emoji partition key: scalars=\(scalarCount), utf8Bytes=\(utf8ByteCount)")
        XCTAssertEqual(scalarCount, 256)
        XCTAssertEqual(utf8ByteCount, 1_024) // 256 emojis × 4 bytes each

        // Record with the emoji partition key
        try await kinesis.record(
            data: XCTUnwrap("test-data-with-emoji-partition-key".data(using: .utf8)),
            partitionKey: emojiPartitionKey,
            streamName: Self.streamName
        )

        // Flush and verify the record was sent successfully
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 1)

        print("Successfully recorded and flushed with 256 emoji scalar partition key")
    }

    // MARK: - PutRecords size limits

    /// Fills the cache with >10 MB of data (using large partition keys) for a single
    /// stream, then flushes. This exercises the PutRecords API limit of 10 MiB per
    /// request and verifies the client handles batching/size correctly.
    func testFlushLargePayloadWithLargePartitionKeys() async throws {
        let largeKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            ),
            options: .init(
                cacheMaxBytes: 12 * 1_024 * 1_024, // 12 MB cache to hold >10 MB
                flushStrategy: .none
            )
        )
        try await largeKinesis.clearCache()

        // Each record: ~50 KB data + ~200-char partition key ≈ 51 KB
        // 210 records ≈ 10.5 MB total (exceeds the 10 MiB PutRecords request limit)
        let recordDataSize = 50 * 1_024 // 50 KB
        let recordCount = 210

        for i in 0 ..< recordCount {
            let partitionKey = String(repeating: "k", count: 200) + "-\(i)"
            let data = Data(repeating: UInt8(i % 256), count: recordDataSize)
            try await largeKinesis.record(
                data: data,
                partitionKey: partitionKey,
                streamName: Self.streamName
            )
        }

        // First flush: sends up to 10 MiB worth of records
        let flush1 = try await largeKinesis.flush()
        XCTAssertGreaterThan(flush1.recordsFlushed, 0)

        // Second flush: sends the remaining records
        let flush2 = try await largeKinesis.flush()
        XCTAssertGreaterThan(flush2.recordsFlushed, 0)

        XCTAssertEqual(flush1.recordsFlushed + flush2.recordsFlushed, recordCount)

        // Third flush: nothing left
        let flush3 = try await largeKinesis.flush()
        XCTAssertEqual(flush3.recordsFlushed, 0)

        try await largeKinesis.clearCache()
    }

    /// Attempts to record a single entry whose total size (partition key + data blob)
    /// exceeds the 10 MiB per-record limit. The record call should fail, and a
    /// subsequent flush of a valid record should still succeed — proving the client
    /// is not left in a broken state.
    func testOversizedRecordIsRejectedAndFlushStillWorks() async throws {
        // 10 MiB = 10_485_760 bytes. Use a 256-char partition key (~256 bytes UTF-8)
        // plus a data blob that pushes the total over 10 MiB.
        let largePartitionKey = String(repeating: "k", count: 256)
        let oversizedData = Data(repeating: 0x42, count: 10 * 1_024 * 1_024) // 10 MiB data + 256 bytes key > 10 MiB

        do {
            try await kinesis.record(
                data: oversizedData,
                partitionKey: largePartitionKey,
                streamName: Self.streamName
            )
            XCTFail("Expected oversized record to be rejected")
        } catch let error as KinesisError {
            guard case .validation = error else {
                XCTFail("Expected validation error, got \(error)")
                return
            }
        }

        // Now record a valid small record and flush — client should still work
        try await kinesis.record(
            data: XCTUnwrap("still-works".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )

        let flushResult = try await kinesis.flush()
        XCTAssertEqual(
            flushResult.recordsFlushed,
            1,
            "Valid record should flush successfully after oversized record rejection"
        )
    }

    // MARK: - Escape hatch

    func testGetKinesisClient() {
        XCTAssertNotNil(kinesis.getKinesisClient())
    }
}

// MARK: - Helpers

/// Thread-safe counter for accumulating flushed record counts across tasks.
@available(iOS 16.0, macOS 13.0, *)
private actor FlushCounter {
    private(set) var value = 0
    func add(_ count: Int) {
        value += count
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct InvalidCredentials: AmplifyFoundation.AWSCredentials {
    // Keys from docs
    let accessKeyId = "AKIAIOSFODNN7EXAMPLE"
    let secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    let sessionToken: String? = nil
    let expiration: Date? = nil
}

@available(iOS 16.0, macOS 13.0, *)
private struct InvalidCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        InvalidCredentials()
    }
}
