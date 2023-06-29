//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LogEntryTests: XCTestCase {
    
    let levels = [
        LogLevel.error,
        LogLevel.warn,
        LogLevel.info,
        LogLevel.debug,
        LogLevel.verbose
    ]
    
    func testLogEntryAttributesAreSet() {
        for level in levels {
            let message = UUID().uuidString
            let sut = LogEntry(category: "LogEntryTests", namespace: nil, level: level, message: message)
            XCTAssertNotNil(sut.created)
            XCTAssertEqual(sut.message, message)
            XCTAssertEqual(sut.logLevel, level)
        }
    }
    
    func testLogEntryIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for level in levels {
            let message = UUID().uuidString
            let sut = LogEntry(category: "LogEntryTests", namespace: nil, level: level, message: message)
            let encoded = try encoder.encode(sut)
            let decoded = try decoder.decode(LogEntry.self, from: encoded)
            XCTAssertEqual(decoded.created, sut.created)
            XCTAssertEqual(decoded.message, message)
            XCTAssertEqual(decoded.logLevel, level)
        }
    }
    
    func testDecodeDefaultsLogLevelWithInvalidLogLevel() throws {
        let message = UUID().uuidString
        let json = """
        {
            "created": 0,
            "category": "LogEntryTests",
            "level": -1337,
            "message": "\(message)"
        }
        """
        let encoded = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(LogEntry.self, from: encoded)
        XCTAssertEqual(decoded.created, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(decoded.message, message)
        XCTAssertEqual(decoded.logLevel, LogLevel.error)
    }
}
