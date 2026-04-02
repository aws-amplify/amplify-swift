//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFirehoseClient
import AmplifyFoundation
import AmplifyFoundationBridge
import AWSPluginsCore
import XCTest

/// Firehose-specific integration tests.
///
/// Inherits all shared stream-client tests from `BaseStreamClientIntegrationTests`.
/// Firehose has no partition key concept, so no partition-key-specific tests are needed.
@available(iOS 16.0, macOS 13.0, *)
class FirehoseIntegrationTests: BaseStreamClientIntegrationTests {

    override var streamName: String { "amplify-firehose-test-stream" }

    // 1,000 KiB per-record limit + 1 byte to exceed it
    override var oversizedRecordSize: Int { 1_000 * 1_024 + 1 }

    override func createDefaultClient() throws -> TestableStreamClient {
        try AmplifyFirehoseClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithSmallCache(cacheMaxBytes: Int64) throws -> TestableStreamClient {
        try AmplifyFirehoseClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(cacheMaxBytes: cacheMaxBytes, flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithMaxRetries(maxRetries: Int) throws -> TestableStreamClient {
        try AmplifyFirehoseClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(maxRetries: maxRetries, flushStrategy: .none)
        ).asTestable()
    }

    override func createClientWithAutoFlush(interval: TimeInterval) throws -> TestableStreamClient {
        try AmplifyFirehoseClient(
            region: Self.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(flushStrategy: .interval(interval))
        ).asTestable()
    }

    override func createClientWithBadCredentials() throws -> TestableStreamClient {
        try AmplifyFirehoseClient(
            region: Self.region,
            credentialsProvider: InvalidCredentialsProvider(),
            options: .init(flushStrategy: .none)
        ).asTestable()
    }

    override func assertCacheLimitExceededError(_ error: Error) {
        guard let firehoseError = error as? FirehoseError,
              case .cacheLimitExceeded = firehoseError else {
            XCTFail("Expected FirehoseError.cacheLimitExceeded, got \(error)")
            return
        }
    }

    override func assertValidationError(_ error: Error) {
        guard let firehoseError = error as? FirehoseError,
              case .validation = firehoseError else {
            XCTFail("Expected FirehoseError.validation, got \(error)")
            return
        }
    }

}

// MARK: - Firehose TestableStreamClient adapter

@available(iOS 16.0, macOS 13.0, *)
private extension AmplifyFirehoseClient {
    func asTestable() -> TestableStreamClient {
        FirehoseTestableAdapter(client: self)
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct FirehoseTestableAdapter: TestableStreamClient {
    let client: AmplifyFirehoseClient

    func record(data: Data, streamName: String) async throws -> RecordData {
        try await client.record(data: data, streamName: streamName)
    }
    func flush() async throws -> FlushData { try await client.flush() }
    func clearCache() async throws -> ClearCacheData { try await client.clearCache() }
    func disable() async { await client.disable() }
    func enable() async { await client.enable() }
}
