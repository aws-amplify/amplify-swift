//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Combine
import XCTest

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchLoggingClient
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

    var systemUnderTest: AmplifyCloudWatchLoggingClient!

    override func setUp() async throws {
        systemUnderTest = try AmplifyCloudWatchLoggingClient(
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
    /// - When: AmplifyCloudWatchLoggingClient is initialized
    /// - Then: the client is enabled and has a unique sink ID
    ///
    func testInitializationSetsDefaults() {
        XCTAssertTrue(systemUnderTest.isEnabled(for: .error))
        XCTAssertTrue(systemUnderTest.id.hasPrefix("AmplifyCloudWatchLoggingClient-"))
    }

    /// Given: valid configuration options
    ///
    /// - When: AmplifyCloudWatchLoggingClient is initialized
    /// - Then: getCloudWatchLogsClient returns a valid client
    ///
    func testInitializationCreatesCloudWatchClient() throws {
        let client = try systemUnderTest.getCloudWatchLogsClient()
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
}
