//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LoggerProxyTests: XCTestCase {
    
    var systemUnderTest: LoggerProxy!
    var loggers: [MockLogger]!
    
    override func setUp() async throws {
        self.loggers = [
            MockLogger(),
            MockLogger(),
            MockLogger(),
            MockLogger(),
            MockLogger(),
        ]
        self.systemUnderTest = LoggerProxy(targets: self.loggers)
    }
    
    override func tearDown() async throws {
        self.loggers = nil
        self.systemUnderTest = nil
    }
    
    func testDefaultState() {
        XCTAssertEqual(systemUnderTest.logLevel, .error)
        for logger in loggers {
            XCTAssertEqual(logger.logLevel, .error)
            XCTAssertEqual(logger.entries, [])
        }
    }
    
    func testLogLevelDependsOnFirstLoger() throws {
        let first = try XCTUnwrap(self.loggers.first)
        let last = try XCTUnwrap(self.loggers.last)
        
        XCTAssertEqual(systemUnderTest.logLevel, .error)
        XCTAssertEqual(systemUnderTest.logLevel, first.logLevel)
        XCTAssertEqual(systemUnderTest.logLevel, last.logLevel)
        
        first.logLevel = .debug
        XCTAssertEqual(systemUnderTest.logLevel, .debug)
        XCTAssertEqual(systemUnderTest.logLevel, first.logLevel)
        XCTAssertNotEqual(systemUnderTest.logLevel, last.logLevel)
        
        systemUnderTest.logLevel = .info
        XCTAssertEqual(systemUnderTest.logLevel, .info)
        XCTAssertEqual(systemUnderTest.logLevel, first.logLevel)
        XCTAssertEqual(systemUnderTest.logLevel, last.logLevel)
    }
    
    func testLogError() {
        struct TestError: Error, CustomStringConvertible {
            var message: String
            var description: String {
                return "TestError.\(message)"
            }
        }
        let errors = createRandomMessages().map { TestError(message: $0) }
        for currentError in errors {
            systemUnderTest.error(error: currentError)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, errors.map { MockLogger.Entry(level: .error, message: $0.description) })
        }
    }
    
    func testLogErrorMessage() {
        let messages = createRandomMessages()
        for message in messages {
            systemUnderTest.error(message)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, messages.map { MockLogger.Entry(level: .error, message: $0) })
        }
    }
    
    func testLogWarn() {
        let messages = createRandomMessages()
        for message in messages {
            systemUnderTest.warn(message)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, messages.map { MockLogger.Entry(level: .warn, message: $0) })
        }
    }
    
    func testLogInfo() {
        let messages = createRandomMessages()
        for message in messages {
            systemUnderTest.info(message)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, messages.map { MockLogger.Entry(level: .info, message: $0) })
        }
    }
    
    func testLogDebug() {
        let messages = createRandomMessages()
        for message in messages {
            systemUnderTest.debug(message)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, messages.map { MockLogger.Entry(level: .debug, message: $0) })
        }
    }
    
    func testLogVerbose() {
        let messages = createRandomMessages()
        for message in messages {
            systemUnderTest.verbose(message)
        }
        for logger in loggers {
            XCTAssertEqual(logger.entries, messages.map { MockLogger.Entry(level: .verbose, message: $0) })
        }
    }
    
    func testEmptyTargetList() {
        let sut = LoggerProxy(targets: [])
        XCTAssertEqual(sut.logLevel, sut.defaultLogLevel)
    }
    
    func createRandomMessages() -> [String] {
        var result: [String] = []
        for _ in 0..<Int.random(in: 5..<11) {
            result.append(UUID().uuidString)
        }
        return result
    }
    
}
