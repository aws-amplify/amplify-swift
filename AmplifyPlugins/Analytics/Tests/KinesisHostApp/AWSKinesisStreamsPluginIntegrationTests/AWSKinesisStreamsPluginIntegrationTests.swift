//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoAuthPlugin
import AWSKinesisStreamsPlugin
import AWSPluginsCore
import AmplifyFoundation
import AmplifyFoundationBridge
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
@testable import Amplify

/// Integration tests for AmplifyKinesisClient against a real
/// Kinesis Data Stream using pre-provisioned Cognito credentials.
///
/// Prerequisites:
/// 1. Deploy the backend: `cd infra && npx ampx sandbox`
/// 2. Create a test user in the Cognito User Pool
/// 3. Copy configs to ~/.aws-amplify/amplify-ios/testconfiguration/:
///    - AWSKinesisStreamsPluginIntegrationTests-amplify_outputs.json
///    - AWSKinesisStreamsPluginIntegrationTests-credentials.json
/// 4. Run from the KinesisHostApp Xcode project
@available(iOS 16.0, macOS 13.0, *)
class AWSKinesisStreamsPluginIntegrationTests: XCTestCase {

    static let amplifyOutputs =
        "testconfiguration/AWSKinesisStreamsPluginIntegrationTests-amplify_outputs"
    static let credentialsResource =
        "testconfiguration/AWSKinesisStreamsPluginIntegrationTests-credentials"
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
        try? await kinesis?.clearCache()
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
        } catch {
            // Expected — cache limit exceeded
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

    // MARK: - Escape hatch

    func testGetKinesisClient() {
        XCTAssertNotNil(kinesis.getKinesisClient())
    }
}
