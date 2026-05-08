//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchLoggingClient

final class CloudWatchLoggingFilterTests: XCTestCase {

    var filter: CloudWatchLoggingFilter!

    override func setUp() async throws {
        filter = CloudWatchLoggingFilter(loggingConstraints: LoggingConstraints(
            defaultLogLevel: .error,
            namespaceLogLevel: [
                "Storage": .warn,
                "API": .info
            ],
            userLogLevel: [
                "user1": UserLogLevel(defaultLogLevel: .info, namespaceLogLevel: ["Auth": .debug]),
                "user2": UserLogLevel(defaultLogLevel: .warn, namespaceLogLevel: [:])
            ]
        ))
    }

    override func tearDown() async throws {
        filter = nil
    }

    /// Given: logging constraints with a default log level of error
    /// When: canLog is called with error level and no namespace
    /// Then: canLog returns true
    func testDefaultLogLevelAllowsError() {
        XCTAssertTrue(filter.canLog(withNamespace: nil, logLevel: .error, userIdentifier: nil))
    }

    /// Given: logging constraints with a default log level of error
    /// When: canLog is called with warn level and no namespace
    /// Then: canLog returns false
    func testDefaultLogLevelBlocksWarn() {
        XCTAssertFalse(filter.canLog(withNamespace: nil, logLevel: .warn, userIdentifier: nil))
    }

    /// Given: logging constraints with namespace-level overrides
    /// When: canLog is called with a namespace that has a higher log level
    /// Then: canLog returns true for allowed levels
    func testNamespaceLevelOverridesDefault() {
        XCTAssertTrue(filter.canLog(withNamespace: "Storage", logLevel: .warn, userIdentifier: nil))
        XCTAssertTrue(filter.canLog(withNamespace: "API", logLevel: .info, userIdentifier: nil))
    }

    /// Given: logging constraints with namespace-level overrides
    /// When: canLog is called with a namespace that has a higher log level
    /// Then: canLog returns false for levels below the namespace threshold
    func testNamespaceLevelBlocksBelowThreshold() {
        XCTAssertFalse(filter.canLog(withNamespace: "Storage", logLevel: .info, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withNamespace: "API", logLevel: .debug, userIdentifier: nil))
    }

    /// Given: logging constraints with user-level overrides
    /// When: canLog is called with a matching user identifier
    /// Then: canLog uses the user-level constraints
    func testUserLevelOverridesDefault() {
        XCTAssertTrue(filter.canLog(withNamespace: nil, logLevel: .info, userIdentifier: "user1"))
        XCTAssertTrue(filter.canLog(withNamespace: "Auth", logLevel: .debug, userIdentifier: "user1"))
    }

    /// Given: logging constraints with user-level overrides
    /// When: canLog is called with a user that has a namespace override
    /// Then: canLog uses the user+namespace-level constraints
    func testUserNamespaceLevelOverride() {
        XCTAssertTrue(filter.canLog(withNamespace: "Auth", logLevel: .debug, userIdentifier: "user1"))
        XCTAssertFalse(filter.canLog(withNamespace: "Auth", logLevel: .verbose, userIdentifier: "user1"))
    }

    /// Given: logging constraints with user-level overrides
    /// When: canLog is called with a user that has no namespace override
    /// Then: canLog falls back to user default level
    func testUserDefaultLevelFallback() {
        XCTAssertTrue(filter.canLog(withNamespace: "Storage", logLevel: .warn, userIdentifier: "user2"))
        XCTAssertFalse(filter.canLog(withNamespace: "Storage", logLevel: .info, userIdentifier: "user2"))
    }

    /// Given: logging constraints
    /// When: canLog is called with .none log level
    /// Then: canLog always returns false
    func testNoneLogLevelAlwaysBlocked() {
        XCTAssertFalse(filter.canLog(withNamespace: nil, logLevel: .none, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withNamespace: "Storage", logLevel: .none, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withNamespace: nil, logLevel: .none, userIdentifier: "user1"))
    }

    /// Given: logging constraints
    /// When: getDefaultLogLevel is called for a namespace
    /// Then: the correct log level is returned
    func testGetDefaultLogLevelForNamespace() {
        XCTAssertEqual(filter.getDefaultLogLevel(forNamespace: "Storage", userIdentifier: nil), .warn)
        XCTAssertEqual(filter.getDefaultLogLevel(forNamespace: "API", userIdentifier: nil), .info)
        XCTAssertEqual(filter.getDefaultLogLevel(forNamespace: nil, userIdentifier: nil), .error)
    }

    /// Given: logging constraints with user-level overrides
    /// When: getDefaultLogLevel is called for a user
    /// Then: the user-level default is returned
    func testGetDefaultLogLevelForUser() {
        XCTAssertEqual(filter.getDefaultLogLevel(forNamespace: nil, userIdentifier: "user1"), .info)
        XCTAssertEqual(filter.getDefaultLogLevel(forNamespace: "Auth", userIdentifier: "user1"), .debug)
    }

    /// Given: logging constraints
    /// When: loggingConstraints is updated
    /// Then: canLog reflects the new constraints
    func testLoggingConstraintsCanBeUpdated() {
        XCTAssertFalse(filter.canLog(withNamespace: nil, logLevel: .verbose, userIdentifier: nil))
        filter.loggingConstraints = LoggingConstraints(defaultLogLevel: .verbose)
        XCTAssertTrue(filter.canLog(withNamespace: nil, logLevel: .verbose, userIdentifier: nil))
    }
}
