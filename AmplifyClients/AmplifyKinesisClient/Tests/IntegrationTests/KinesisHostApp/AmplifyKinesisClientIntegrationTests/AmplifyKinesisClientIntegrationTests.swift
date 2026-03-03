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
            options: .init(cacheMaxBytes: 10, flushStrategy: .none)
        )
        // Clear first so cachedSize starts at 0
        try await smallKinesis.clearCache()

        do {
            // 60 bytes > 10 byte limit — should fail immediately
            try await smallKinesis.record(
                data: Data(repeating: 0x41, count: 60),
                partitionKey: "p1",
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

    // MARK: - Auto-flush

    func testAutoFlush() async throws {
        let autoKinesis = try AmplifyKinesisClient(
            region: Self.region,
            credentialsProvider: SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            ),
            options: .init(flushStrategy: .interval(.seconds(3)))
        )
        try await autoKinesis.record(
            data: XCTUnwrap("auto-flush".data(using: .utf8)),
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        try await Task.sleep(for: .seconds(6))
        let flushResult = try await autoKinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
        await autoKinesis.disable()
        try await autoKinesis.clearCache()
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
        let oversizedData = Data(repeating: 0x42, count: 10 * 1024 * 1024) // 10 MiB data + 256 bytes key > 10 MiB

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
