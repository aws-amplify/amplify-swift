//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyFoundation
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the plugin's engine log router. `Amplify.Logging` is replaced by a
/// recording fake throughout, so no test touches the global logging category.
class AmplifyEngineLogRouterTests: XCTestCase {

    /// - Given: The plugin's scope
    /// - When: It is compared with what `AWSCognitoAuthPlugin.log` resolves
    /// - Then: It is the same category and namespace
    ///
    func testPluginScopeMatchesPluginLog() {
        XCTAssertEqual(
            AmplifyEngineLogRouter.pluginScope,
            .categoryNamespace(CategoryType.auth.displayName, String(describing: AWSCognitoAuthPlugin.self))
        )
        XCTAssertEqual(AmplifyEngineLogRouter().scope, AmplifyEngineLogRouter.pluginScope)
    }

    /// - Given: Each scope
    /// - When: It is resolved against a recording logging category
    /// - Then: It calls the `Amplify.Logging` method the plugin's log sites call today, with the same arguments
    ///
    func testScopeResolvesToTheMatchingAmplifyLoggingCall() {
        let logging = RecordingLoggingCategory()

        _ = AmplifyEngineLogRouter.amplifyLogger(for: .category("AuthFactorType"), in: logging)
        _ = AmplifyEngineLogRouter.amplifyLogger(for: .categoryNamespace("Authentication", "InitiateAuthSRP"), in: logging)
        _ = AmplifyEngineLogRouter.amplifyLogger(for: .namespace("KeychainStore"), in: logging)

        XCTAssertEqual(logging.calls, [
            "logger(forCategory: AuthFactorType)",
            "logger(forCategory: Authentication, forNamespace: InitiateAuthSRP)",
            "logger(forNamespace: KeychainStore)"
        ])
    }

    /// - Given: A router whose resolver counts calls
    /// - When: It logs three messages
    /// - Then: The Amplify logger is resolved once per message, never cached
    ///
    func testResolvesAmplifyLoggerPerMessage() {
        let sink = RecordingAmplifyLogger()
        let resolutions = ScopeRecorder()
        let router = AmplifyEngineLogRouter(scope: .namespace("n")) { scope in
            resolutions.append(scope)
            return sink
        }

        router.info("a")
        router.info("b")
        router.debug("c")

        XCTAssertEqual(resolutions.scopes, [.namespace("n"), .namespace("n"), .namespace("n")])
    }

    /// - Given: A router
    /// - When: It logs at every Foundation level
    /// - Then: Each maps 1:1 onto the Amplify level, `.none` logs nothing, and an error is appended to the message
    ///
    func testLevelMapping() {
        let sink = RecordingAmplifyLogger()
        let router = AmplifyEngineLogRouter(scope: .category("c")) { _ in sink }
        let error = NSError(domain: "d", code: 1)

        router.error("e")
        router.warn("w", error)
        router.info("i", error)
        router.debug("d", error)
        router.verbose("v", error)
        router.log(.none, "none", nil)
        router.log(.error, "le", nil)
        router.log(.warn, "lw", nil)
        router.log(.info, "li", nil)
        router.log(.debug, "ld", nil)
        router.log(.verbose, "lv", nil)

        let suffix = " - \(error.localizedDescription)"
        XCTAssertEqual(sink.lines, [
            "error: e", "warn: w\(suffix)", "info: i\(suffix)", "debug: d\(suffix)", "verbose: v\(suffix)",
            "error: le", "warn: lw", "info: li", "debug: ld", "verbose: lv"
        ])
    }

    /// - Given: A router
    /// - When: `error` is called with an empty message and an error, with a message and an error, and with a message only
    /// - Then: Only the first becomes Amplify's `error(error:)`; a message with an error logs both, as one line
    ///
    func testErrorForwarding() {
        let sink = RecordingAmplifyLogger()
        let router = AmplifyEngineLogRouter(scope: .category("c")) { _ in sink }
        let error = NSError(domain: "d", code: 1)

        router.error("", error)
        router.error("message", error)
        router.error("message only")
        router.log(.error, "", error)

        XCTAssertEqual(sink.lines, [
            "error(error:): \(error)",
            "error: message - \(error.localizedDescription)",
            "error: message only",
            "error(error:): \(error)"
        ])
    }

