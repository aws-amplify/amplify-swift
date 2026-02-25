//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol Logger {
    /// Logs a message at `error` level
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)

    /// Logs a message at `warn` level
    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)

    /// Logs a message at `info` level
    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)

    /// Logs a message at `debug` level
    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)

    /// Logs a message at `verbose` level
    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
    
    /// Logs a message at the given level
    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?)
}

/// An enumeration of the different levels of logging.
/// The levels are progressive, with lower-value items being higher priority
/// than higher-value items. For example, `info` is lower priority than `warn`
/// or `error`. At a given level, only log messages of higher level(lower in value) are allowed.
public enum LogLevel: Int {
    case none
    case error
    case warn
    case info
    case debug
    case verbose
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension Logger {
    func error(_ message: @autoclosure () -> String) {
        error(message(), nil)
    }
      
    func warn(_ message: @autoclosure () -> String) {
        warn(message(), nil)
    }

    func info(_ message: @autoclosure () -> String) {
        info(message(), nil)
    }

    func debug(_ message: @autoclosure () -> String) {
        debug(message(), nil)
    }

    func verbose(_ message: @autoclosure () -> String) {
        verbose(message(), nil)
    }
    
    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String) {
        log(logLevel, message(), nil)
    }
}

