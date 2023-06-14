//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Represents an individual row in a log.
///
/// - Tag: LogEntry
struct LogEntry: Codable, Hashable {
    
    /// The timestamp representing the creation time of the log entry or event.
    ///
    /// - Tag: LogEntry.created
    let created: Date

    /// The logical tag of the log entry or event. This will likely be a
    /// Category name.
    ///
    /// - Tag: LogEntry.tag
    let tag: String

    /// An integer representation of the [LogLevel](x-source-tag://LogLevel)
    /// associated with the receiver. This attribute's uses an Int to accomodate coding.
    ///
    /// - Tag: LogEntry.level
    private let level: Int
    
    /// The main payload String associated with the receiver.
    ///
    /// - Tag: LogEntry.message
    let message: String
    
    /// The [LogLevel](x-source-tag://LogLevel) associated with the receiver.
    ///
    /// - Tag: LogEntry.logLevel
    var logLevel: LogLevel {
        if let result = LogLevel(rawValue: self.level) {
            return result
        }
        return .error
    }
    
    /// - Returns: String representation of [logLevel](x-source-tag://LogEntry.logLevel)
    ///
    /// - Tag: LogEntry.logLevelName
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
        Int((created.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    /// - Tag: LogEntry.init
    init(tag: String, level: LogLevel, message: String, created: Date = Date()) {
        self.created = created
        self.level = level.rawValue
        self.tag = tag
        self.message = message
    }
    
}