    /// - Given: A router whose Amplify logger never evaluates messages (a disabled level)
    /// - When: It logs without an error
    /// - Then: The message is not evaluated, as with the plugin's `log` today
    ///
    func testMessagesStayLazy() {
        let sink = RecordingAmplifyLogger(evaluates: false)
        let router = AmplifyEngineLogRouter(scope: .category("c")) { _ in sink }
        let evaluations = ScopeRecorder()
        func message() -> String {
            evaluations.append(.category("evaluated"))
            return "m"
        }

        router.error(message())
        router.warn(message())
        router.info(message())
        router.debug(message())
        router.verbose(message())

        XCTAssertTrue(evaluations.scopes.isEmpty)
    }

    /// Test that a non-error line carrying an error is not built while the level is off
    ///
    /// - Given: A router whose Amplify logger reports `.none` and never evaluates messages
    /// - When:
    ///    - It logs at every non-error level with a message and an error
    /// - Then:
    ///    - No message is evaluated. (`error` with an error always builds its message: see
    ///      `testErrorWithTheLevelOffStillReachesErrorError`.)
    ///
    func testNonErrorLevelsWithAnErrorStayLazyWhenTheLevelIsOff() {
        let sink = RecordingAmplifyLogger(evaluates: false)
        sink.logLevel = .none
        let router = AmplifyEngineLogRouter(scope: .category("c")) { _ in sink }
        let error = NSError(domain: "d", code: 1)
        let evaluations = ScopeRecorder()
        func message() -> String {
            evaluations.append(.category("evaluated"))
            return "m"
        }

        router.warn(message(), error)
        router.info(message(), error)
        router.debug(message(), error)
        router.verbose(message(), error)
        router.log(.warn, message(), error)

        XCTAssertTrue(evaluations.scopes.isEmpty)
    }

    /// Test that the logger's level never changes which Amplify method an error line reaches
    ///
    /// - Given: A router whose Amplify logger reports `.none` but still records what it is given, as a
    ///   CloudWatch target behind a first target that is off would
    /// - When:
    ///    - It logs an error with a message, an error with an empty message, and the same through `log(.error, …)`
    /// - Then:
    ///    - The empty-message lines reach `error(error:)`, and the message line is one `error(_:)` line
    ///      carrying the error: exactly what it receives at any other level
    ///
    func testErrorWithTheLevelOffStillReachesErrorError() {
        let sink = RecordingAmplifyLogger()
        sink.logLevel = .none
        let router = AmplifyEngineLogRouter(scope: .category("c")) { _ in sink }
        let error = NSError(domain: "d", code: 1)

        router.error("message", error)
        router.error("", error)
        router.log(.error, "", error)

        XCTAssertEqual(sink.lines, [
            "error: message - \(error.localizedDescription)",
            "error(error:): \(error)",
            "error(error:): \(error)"
        ])
    }

    /// Test that the plugin installs its router only over the default
    ///
    /// - Given: A router other than the default is installed
    /// - When:
    ///    - An `AWSCognitoAuthPlugin` is created
    /// - Then:
    ///    - The installed router is left in place
    ///
    func testPluginInitKeepsAnInstalledRouter() {
        let previous = EngineLog.router
        defer { EngineLog.install(previous) }
        let other = CapturingRouter()
        EngineLog.install(other)

        _ = AWSCognitoAuthPlugin()

        XCTAssertTrue(EngineLog.router as? CapturingRouter === other)
    }

