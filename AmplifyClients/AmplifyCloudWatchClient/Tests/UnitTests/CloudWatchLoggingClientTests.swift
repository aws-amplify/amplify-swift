//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Combine
import XCTest

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchClient
@testable import InternalCloudWatchLogging

private struct MockCredentials: AWSCredentials {
    var accessKeyId: String = "test-access-key"
    var secretAccessKey: String = "test-secret-key"
}

private class MockAWSCredentialsProvider: AWSCredentialsProvider {
    func resolve() async throws -> any AWSCredentials {
        return MockCredentials()
    }
}

final class CloudWatchLoggingClientTests: XCTestCase {

    var systemUnderTest: AmplifyCloudWatchClient!

    override func setUp() async throws {
        systemUnderTest = try AmplifyCloudWatchClient(
            region: "us-east-1",
            credentialsProvider: MockAWSCredentialsProvider(),
            options: .init(
                logGroupName: "/test/unit-tests",
                localStoreMaxSizeInMB: 1,
                flushStrategy: .interval(60),
                loggingConstraints: LoggingConstraints(defaultLogLevel: .error)
            )
        )
    }

    override func tearDown() async throws {
        await systemUnderTest.reset()
        systemUnderTest = nil
    }

    // MARK: - Initialization

    /// Given: valid configuration options
    ///
    /// - When: AmplifyCloudWatchClient is initialized
    /// - Then: the client is enabled and has a unique sink ID
    ///
    func testInitializationSetsDefaults() {
        XCTAssertTrue(systemUnderTest.isEnabled(for: .error))
        XCTAssertTrue(systemUnderTest.id.hasPrefix("AmplifyCloudWatchLoggingSink-"))
    }

    /// Given: valid configuration options
    ///
    /// - When: AmplifyCloudWatchClient is initialized
    /// - Then: getCloudWatchLogsClient returns a valid client
    ///
    func testInitializationCreatesCloudWatchClient() throws {
        let client = systemUnderTest.getCloudWatchLogsClient()
        XCTAssertNotNil(client)
    }

    // MARK: - Enable / Disable

    /// Given: an enabled client
    ///
    /// - When: disable is called
    /// - Then: isEnabled returns false for all log levels
    ///
    func testDisableStopsLogging() {
        XCTAssertTrue(systemUnderTest.isEnabled(for: .error))
        systemUnderTest.disable()
        XCTAssertFalse(systemUnderTest.isEnabled(for: .error))
        XCTAssertFalse(systemUnderTest.isEnabled(for: .verbose))
    }

    /// Given: a disabled client
    ///
    /// - When: enable is called
    /// - Then: isEnabled returns true
    ///
    func testEnableResumesLogging() {
        systemUnderTest.disable()
        XCTAssertFalse(systemUnderTest.isEnabled(for: .error))
        systemUnderTest.enable()
        XCTAssertTrue(systemUnderTest.isEnabled(for: .error))
    }

    // MARK: - LogSinkBehavior

    /// Given: an enabled client
    ///
    /// - When: isEnabled is called for various log levels
    /// - Then: it returns true for all levels (global enable, filtering is per-namespace)
    ///
    func testIsEnabledReturnsTrueForAllLevelsWhenEnabled() {
        XCTAssertTrue(systemUnderTest.isEnabled(for: .error))
        XCTAssertTrue(systemUnderTest.isEnabled(for: .warn))
        XCTAssertTrue(systemUnderTest.isEnabled(for: .info))
        XCTAssertTrue(systemUnderTest.isEnabled(for: .debug))
        XCTAssertTrue(systemUnderTest.isEnabled(for: .verbose))
    }

    /// Given: a disabled client
    ///
    /// - When: isEnabled is called
    /// - Then: it returns false for all levels
    ///
    func testIsEnabledReturnsFalseWhenDisabled() {
        systemUnderTest.disable()
        XCTAssertFalse(systemUnderTest.isEnabled(for: .error))
        XCTAssertFalse(systemUnderTest.isEnabled(for: .verbose))
    }

    // MARK: - Level keying / concurrency / teardown (injected client)

    /// Given: an injected client
    /// When: messages at several levels are emitted under one namespace
    /// Then: they share a single controller — the level is not part of the key
    func testMultipleLevelsUnderOneNamespaceUseASingleController() {
        let client = makeClient(mockClient: MockCloudWatchLogsClient())

        client.emit(message: LogMessage(level: .error, name: "OneNamespace", content: "e"))
        client.emit(message: LogMessage(level: .debug, name: "OneNamespace", content: "d"))
        client.emit(message: LogMessage(level: .info, name: "OneNamespace", content: "i"))
        XCTAssertEqual(client.controllerCount, 1)

        // Sanity: a different namespace still gets its own controller.
        client.emit(message: LogMessage(level: .error, name: "OtherNamespace", content: "x"))
        XCTAssertEqual(client.controllerCount, 2)
    }

    /// Given: an injected client
    /// When: many emits and a flush run concurrently
    /// Then: the run completes without a crash or data-race trap (exercises the client's locking)
    func testConcurrentEmitAndFlushDoNotCrash() async throws {
        let mockClient = MockCloudWatchLogsClient()
        let client = makeClient(mockClient: mockClient)

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 200 {
                group.addTask {
                    client.emit(message: LogMessage(level: .error, name: "ns\(index % 5)", content: "m"))
                }
            }
            group.addTask { try? await client.flushLogs() }
        }
    }

    /// Given: a client with an interval flush strategy (creates a repeating timer)
    /// When: the last strong reference is released
    /// Then: the client deallocates — no retained timer / network-monitor cycle
    func testClientDeallocatesWithoutRetainCycle() throws {
        weak var weakClient: AmplifyCloudWatchClient?
        func scope() {
            let client = makeClient(mockClient: MockCloudWatchLogsClient(), flushStrategy: .interval(1))
            weakClient = client
            // Emit so a CloudWatchLoggingSessionController / CloudWatchLoggingSession is actually
            // constructed — that is the object graph a retain cycle would most likely hide in.
            client.emit(message: LogMessage(level: .error, name: "DeallocNamespace", content: "m"))
            XCTAssertEqual(client.controllerCount, 1)
            XCTAssertNotNil(weakClient)
        }
        scope()
        XCTAssertNil(weakClient)
    }

    // MARK: - Helpers

    private func makeClient(
        mockClient: MockCloudWatchLogsClient,
        constraints: LoggingConstraints = LoggingConstraints(defaultLogLevel: .verbose),
        flushStrategy: FlushStrategy = .none
    ) -> AmplifyCloudWatchClient {
        AmplifyCloudWatchClient(
            cloudWatchClient: mockClient,
            logGroupName: "/test/unit",
            loggingConstraints: constraints,
            networkMonitor: MockLoggingNetworkMonitor(),
            flushStrategy: flushStrategy
        )
    }
}
