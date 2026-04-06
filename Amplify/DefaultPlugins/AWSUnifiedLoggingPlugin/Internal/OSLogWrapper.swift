//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import os.log

final class OSLogWrapper: Logger {
    private let osLog: OSLog

    var enabled: Bool = true

    var getLogLevel: () -> LogLevel

    var logLevel: LogLevel {
        get {
            getLogLevel()
        }
        set {
            getLogLevel = { newValue }
        }
    }

    init(osLog: OSLog, getLogLevel: @escaping () -> LogLevel) {
        self.osLog = osLog
        self.getLogLevel = getLogLevel
    }

    func error(_ message: @autoclosure () -> String) {
        guard enabled, logLevel.rawValue >= LogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            message()
        )
    }

    func error(error: Error) {
        guard enabled, logLevel.rawValue >= LogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            error.localizedDescription
        )
    }

    func warn(_ message: @autoclosure () -> String) {
        guard enabled, logLevel.rawValue >= LogLevel.warn.rawValue else {
            return
        }

        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }

    func info(_ message: @autoclosure () -> String) {
        guard enabled, logLevel.rawValue >= LogLevel.info.rawValue else {
            return
        }

        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }

    func debug(_ message: @autoclosure () -> String) {
        guard enabled, logLevel.rawValue >= LogLevel.debug.rawValue else {
            return
        }

        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }

    func verbose(_ message: @autoclosure () -> String) {
        guard enabled, logLevel.rawValue >= LogLevel.verbose.rawValue else {
            return
        }

        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }
}
