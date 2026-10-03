//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the engine's global log router. Nothing in the engine logs through it yet.
class EngineLogTests: XCTestCase {

    private var previousRouter: (any EngineLogRouter)?

    override func setUp() {
        super.setUp()
        previousRouter = EngineLog.router
    }

    override func tearDown() {
        if let previousRouter {
            EngineLog.install(previousRouter)
        }
        super.tearDown()
    }

    /// - Given: The default router
    /// - When: Each scope is mapped to an `AmplifyLogging` name
    /// - Then: A category logs under the category, and a namespace under the namespace
    ///
    func testFoundationRouterNames() {
        XCTAssertEqual(FoundationEngineLogRouter.name(for: .category("AuthFactorType")), "AuthFactorType")
        XCTAssertEqual(
            FoundationEngineLogRouter.name(for: .categoryNamespace("Authentication", "InitiateAuthSRP")),
            "InitiateAuthSRP"
        )
        XCTAssertEqual(FoundationEngineLogRouter.name(for: .namespace("KeychainStore")), "KeychainStore")
    }

    /// - Given: The router is reset
    /// - When: The installed router is read
    /// - Then: It is the Foundation router
    ///
    func testResetRestoresFoundationRouter() {
        EngineLog.install(CapturingRouter())
        EngineLog.resetRouter()
        XCTAssertTrue(EngineLog.router is FoundationEngineLogRouter)
    }

    /// Test the ordering rule: a host's router replaces only the default
    ///
    /// - Given: The default router
    /// - When:
    ///    - A first router is installed with `installIfDefault`, then a second
    /// - Then:
    ///    - The first is installed and stays installed, and the second call reports that it did nothing
    ///
    func testInstallIfDefaultReplacesOnlyTheDefault() {
        EngineLog.resetRouter()
        let first = CapturingRouter()
        let second = CapturingRouter()

        XCTAssertTrue(EngineLog.installIfDefault(first))
        XCTAssertFalse(EngineLog.installIfDefault(second))

        XCTAssertTrue(EngineLog.router as? CapturingRouter === first)
        EngineLog.logger(.category("c")).info("m")
        XCTAssertEqual(first.entries.map(\.message), ["m"])
        XCTAssertTrue(second.entries.isEmpty)
    }

    /// - Given: A capturing router is installed
    /// - When: A scoped logger logs at every level
    /// - Then: Each message reaches the router with its scope, level and error
    ///
    func testLoggerForwardsScopeLevelMessageAndError() {
        let router = CapturingRouter()
        EngineLog.install(router)
        let logger = EngineLog.logger(.category("AuthFactorType"))
        let error = NSError(domain: "test", code: 7)

        logger.error("e", error)
        logger.warn("w")
        logger.info("i")
        logger.debug("d")
        logger.verbose("v")
        logger.log(.warn, "l", nil)

        XCTAssertEqual(router.entries.map(\.scope), Array(repeating: .category("AuthFactorType"), count: 6))
        XCTAssertEqual(router.entries.map(\.level), [.error, .warn, .info, .debug, .verbose, .warn])
        XCTAssertEqual(router.entries.map(\.message), ["e", "w", "i", "d", "v", "l"])
        XCTAssertEqual(router.entries.map(\.hasError), [true, false, false, false, false, false])
    }

    /// - Given: A logger obtained before a router is installed
    /// - When: Routers are installed after it was obtained, and it logs
    /// - Then: Each message goes to the router installed at the time of the message
    ///
    func testLoggerResolvesRouterPerMessage() {
        let logger = EngineLog.logger(.namespace("KeychainStore"))
        let first = CapturingRouter()
        let second = CapturingRouter()

        EngineLog.install(first)
        logger.info("one")
        EngineLog.install(second)
        logger.info("two")

        XCTAssertEqual(first.entries.map(\.message), ["one"])
        XCTAssertEqual(second.entries.map(\.message), ["two"])
    }
}

/// Records every message, with the scope it was resolved for.
final class CapturingRouter: EngineLogRouter, @unchecked Sendable {

    struct Entry: Equatable {
        let scope: EngineLogScope
        let level: AmplifyFoundation.LogLevel
        let message: String
        let hasError: Bool
    }

    private let lock = NSLock()
    private var _entries: [Entry] = []

    var entries: [Entry] {
        lock.withLock { _entries }
    }

    func logger(_ scope: EngineLogScope) -> EngineLogger {
        CapturingLogger(scope: scope, router: self)
    }

    fileprivate func append(_ entry: Entry) {
        lock.withLock { _entries.append(entry) }
    }

    /// A caller's logger over this router: each scope it is asked for is recorded under that scope, and its
    /// own lines under `scope`. What a site that takes its caller's logger is given in a test.
    func scopedLogger(at scope: EngineLogScope = .category("Caller")) -> any EngineScopedLogger {
        CapturingScopedLogger(scope: scope, router: self)
    }
}

/// `CapturingRouter.scopedLogger(at:)`.
private struct CapturingScopedLogger: EngineScopedLogger {
    let scope: EngineLogScope
    let router: CapturingRouter

    func scoped(_ scope: EngineLogScope) -> EngineLogger {
        router.logger(scope)
    }

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).error(message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).warn(message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).info(message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).debug(message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).verbose(message(), error())
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).log(logLevel, message(), error())
    }
}

private struct CapturingLogger: AmplifyFoundation.Logger {
    let scope: EngineLogScope
    let router: CapturingRouter

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.error, message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.warn, message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.info, message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.debug, message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.verbose, message(), error())
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.append(.init(scope: scope, level: logLevel, message: message(), hasError: error() != nil))
    }
}
