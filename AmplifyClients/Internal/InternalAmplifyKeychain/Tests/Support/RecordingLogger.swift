//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// A logger that keeps every message with its level, so a test can assert what was logged.
final class RecordingLogger: Logger, @unchecked Sendable {

    // `@unchecked Sendable`: `entries` is only touched while holding `lock`.
    private let lock = NSLock()
    private var entries: [(level: LogLevel, message: String)] = []

    /// The messages logged at `level`, oldest first.
    func messages(at level: LogLevel) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return entries.filter { $0.level == level }.map(\.message)
    }

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.error, message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.warn, message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.info, message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.debug, message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        log(.verbose, message(), error())
    }

    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        let text = message()
        lock.lock()
        defer { lock.unlock() }
        entries.append((logLevel, text))
    }
}
