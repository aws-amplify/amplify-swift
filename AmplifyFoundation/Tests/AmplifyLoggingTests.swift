//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyFoundation

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AmplifyLoggingTests: XCTestCase, @unchecked Sendable {
    var logSink: MockLogSink!

    override func setUp() {
        logSink = MockLogSink()
    }

    override func tearDown() {
        AmplifyLogging.removeSink(logSink)
    }

    /// - Given: no registered log sinks
    /// - When: a sink is added
    /// - Then:
    ///    - one sink is registered
    func testAmplifyLoggingSinkAddedSuccess() {
        AmplifyLogging.addSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 1)
    }

    /// - Given: one registered log sink
    /// - When: it is removed
    /// - Then:
    ///    - no sink is registered
    func testAmplifyLoggingSinkRemovedSuccess() {
        AmplifyLogging.addSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 1)

        AmplifyLogging.removeSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 0)
    }

    /// - Given: a registered sink at the debug level
    /// - When: a logger for `testCategory` logs a debug message
    /// - Then:
    ///    - the sink receives one message with that category, level and content
    func testLogMessageSuccess() {
        logSink.logLevel = .debug
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        let message = "Hello World"
        logger.debug(message, nil)

        XCTAssertEqual(logSink.logMessages.count, 1)
        XCTAssertEqual(logSink.logMessages[0].name, "testCategory")
        XCTAssertEqual(logSink.logMessages[0].level, LogLevel.debug)
        XCTAssertEqual(logSink.logMessages[0].content, message)
    }

    /// - Given: a registered sink at the default (debug) level
    /// - When: a logger logs a debug message and then an error message with an error
    /// - Then:
    ///    - the sink receives both, in order, with their levels and content, and the error message carries
    ///      the error with its description and recovery suggestion
    func testMultipleLogMessageSuccess() {
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        let debugMessage = "Debug Message"
        logger.debug(debugMessage, nil)

        let errorMessage = "Error Message"
        logger.error(errorMessage, MockAmplifyError.defaultError())

        XCTAssertEqual(logSink.logMessages.count, 2)
        XCTAssertEqual(logSink.logMessages[0].name, "testCategory")
        XCTAssertEqual(logSink.logMessages[0].level, LogLevel.debug)
        XCTAssertEqual(logSink.logMessages[0].content, debugMessage)

        XCTAssertEqual(logSink.logMessages[1].name, "testCategory")
        XCTAssertEqual(logSink.logMessages[1].level, LogLevel.error)
        XCTAssertEqual(logSink.logMessages[1].content, errorMessage)

        guard let error = logSink.logMessages[1].error as? MockAmplifyError else {
            XCTFail("Error type should be of AmplifyError")
            return
        }
        XCTAssertEqual(error.errorDescription, "defaultError")
        XCTAssertEqual(error.recoverySuggestion, "defaultSuggestion")
    }

    /// - Given: a registered sink at the error level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives one message: error, in that order
    func testErrorThresholdForLogging() {
        logSink.logLevel = .error
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 1)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
    }

    /// - Given: a registered sink at the warn level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives two messages: error and warn, in that order
    func testWarnThresholdForLogging() {
        logSink.logLevel = .warn
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 2)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
    }

    /// - Given: a registered sink at the info level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives three messages: error, warn and info, in that order
    func testInfoThresholdForLogging() {
        logSink.logLevel = .info
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 3)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
    }

    /// - Given: a registered sink at the debug level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives four messages: error, warn, info and debug, in that order
    func testDebugThresholdForLogging() {
        logSink.logLevel = .debug
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 4)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
        XCTAssertEqual(logSink.logMessages[3].level, .debug)
    }

    /// - Given: a registered sink at the verbose level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives all five messages: error, warn, info, debug and verbose, in that order
    func testVerboseThresholdForLogging() {
        logSink.logLevel = .verbose
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 5)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
        XCTAssertEqual(logSink.logMessages[3].level, .debug)
        XCTAssertEqual(logSink.logMessages[4].level, .verbose)
    }

    /// - Given: a registered sink at the `none` level
    /// - When: a logger logs one message at each level, from error to verbose
    /// - Then:
    ///    - the sink receives nothing
    func testNoneThresholdForLogging() {
        logSink.logLevel = .none
        AmplifyLogging.addSink(logSink)

        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage")
        logger.warn("warnMessage")
        logger.info("infoMessage")
        logger.debug("debugMessage")
        logger.verbose("verboseMessage")

        XCTAssertEqual(logSink.logMessages.count, 0)
    }

    /// - Given: a registered sink and a logger created from it
    /// - When: a second sink is added and the logger then logs a debug message
    /// - Then:
    ///    - the first sink receives it and the second does not: a logger keeps the sinks it was created with
    func testSinkAddedAfterLoggerCreatedShouldNotReceiveLogs() {
        AmplifyLogging.addSink(logSink) // .debug log level
        let logger = AmplifyLogging.logger(for: "testCategory")

        let newSink = MockLogSink() // .debug log level
        AmplifyLogging.addSink(newSink)

        logger.debug("debugMessage")
        XCTAssertEqual(logSink.logMessages.count, 1)
        XCTAssertEqual(newSink.logMessages.count, 0)
    }

    /// - Given: two registered sinks at the debug level, and a logger created after both
    /// - When: the logger logs a debug message
    /// - Then:
    ///    - each sink receives it once
    func testMultipleSinksLogMessageSuccess() {
        AmplifyLogging.addSink(logSink) // .debug log level

        let newSink = MockLogSink() // .debug log level
        AmplifyLogging.addSink(newSink)
        let logger = AmplifyLogging.logger(for: "testCategory")

        logger.debug("debugMessage")
        XCTAssertEqual(logSink.logMessages.count, 1)
        XCTAssertEqual(newSink.logMessages.count, 1)
    }

    /// - Given: one registered sink at the debug level and one at the verbose level, and a logger created after
    ///   both
    /// - When: the logger logs a verbose message
    /// - Then:
    ///    - only the verbose sink receives it
    func testMultipleSinksWithDifferentLogLevels() {
        AmplifyLogging.addSink(logSink) // .debug log level

        let newSink = MockLogSink()
        newSink.logLevel = .verbose // .verbose log level
        AmplifyLogging.addSink(newSink)

        let logger = AmplifyLogging.logger(for: "testCategory")

        logger.verbose("verboseMessage")
        XCTAssertEqual(logSink.logMessages.count, 0)
        XCTAssertEqual(newSink.logMessages.count, 1)
    }
}


/// Mock LogSink for testing which stores the list of log messages in memory
/// - Note: `@unchecked Sendable`: `LogSinkBehavior` is `Sendable`. This test double is written and
///   read from a single test.
final class MockLogSink: LogSinkBehavior, @unchecked Sendable {
    let id: String = UUID().uuidString
    var logLevel: LogLevel = .debug
    var logMessages: [LogMessage] = []

    init() { }

    func isEnabled(for logLevel: AmplifyFoundation.LogLevel) -> Bool {
        return logLevel <= self.logLevel
    }

    func emit(message: AmplifyFoundation.LogMessage) {
        if isEnabled(for: message.level) {
            logMessages.append(message)
        }
    }
}

final class MockAmplifyError: AmplifyError {
    let errorDescription: ErrorDescription
    let recoverySuggestion: RecoverySuggestion
    let underlyingError: Error?

    required init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: (any Error)?) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }

    static func defaultError() -> Self {
        return .init(
            errorDescription: "defaultError",
            recoverySuggestion: "defaultSuggestion",
            error: MockError.defaultError)
    }
}

enum MockError: Error {
     case defaultError
}
