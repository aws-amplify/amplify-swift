//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Test-friendly implementation of the Amplify
/// [Logger](x-source-tag://Logger)
/// protocol.
///
/// - Tag: MockLogger
final class MockLogger {
    struct Entry: Equatable {
        var level: Amplify.LogLevel
        var message: String
    }
    var logLevel: Amplify.LogLevel = .debug
    var entries: [Entry] = []
}

extension MockLogger: Logger {

    func error(_ message: @autoclosure () -> String) {
        entries.append(.init(level: .error, message: message()))
    }
    
    func error(error: Error) {
        entries.append(.init(level: .error, message: "\(error)"))
    }
    
    func warn(_ message: @autoclosure () -> String) {
        entries.append(.init(level: .warn, message: message()))
    }
    
    func info(_ message: @autoclosure () -> String) {
        entries.append(.init(level: .info, message: message()))
    }
    
    func debug(_ message: @autoclosure () -> String) {
        entries.append(.init(level: .debug, message: message()))
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        entries.append(.init(level: .verbose, message: message()))
    }
    
}
