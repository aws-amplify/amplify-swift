//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Class that wraps another `Logger` and saves the logs in memory
class PersistentLogWrapper: Logger {
    var logLevel: LogLevel

    var wrapper: Logger

    /// Array of `LogEntry` containing the history of logs
    private var logHistory: [LogEntryItem] = []

    init(logWrapper: Logger) {
        self.wrapper = logWrapper
        self.logLevel = logWrapper.logLevel
    }

    func error(_ message: @autoclosure () -> String) {
        logHistory.append(LogEntryItem(message: message(), logLevel: .error, timeStamp: Date()))
        wrapper.error(message())
    }

    func warn(_ message: @autoclosure () -> String) {
        logHistory.append(LogEntryItem(message: message(), logLevel: .warn, timeStamp: Date()))
        wrapper.warn(message())
    }

    func error(error: Error) {
        logHistory.append(LogEntryItem(message: error.localizedDescription, logLevel: .error, timeStamp: Date()))
        wrapper.error(error: error)
    }

    func info(_ message: @autoclosure () -> String) {
        logHistory.append(LogEntryItem(message: message(), logLevel: .info, timeStamp: Date()))
        wrapper.info(message())
    }

    func debug(_ message: @autoclosure () -> String) {
        logHistory.append(LogEntryItem(message: message(), logLevel: .debug, timeStamp: Date()))
        wrapper.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String) {
        logHistory.append(LogEntryItem(message: message(), logLevel: .verbose, timeStamp: Date()))
        wrapper.verbose(message())
    }

    func getLogHistory() -> [LogEntryItem] {
        return logHistory
    }

}
