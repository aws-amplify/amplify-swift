//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os.log

/// - Note: `@unchecked Sendable` because `enabled` and `getLogLevel` are mutable — both are
///   reassigned after construction by `AWSUnifiedLoggingPlugin` — but every access goes
///   through `lock`. `Logger` is `Sendable`, and a logger is shared across concurrency
///   domains by nature, so the state genuinely needs synchronizing rather than annotating away.
final class OSLogWrapper: Logger, @unchecked Sendable {
    private let osLog: OSLog

    private let lock = NSLock()
    private var _enabled: Bool = true
    private var _getLogLevel: () -> LogLevel

    var enabled: Bool {
        get { lock.withLock { _enabled } }
        set { lock.withLock { _enabled = newValue } }
    }

    var getLogLevel: () -> LogLevel {
        get { lock.withLock { _getLogLevel } }
        set { lock.withLock { _getLogLevel = newValue } }
    }

    var logLevel: LogLevel {
        get {
            getLogLevel()
        }
        set {
            lock.withLock { _getLogLevel = { newValue } }
        }
    }

    init(osLog: OSLog, getLogLevel: @escaping () -> LogLevel) {
        self.osLog = osLog
        self._getLogLevel = getLogLevel
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
