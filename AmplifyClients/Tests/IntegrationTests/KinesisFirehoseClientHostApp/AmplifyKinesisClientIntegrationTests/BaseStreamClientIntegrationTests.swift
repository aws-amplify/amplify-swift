//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AmplifyRecordCache
import AWSCognitoAuthPlugin
import AWSPluginsCore
import XCTest
@testable import Amplify

/// Shared integration tests for stream-based record clients.
///
/// Both `AmplifyKinesisClient` and `AmplifyFirehoseClient` share the same
/// `RecordClient` core with identical flush, cache, retry, and lifecycle
/// semantics. This base class captures those shared behaviours so they are
/// tested once and inherited by both concrete test classes.
@available(iOS 16.0, macOS 13.0, *)
class BaseStreamClientIntegrationTests: XCTestCase {

    static let amplifyOutputs =
        "testconfiguration/AmplifyKinesisClientIntegrationTests-amplify_outputs"
    static let credentialsResource =
        "testconfiguration/AmplifyKinesisClientIntegrationTests-credentials"
    static let region = "us-east-1"

    // MARK: - Abstract contract — subclasses override these

    /// Skip test execution for the base class — only subclasses should run.
    override func invokeTest() {
        guard type(of: self) != BaseStreamClientIntegrationTests.self else { return }
        super.invokeTest()
    }

    var streamName: String { fatalError("Subclass must override") }
    var oversizedRecordSize: Int { fatalError("Subclass must override") }

    func createDefaultClient() throws -> TestableStreamClient {
        fatalError("Subclass must override")
    }
    func createClientWithSmallCache(cacheMaxBytes: Int64) throws -> TestableStreamClient {
        fatalError("Subclass must override")
    }
    func createClientWithMaxRetries(maxRetries: Int) throws -> TestableStreamClient {
        fatalError("Subclass must override")
    }
    func createClientWithAutoFlush(interval: TimeInterval) throws -> TestableStreamClient {
        fatalError("Subclass must override")
    }
    func createClientWithBadCredentials() throws -> TestableStreamClient {
        fatalError("Subclass must override")
    }
    func assertCacheLimitExceededError(_ error: Error) {
        fatalError("Subclass must override")
    }
    func assertValidationError(_ error: Error) {
        fatalError("Subclass must override")
    }

    // MARK: - Shared credentials setup

    static var credentialsProvider: (any AmplifyFoundation.AWSCredentialsProvider)!
    private static var isConfigured = false

    // MARK: - Per-test setup / teardown

    var client: TestableStreamClient!

    override func setUp() async throws {
        if !Self.isConfigured {
            if !Amplify.isConfigured {
                try Amplify.add(plugin: AWSCognitoAuthPlugin())
                let data = try TestConfigHelper.retrieve(forResource: Self.amplifyOutputs)
                try Amplify.configure(with: .data(data))
            }

            let credentials = try TestConfigHelper.retrieveCredentials(
                forResource: Self.credentialsResource
            )
            guard let username = credentials["username"],
                  let password = credentials["password"] else {
                XCTFail("Missing username/password in credentials file")
                return
            }

            _ = await Amplify.Auth.signOut()
            let result = try await Amplify.Auth.signIn(
                username: username, password: password
            )
            guard result.isSignedIn else {
                XCTFail("Sign in failed")
                return
            }

            Self.credentialsProvider = SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            )
            Self.isConfigured = true
        }

