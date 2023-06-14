//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Test-friendly implementation of Amplify's [Logger](x-source-tag://Logger)
/// protocol.
///
/// - Tag: MockLogger
final class MockLogger {
    struct Entry: Equatable {
        var level: LogLevel
        var message: String
    }
    var logLevel: Amplify.LogLevel = .error
    var entries: [Entry] = []
}

extension MockLogger: Logger {
    
    func error(_ message: @autoclosure () -> String) {
        entries.append(Entry(level: .error, message: message()))
    }
    
    func error(error: Error) {
        entries.append(Entry(level: .error, message: String(describing: error)))
    }
    
    func warn(_ message: @autoclosure () -> String) {
        entries.append(Entry(level: .warn, message: message()))
    }
    
    func info(_ message: @autoclosure () -> String) {
        entries.append(Entry(level: .info, message: message()))
    }
    
    func debug(_ message: @autoclosure () -> String) {
        entries.append(Entry(level: .debug, message: message()))
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        entries.append(Entry(level: .verbose, message: message()))
    }
}
