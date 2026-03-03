//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoAuthPlugin
import AmplifyKinesisClient
import AWSPluginsCore
import AmplifyFoundation
import AmplifyFoundationBridge
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
            data: "test-record".data(using: .utf8)!,
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
            data: "dropped-record".data(using: .utf8)!,
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.enable()
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
    }

    func testEnableDisableLifecycle() async throws {
        try await kinesis.record(
            data: "before-disable".data(using: .utf8)!,
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.disable()
        try await kinesis.record(
            data: "while-disabled".data(using: .utf8)!,
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        await kinesis.enable()
        let flushResult = try await kinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 1)
    }

    // MARK: - Cache behavior

    func testClearCache() async throws {
        try await kinesis.record(
            data: "to-be-cleared".data(using: .utf8)!,
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

    // MARK: - Stress tests

    func testHighVolumeRecordAndFlush() async throws {
        let count = 50
        for i in 0..<count {
            try await kinesis.record(
                data: "stress-\(i)".data(using: .utf8)!,
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
        for cycle in 0..<cycles {
            for i in 0..<perCycle {
                try await kinesis.record(
                    data: "c\(cycle)-r\(i)".data(using: .utf8)!,
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
            data: "auto-flush".data(using: .utf8)!,
            partitionKey: "partition-1",
            streamName: Self.streamName
        )
        try await Task.sleep(for: .seconds(6))
        let flushResult = try await autoKinesis.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
        await autoKinesis.disable()
        try await autoKinesis.clearCache()
    }

    // // MARK: - PutRecords size limits
    //
    // /// Fills the cache with >5 MB of data (using large partition keys) for a single
    // /// stream, then flushes. This exercises the PutRecords API limit of 5 MiB per
    // /// request and verifies the client handles batching/size correctly.
    // func testFlushLargePayloadWithLargePartitionKeys() async throws {
    //     let largeKinesis = try AmplifyKinesisClient(
    //         region: Self.region,
    //         credentialsProvider: SDKToFoundationCredentialsAdapter(
    //             resolver: AWSAuthService().getCredentialIdentityResolver()
    //         ),
    //         options: .init(
    //             cacheMaxBytes: 6 * 1_024 * 1_024, // 6 MB cache to hold >5 MB
    //             flushStrategy: .none
    //         )
    //     )
    //     try await largeKinesis.clearCache()
    //
    //     // Each record: ~50 KB data + ~200-char partition key
    //     // 110 records ≈ 5.5 MB total (exceeds the 5 MiB PutRecords request limit)
    //     let recordDataSize = 50 * 1_024 // 50 KB
    //     let recordCount = 110
    //
    //     for i in 0..<recordCount {
    //         let partitionKey = String(repeating: "k", count: 200) + "-\(i)"
    //         let data = Data(repeating: UInt8(i % 256), count: recordDataSize)
    //         try await largeKinesis.record(
    //             data: data,
    //             partitionKey: partitionKey,
    //             streamName: Self.streamName
    //         )
    //     }
    //
    //     let flushResult = try await largeKinesis.flush()
    //     XCTAssertEqual(flushResult.recordsFlushed, recordCount,
    //                    "All \(recordCount) records should be flushed despite exceeding 5 MiB per-request limit")
    //
    //     try await largeKinesis.clearCache()
    // }
    //
    // /// Attempts to record a single entry whose total size (partition key + data blob)
    // /// exceeds the 1 MiB per-record limit. The record call should fail, and a
    // /// subsequent flush of a valid record should still succeed — proving the client
    // /// is not left in a broken state.
    // func testOversizedRecordIsRejectedAndFlushStillWorks() async throws {
    //     // 1 MiB = 1_048_576 bytes. Use a 256-char partition key (~256 bytes UTF-8)
    //     // plus a data blob that pushes the total over 1 MiB.
    //     let largePartitionKey = String(repeating: "k", count: 256)
    //     let oversizedData = Data(repeating: 0x42, count: 1_048_576) // 1 MiB data + 256 bytes key > 1 MiB
    //
    //     do {
    //         try await kinesis.record(
    //             data: oversizedData,
    //             partitionKey: largePartitionKey,
    //             streamName: Self.streamName
    //         )
    //         XCTFail("Expected record to fail with oversized payload")
    //     } catch let error as KinesisError {
    //         guard case .cacheLimitExceeded = error else {
    //             XCTFail("Expected KinesisError.cacheLimitExceeded, got \(error)")
    //             return
    //         }
    //     }
    //
    //     // Now record a valid small record and flush — client should still work
    //     try await kinesis.record(
    //         data: "still-works".data(using: .utf8)!,
    //         partitionKey: "partition-1",
    //         streamName: Self.streamName
    //     )
    //
    //     let flushResult = try await kinesis.flush()
    //     XCTAssertEqual(flushResult.recordsFlushed, 1,
    //                    "Valid record should flush successfully after oversized record was rejected")
    // }

    // MARK: - Escape hatch

    func testGetKinesisClient() {
        XCTAssertNotNil(kinesis.getKinesisClient())
    }
}
