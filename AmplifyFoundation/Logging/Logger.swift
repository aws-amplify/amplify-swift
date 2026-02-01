//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol FoundationLogger {
    /// namespace
    var namespace: String {get set}

    /// The log level of the logger.
    var logLevel: FoundationLogLevel { get set }

    /// Logs a message at `error` level
    func error(_ message: @autoclosure () -> String)

    /// Logs the error at `error` level
    func error(_ error: @autoclosure () -> Error)

    /// Logs a message at `warn` level
    func warn(_ message: @autoclosure () -> String)

    /// Logs a message at `info` level
    func info(_ message: @autoclosure () -> String)

    /// Logs a message at `debug` level
    func debug(_ message: @autoclosure () -> String)

    /// Logs a message at `verbose` level
    func verbose(_ message: @autoclosure () -> String)
}

public protocol FoundationLoggerProvider {
    func resolve(forNamespace namespace: String) -> FoundationLogger
}

/// An enumeration of the different levels of logging.
/// The levels are progressive, with lower-value items being lower priority
/// than higher-value items. For example, `info` is lower priority than `warn`
/// or `error`.
public enum FoundationLogLevel: Int {
    case error
    case warn
    case info
    case debug
    case verbose
}
