//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// This class acts as a layer of indirection conforming to Logger
/// protocol that delegates all work to its sinks.
///
final class BroadcastLogger {
    
    let sinks: [any LogSinkBehavior]
    let name: String

    init(name: String, sinks: [any LogSinkBehavior]) {
        self.name = name
        self.sinks = sinks
    }
}

extension BroadcastLogger: Logger {
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        log(.error, message(), error())
    }
    
    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        log(.warn, message(), error())
    }
    
    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        log(.info, message(), error())
    }
    
    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        log(.debug, message(), error())
    }
    
    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        log(.verbose, message(), error())
    }
    
    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> (any Error)?) {
        sinks.forEach { sink in
            if sink.isEnabled(for: logLevel) {
                sink.emit(message: .init(level: logLevel, name: name, content: message(), error: error()))
            }
        }
    }
}
