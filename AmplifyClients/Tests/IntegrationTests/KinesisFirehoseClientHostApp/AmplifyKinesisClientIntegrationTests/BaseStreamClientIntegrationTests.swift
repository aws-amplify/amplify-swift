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

    func testRecordAndFlush() async throws {
        try await client.record(
            data: XCTUnwrap("test-record".data(using: .utf8)),
            streamName: streamName
        )
        let result = try await client.flush()
        XCTAssertGreaterThan(result.recordsFlushed, 0)
    }

    func testFlushWhenEmpty() async throws {
        let result = try await client.flush()
        XCTAssertEqual(result.recordsFlushed, 0)
        XCTAssertFalse(result.flushInProgress)
    }

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

    func testFlushWithInvalidCredentials() async throws {
        let badClient = try createClientWithBadCredentials()
        try await badClient.record(
            data: XCTUnwrap("bad-creds".data(using: .utf8)),
            streamName: streamName
        )
        // With invalid credentials, the SDK may return an auth error (handled silently,
        // recordsFlushed == 0) or the TLS handshake may fail (thrown as a network error).
        // Both are acceptable — the key assertion is that no records are successfully flushed.
        do {
            let result = try await badClient.flush()
            XCTAssertEqual(result.recordsFlushed, 0)
        } catch {
            // Network-level errors (e.g. TLS failures) are expected with fake credentials
        }
        try await badClient.clearCache()
    }

    // MARK: - Retry exhaustion

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

    func testSingleFlushDrainsMultipleBatches() async throws {
        let recordCount = 1100
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
