//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalCloudWatchLogging

/// Represents an individual row in a log.
struct LogEntry: Codable, Hashable, Sendable, LogEntryRepresentable {

    /// The timestamp representing the creation time of the log entry or event.
    let created: Date

    /// The namespace logical tag of the log entry or event.
    let namespace: String

    /// An integer representation of the log level. Uses an Int to accommodate coding.
    private let level: Int

    /// The main payload String associated with the receiver.
    let message: String

    /// The log level associated with the receiver.
    var logLevel: LogLevel {
        if let result = LogLevel(rawValue: level) {
            return result
        }
        return .error
    }

    /// - Returns: String representation of log level
    var logLevelName: String {
        switch logLevel {
        case .error: return "ERROR"
        case .warn: return "WARN"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .verbose: return "VERBOSE"
        case .none: return "NONE"
        }
    }

    var millisecondsSince1970: Int {
        Int((created.timeIntervalSince1970 * 1_000.0).rounded())
    }

    init(namespace: String, level: LogLevel, message: String, created: Date = Date()) {
        self.created = created
        self.level = level.rawValue
        self.namespace = namespace
        self.message = message
    }
}