    /// - Given: The plugin's router
    /// - When: It hands out a logger for another scope, as a scoped logger and as a router
    /// - Then: The new logger has that scope and the same resolver
    ///
    func testScopedAndLoggerKeepTheResolver() throws {
        let sink = RecordingAmplifyLogger()
        let resolutions = ScopeRecorder()
        let router = AmplifyEngineLogRouter(scope: AmplifyEngineLogRouter.pluginScope) { scope in
            resolutions.append(scope)
            return sink
        }

        let scoped = try XCTUnwrap(router.scoped(.category("MFAType")) as? AmplifyEngineLogRouter)
        let routed = try XCTUnwrap(router.logger(.namespace("KeychainStore")) as? AmplifyEngineLogRouter)
        scoped.info("a")
        routed.info("b")
        router.info("c")

        XCTAssertEqual(scoped.scope, .category("MFAType"))
        XCTAssertEqual(routed.scope, .namespace("KeychainStore"))
        XCTAssertEqual(resolutions.scopes, [.category("MFAType"), .namespace("KeychainStore"), AmplifyEngineLogRouter.pluginScope])
        XCTAssertEqual(sink.lines, ["info: a", "info: b", "info: c"])
    }

    /// - Given: Some other router is installed
    /// - When: An `AWSCognitoAuthPlugin` is created
    /// - Then: The plugin's router, at the plugin's scope, is the global engine router
    ///
    func testPluginInitInstallsTheRouter() throws {
        let previous = EngineLog.router
        defer { EngineLog.install(previous) }
        EngineLog.resetRouter()

        _ = AWSCognitoAuthPlugin()

        let installed = try XCTUnwrap(EngineLog.router as? AmplifyEngineLogRouter)
        XCTAssertEqual(installed.scope, AmplifyEngineLogRouter.pluginScope)
    }
}

// MARK: - Fakes

/// Thread-safe list of scopes, used to count resolutions and evaluations from `@Sendable` closures.
private final class ScopeRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _scopes: [EngineLogScope] = []

    var scopes: [EngineLogScope] {
        lock.withLock { _scopes }
    }

    func append(_ scope: EngineLogScope) {
        lock.withLock { _scopes.append(scope) }
    }
}

/// An `Amplify.Logger` that records what it is asked to log.
private final class RecordingAmplifyLogger: AmplifyCategoryLogger, @unchecked Sendable {
    private let lock = NSLock()
    private var _lines: [String] = []
    private let evaluates: Bool

    var logLevel: AmplifyCategoryLogLevel = .verbose

    init(evaluates: Bool = true) {
        self.evaluates = evaluates
    }

    var lines: [String] {
        lock.withLock { _lines }
    }

    private func record(_ level: String, _ message: () -> String) {
        guard evaluates else { return }
        let line = "\(level): \(message())"
        lock.withLock { _lines.append(line) }
    }

    func error(_ message: @autoclosure () -> String) {
        record("error", message)
    }

    func error(error: Error) {
        record("error(error:)") { "\(error)" }
    }

    func warn(_ message: @autoclosure () -> String) {
        record("warn", message)
    }

    func info(_ message: @autoclosure () -> String) {
        record("info", message)
    }

    func debug(_ message: @autoclosure () -> String) {
        record("debug", message)
    }

    func verbose(_ message: @autoclosure () -> String) {
        record("verbose", message)
    }
}

/// A logging category that records which `logger(…)` call was made.
private final class RecordingLoggingCategory: LoggingCategoryClientBehavior, @unchecked Sendable {
    private(set) var calls: [String] = []
    private let logger = RecordingAmplifyLogger()

    var `default`: any AmplifyCategoryLogger {
        calls.append("default")
        return logger
    }

    func logger(forCategory category: String, logLevel: AmplifyCategoryLogLevel) -> any AmplifyCategoryLogger {
        calls.append("logger(forCategory: \(category), logLevel: \(logLevel))")
        return logger
    }

    func logger(forCategory category: String) -> any AmplifyCategoryLogger {
        calls.append("logger(forCategory: \(category))")
        return logger
    }

    func enable() {}

    func disable() {}

    func logger(forNamespace namespace: String) -> any AmplifyCategoryLogger {
        calls.append("logger(forNamespace: \(namespace))")
        return logger
    }

    func logger(forCategory category: String, forNamespace namespace: String) -> any AmplifyCategoryLogger {
        calls.append("logger(forCategory: \(category), forNamespace: \(namespace))")
        return logger
    }
}
