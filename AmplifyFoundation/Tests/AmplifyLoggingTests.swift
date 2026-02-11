//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyFoundation

class AmplifyLoggingTests: XCTestCase {
    var logSink: MockLogSink!
    
    override func setUp() {
        logSink = MockLogSink()
    }
    
    func testAmplifyLoggingSinkAddedSuccess() {
        AmplifyLogging.addSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 1)
    }
    
    func testAmplifyLoggingSinkRemovedSuccess() {
        AmplifyLogging.addSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 1)
        
        AmplifyLogging.removeSink(logSink)
        XCTAssertEqual(AmplifyLogging.registeredLogSinks.keys.count, 0)
    }
    
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
    
    func testErrorThresholdForLogging() {
        logSink.logLevel = .error
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 1)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
    }
    
    func testWarnThresholdForLogging() {
        logSink.logLevel = .warn
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 2)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
    }
    
    func testInfoThresholdForLogging() {
        logSink.logLevel = .info
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 3)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
    }
    
    func testDebugThresholdForLogging() {
        logSink.logLevel = .debug
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 4)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
        XCTAssertEqual(logSink.logMessages[3].level, .debug)
    }
    
    func testVerboseThresholdForLogging() {
        logSink.logLevel = .verbose
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 5)
        XCTAssertEqual(logSink.logMessages[0].level, .error)
        XCTAssertEqual(logSink.logMessages[1].level, .warn)
        XCTAssertEqual(logSink.logMessages[2].level, .info)
        XCTAssertEqual(logSink.logMessages[3].level, .debug)
        XCTAssertEqual(logSink.logMessages[4].level, .verbose)
    }
    
    func testNoneThresholdForLogging() {
        logSink.logLevel = .none
        AmplifyLogging.addSink(logSink)
        
        let logger = AmplifyLogging.logger(for: "testCategory")
        logger.error("errorMessage", nil)
        logger.warn("warnMessage", nil)
        logger.info("infoMessage", nil)
        logger.debug("debugMessage", nil)
        logger.verbose("verboseMessage", nil)
        
        XCTAssertEqual(logSink.logMessages.count, 0)
    }
    
    
}


/// Mock LogSink for testing which stores the list of log messages in memory
class MockLogSink : LogSinkBehavior {
    var id: String = "MockLogSink"
    var logLevel: LogLevel = .debug
    var logMessages: [LogMessage] = []
    
    init() { }
    
    func isEnabled(for logLevel: AmplifyFoundation.LogLevel) -> Bool {
        return logLevel <= self.logLevel
    }
    
    func emit(message: AmplifyFoundation.LogMessage) {
        logMessages.append(message)
    }
}

class MockAmplifyError: AmplifyError {
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
