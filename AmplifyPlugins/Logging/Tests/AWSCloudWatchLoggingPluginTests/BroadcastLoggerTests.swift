//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify

final class BroadcastLoggerTests: XCTestCase {
    
    var systemUnderTest: BroadcastLogger!
    var mockLogger1: MockLogger!
    var mockLogger2: MockLogger!
    override func setUp() async throws {
        mockLogger1 = MockLogger()
        mockLogger2 = MockLogger()
        systemUnderTest = BroadcastLogger(targets: [mockLogger1, mockLogger2])
    }
    
    override func tearDown() async throws {
        mockLogger1 = nil
        mockLogger2 = nil
        systemUnderTest = nil
    }
    
    /// Given: broadcast logger
    /// When: an error message is logged
    /// Then: the same error message is broadcasted to all underlying loggers
    func testBroadcastErrorLog() {
        XCTAssertEqual(mockLogger1.entries.count, 0)
        XCTAssertEqual(mockLogger2.entries.count, 0)
        
        let message = "Error message"
        systemUnderTest.error(message)
        
        XCTAssertEqual(mockLogger1.entries.count, 1)
        XCTAssertEqual(mockLogger2.entries.count, 1)
        XCTAssertEqual(mockLogger1.entries[0].level, .error)
        XCTAssertEqual(mockLogger2.entries[0].level, .error)
        XCTAssertEqual(mockLogger1.entries[0].message, message)
        XCTAssertEqual(mockLogger2.entries[0].message, message)
    }
    
    /// Given: broadcast logger
    /// When: a warn message is logged
    /// Then: the same warn message is broadcasted to all underlying loggers
    func testBroadcastWarnLog() {
        XCTAssertEqual(mockLogger1.entries.count, 0)
        XCTAssertEqual(mockLogger2.entries.count, 0)
        
        let message = "Warn message"
        systemUnderTest.warn(message)
        
        XCTAssertEqual(mockLogger1.entries.count, 1)
        XCTAssertEqual(mockLogger2.entries.count, 1)
        XCTAssertEqual(mockLogger1.entries[0].level, .warn)
        XCTAssertEqual(mockLogger2.entries[0].level, .warn)
        XCTAssertEqual(mockLogger1.entries[0].message, message)
        XCTAssertEqual(mockLogger2.entries[0].message, message)
    }
    
    /// Given: broadcast logger
    /// When: a debug message is logged
    /// Then: the same debug message is broadcasted to all underlying loggers
    func testBroadcastDebugLog() {
        XCTAssertEqual(mockLogger1.entries.count, 0)
        XCTAssertEqual(mockLogger2.entries.count, 0)
        
        let message = "Debug message"
        systemUnderTest.debug(message)
        
        XCTAssertEqual(mockLogger1.entries.count, 1)
        XCTAssertEqual(mockLogger2.entries.count, 1)
        XCTAssertEqual(mockLogger1.entries[0].level, .debug)
        XCTAssertEqual(mockLogger2.entries[0].level, .debug)
        XCTAssertEqual(mockLogger1.entries[0].message, message)
        XCTAssertEqual(mockLogger2.entries[0].message, message)
    }
    
    /// Given: broadcast logger
    /// When: an info message is logged
    /// Then: the same info message is broadcasted to all underlying loggers
    func testBroadcastInfoLog() {
        XCTAssertEqual(mockLogger1.entries.count, 0)
        XCTAssertEqual(mockLogger2.entries.count, 0)
        
        let message = "Info message"
        systemUnderTest.info(message)
        
        XCTAssertEqual(mockLogger1.entries.count, 1)
        XCTAssertEqual(mockLogger2.entries.count, 1)
        XCTAssertEqual(mockLogger1.entries[0].level, .info)
        XCTAssertEqual(mockLogger2.entries[0].level, .info)
        XCTAssertEqual(mockLogger1.entries[0].message, message)
        XCTAssertEqual(mockLogger2.entries[0].message, message)
    }
    
    /// Given: broadcast logger
    /// When: a verbose message is logged
    /// Then: the same verbose message is broadcasted to all underlying loggers
    func testBroadcastVerboseLog() {
        XCTAssertEqual(mockLogger1.entries.count, 0)
        XCTAssertEqual(mockLogger2.entries.count, 0)
        
        let message = "Verbose message"
        systemUnderTest.verbose(message)
        
        XCTAssertEqual(mockLogger1.entries.count, 1)
        XCTAssertEqual(mockLogger2.entries.count, 1)
        XCTAssertEqual(mockLogger1.entries[0].level, .verbose)
        XCTAssertEqual(mockLogger2.entries[0].level, .verbose)
        XCTAssertEqual(mockLogger1.entries[0].message, message)
        XCTAssertEqual(mockLogger2.entries[0].message, message)
    }
    
    /// Given: a broadcast logger
    /// When: log level is modified
    /// Then: all underlying logger log levels are modified
    func testBroadcastLogLevelModified() {
        XCTAssertEqual(mockLogger1.logLevel, .error)
        XCTAssertEqual(mockLogger2.logLevel, .error)
        systemUnderTest.logLevel = .verbose
        XCTAssertEqual(mockLogger1.logLevel, .verbose)
        XCTAssertEqual(mockLogger2.logLevel, .verbose)
    }
}