        client = try createDefaultClient()
        try await client.clearCache()
    }

    override func tearDown() async throws {
        await client?.disable()
        _ = try? await client?.clearCache()
    }

    // MARK: - Core happy path

    /// Test that a single record can be recorded and flushed.
    ///
    /// - Given: A single record cached locally
    /// - When:
    ///    - flush() is called
    /// - Then:
    ///    - The record is sent to the stream and recordsFlushed > 0
    ///
    func testRecordAndFlush() async throws {
        try await client.record(
            data: XCTUnwrap("test-record".data(using: .utf8)),
            streamName: streamName
        )
        let result = try await client.flush()
        XCTAssertGreaterThan(result.recordsFlushed, 0)
    }

    /// Test that flushing an empty cache returns zero.
    ///
    /// - Given: An empty cache with no pending records
    /// - When:
    ///    - flush() is called
    /// - Then:
    ///    - recordsFlushed is 0 and flushInProgress is false
    ///
    func testFlushWhenEmpty() async throws {
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 0)
        XCTAssertFalse(result.flushInProgress)
    }

    /// Test that records submitted while disabled are silently dropped.
    ///
    /// - Given: The client is disabled
    /// - When:
    ///    - A record is submitted and the client is re-enabled
    /// - Then:
    ///    - The record is dropped and flush returns 0
    ///
    func testRecordWhileDisabledDropsRecords() async throws {
        await client.disable()
        try await client.record(
            data: XCTUnwrap("dropped-record".data(using: .utf8)),
            streamName: streamName
        )
        await client.enable()
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 0)
    }

    /// Test the enable/disable lifecycle preserves pre-disable records.
    ///
    /// - Given: One record cached before disable, one submitted while disabled
    /// - When:
    ///    - The client is re-enabled and flushed
    /// - Then:
    ///    - Only the pre-disable record is flushed (count == 1)
    ///
    func testEnableDisableLifecycle() async throws {
        try await client.record(
            data: XCTUnwrap("before-disable".data(using: .utf8)),
            streamName: streamName
        )
        await client.disable()
        try await client.record(
            data: XCTUnwrap("while-disabled".data(using: .utf8)),
            streamName: streamName
        )
        await client.enable()
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 1)
    }

    /// Test that concurrent flush calls are handled gracefully.
    ///
    /// - Given: 10 records cached locally
    /// - When:
    ///    - Two flush() calls are made concurrently
    /// - Then:
    ///    - At least one flush succeeds or one reports flushInProgress
    ///
    func testConcurrentFlushReturnsInProgress() async throws {
        for i in 0 ..< 10 {
            try await client.record(
                data: XCTUnwrap("record-\(i)".data(using: .utf8)),
                streamName: streamName
            )
        }
        async let flush1 = client.flush()
        async let flush2 = client.flush()
        let results = try await [flush1, flush2]
        let anyFlushed = results.contains { $0.recordsFlushed > 0 }
        let anyInProgress = results.contains { $0.flushInProgress }
        XCTAssertTrue(anyFlushed || anyInProgress)
    }

    // MARK: - Cache behavior

    /// Test that exceeding the cache byte limit throws an error.
    ///
    /// - Given: A client with a 100-byte cache limit
    /// - When:
    ///    - Two 60-byte records are submitted (exceeding the limit)
    /// - Then:
    ///    - A cacheLimitExceeded error is thrown
    ///
    func testCacheLimitExceeded() async throws {
        let smallClient = try createClientWithSmallCache(cacheMaxBytes: 100)
        try await smallClient.clearCache()

        do {
            let bigData = Data(repeating: 0x41, count: 60)
            try await smallClient.record(data: bigData, streamName: streamName)
            try await smallClient.record(data: bigData, streamName: streamName)
            XCTFail("Expected cache limit error")
        } catch {
            assertCacheLimitExceededError(error)
        }
        try await smallClient.clearCache()
    }

    /// Test that clearCache removes all pending records.
    ///
    /// - Given: One record cached locally
    /// - When:
    ///    - clearCache() is called
    /// - Then:
    ///    - The record is removed and a subsequent flush returns 0
    ///
    func testClearCache() async throws {
        try await client.record(
            data: XCTUnwrap("to-be-cleared".data(using: .utf8)),
            streamName: streamName
        )
        let clearResult = try await client.clearCache()
        XCTAssertGreaterThan(clearResult.recordsCleared, 0)
        let flushResult = try await client.flush()
        XCTAssertEqual(flushResult.recordsFlushed, 0)
    }

    // MARK: - Error paths

    /// Test that a nonexistent stream doesn't block valid stream records.
    ///
    /// - Given: One record to a nonexistent stream and one to a valid stream
    /// - When:
    ///    - flush() is called
    /// - Then:
    ///    - Only the valid-stream record is flushed (count == 1)
    ///
    func testFlushWithNonexistentStreamName() async throws {
        try await client.record(
            data: XCTUnwrap("wrong-stream".data(using: .utf8)),
            streamName: "nonexistent-stream-name"
        )
        try await client.record(
            data: XCTUnwrap("valid-stream".data(using: .utf8)),
            streamName: streamName
        )
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 1)
        try await client.clearCache()
    }

    /// Test that invalid credentials don't cause a crash.
    ///
    /// - Given: A client configured with invalid AWS credentials
    /// - When:
    ///    - A record is submitted and flush() is called
    /// - Then:
    ///    - No records are successfully flushed (auth error handled silently)
    ///
    func testFlushWithInvalidCredentials() async throws {
        let badClient = try createClientWithBadCredentials()
        try await badClient.record(
            data: XCTUnwrap("bad-creds".data(using: .utf8)),
            streamName: streamName
        )
        do {
            let result = try await badClient.flush()
            XCTAssertEqual(result.recordsFlushed, 0)
        } catch {
            // Network-level errors (e.g. TLS failures) are expected with fake credentials
        }
        try await badClient.clearCache()
    }

    // MARK: - Retry exhaustion

    /// Test that records to a nonexistent stream are evicted after exhausting retries.
    ///
    /// - Given: One record to a nonexistent stream and one to a valid stream, maxRetries = 5
    /// - When:
    ///    - flush() is called repeatedly (1 + maxRetries + 1 times)
    /// - Then:
    ///    - The valid record flushes on the first call; the invalid record is evicted
    ///      after exhausting retries, and the cache is empty at the end
    ///
    func testInvalidStreamRecordIsDroppedAfterMaxRetries() async throws {
        let maxRetries = 5
        let retryClient = try createClientWithMaxRetries(maxRetries: maxRetries)
        try await retryClient.clearCache()

        try await retryClient.record(
            data: XCTUnwrap("invalid-stream".data(using: .utf8)),
            streamName: "nonexistent-stream-name"
        )
        try await retryClient.record(
            data: XCTUnwrap("valid-stream".data(using: .utf8)),
            streamName: streamName
        )

        let firstFlush = try await retryClient.flush()
        XCTAssertEqual(firstFlush.recordsFlushed, 1)

        for _ in 0 ..< maxRetries {
            let result = try await retryClient.flush()
            XCTAssertEqual(result.recordsFlushed, 0)
        }

        let finalFlush = try await retryClient.flush()
        XCTAssertEqual(finalFlush.recordsFlushed, 0)

        let clearResult = try await retryClient.clearCache()
        XCTAssertEqual(clearResult.recordsCleared, 0)
        await retryClient.disable()
    }

    // MARK: - Stress tests

    /// Test high-volume record and flush.
    ///
    /// - Given: 50 records cached locally
    /// - When:
    ///    - flush() is called once
    /// - Then:
    ///    - All 50 records are flushed successfully
    ///
    func testHighVolumeRecordAndFlush() async throws {
        let count = 50
        for i in 0 ..< count {
            try await client.record(
                data: XCTUnwrap("stress-\(i)".data(using: .utf8)),
                streamName: streamName
            )
        }
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, count)
    }

    /// Test repeated record-then-flush cycles.
    ///
    /// - Given: 5 cycles of 5 records each
    /// - When:
    ///    - flush() is called after each cycle
    /// - Then:
    ///    - The total flushed across all cycles equals 25
    ///
    func testRepeatedFlushCycles() async throws {
        let cycles = 5
        let perCycle = 5
        var total = 0
        for cycle in 0 ..< cycles {
            for i in 0 ..< perCycle {
                try await client.record(
                    data: XCTUnwrap("c\(cycle)-r\(i)".data(using: .utf8)),
                    streamName: streamName
                )
            }
            total += try await client.flush().recordsFlushed
        }
        XCTAssertEqual(total, cycles * perCycle)
    }

    /// Test concurrent producers with a periodic flusher.
    ///
    /// - Given: 5 producer tasks each recording 20 events concurrently
    /// - When:
    ///    - A flusher task calls flush() every 500ms during production
    /// - Then:
    ///    - All 100 records are eventually flushed with none lost
    ///
    func testConcurrentRecordAndFlushStress() async throws {
        let producers = 5
        let recordsPerProducer = 20
        let totalExpected = producers * recordsPerProducer
        let counter = FlushCounter()

        let flusherTask = Task {
            while !Task.isCancelled {
                let result = try await client.flush()
                await counter.add(result.recordsFlushed)
                try await Task.sleep(for: .milliseconds(500))
            }
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for p in 0 ..< producers {
                group.addTask {
                    for i in 0 ..< recordsPerProducer {
                        try await self.client.record(
                            data: XCTUnwrap("p\(p)-r\(i)".data(using: .utf8)),
                            streamName: self.streamName
                        )
                    }
                }
            }
            try await group.waitForAll()
        }

        flusherTask.cancel()
        _ = try? await flusherTask.value

        let drainResult = try await client.flush()
        await counter.add(drainResult.recordsFlushed)

        let finalResult = try await client.flush()
        XCTAssertEqual(finalResult.recordsFlushed, 0)

        let totalFlushed = await counter.value
        XCTAssertEqual(totalFlushed, totalExpected)
    }

    // MARK: - Multi-batch flush

    /// Test that a single flush drains records exceeding the per-batch limit.
    ///
    /// - Given: 1100 records cached (exceeding the per-batch limit)
    /// - When:
    ///    - A single flush() is called
    /// - Then:
    ///    - All 1100 records are drained across multiple internal batches
    ///
    func testSingleFlushDrainsMultipleBatches() async throws {
        let recordCount = 1_100
        for i in 0 ..< recordCount {
            try await client.record(
                data: XCTUnwrap("batch-\(i)".data(using: .utf8)),
                streamName: streamName
            )
        }
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, recordCount)
        let empty = try await client.flush()
        XCTAssertEqual(empty.recordsFlushed, 0)
    }

    // MARK: - Auto-flush

    /// Test that the auto-flush scheduler starts without an explicit enable() call.
    ///
    /// - Given: A client with a 3-second auto-flush interval (no explicit enable() call)
    /// - When:
    ///    - A record is submitted and we wait 6 seconds
    /// - Then:
    ///    - The auto-flush fires and a manual flush finds 0 remaining records
    ///
    func testAutoFlushStartsWithoutExplicitEnable() async throws {
        let autoClient = try createClientWithAutoFlush(interval: 3)
        try await autoClient.record(
            data: XCTUnwrap("auto-start".data(using: .utf8)),
            streamName: streamName
        )
        try await Task.sleep(for: .seconds(6))
        let result = try await autoClient.flush()
        XCTAssertEqual(result.recordsFlushed, 0)
        await autoClient.disable()
        try await autoClient.clearCache()
    }

    // MARK: - Oversized record validation

    /// Test that an oversized record is rejected and the client remains usable.
    ///
    /// - Given: A record that exceeds the per-record size limit
    /// - When:
    ///    - record() is called
    /// - Then:
    ///    - A validation error is thrown, and a subsequent valid record still flushes
    ///
    func testOversizedRecordIsRejectedAndFlushStillWorks() async throws {
        let oversizedData = Data(repeating: 0x42, count: oversizedRecordSize)
        do {
            try await client.record(data: oversizedData, streamName: streamName)
            XCTFail("Expected oversized record to be rejected")
        } catch {
            assertValidationError(error)
        }

        try await client.record(
            data: XCTUnwrap("still-works".data(using: .utf8)),
            streamName: streamName
        )
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 1)
    }

    // MARK: - Escape hatch (subclasses add their own)
}

// MARK: - Helpers

@available(iOS 16.0, macOS 13.0, *)
actor FlushCounter {
    private(set) var value = 0
    func add(_ count: Int) { value += count }
}

struct InvalidCredentials: AmplifyFoundation.AWSCredentials {
    let accessKeyId = "AKIAIOSFODNN7EXAMPLE"
    let secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

struct InvalidCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        InvalidCredentials()
    }
}
