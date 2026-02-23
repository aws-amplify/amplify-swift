//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import os.log

/// A ready to use implementation of `LogSinkBehavior` which uses `OSLog`
/// to log messages to the console
public final class AmplifyOSLogSink : LogSinkBehavior {
    public let id: String
    private let logLevel : LogLevel
    private let subsystem: String
    
    public init(logLevel: LogLevel) {
        self.id = UUID().uuidString
        self.logLevel = logLevel
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.amazonaws.amplify.logSink"
    }
    
    public func isEnabled(for logLevel: LogLevel) -> Bool {
        logLevel <= self.logLevel
    }
    
    public func emit(message: LogMessage ) {
        if isEnabled(for: message.level) {
            let osLog = OSLog(subsystem: subsystem, category: message.name)
            let osLogType: OSLogType
            switch message.level {
            case .error: osLogType = .error
            case .warn, .info: osLogType = .info
            case .debug, .verbose: osLogType = .debug
            case .none: return
            }
            let content = message.content + (message.error.map { " - \($0.localizedDescription)" } ?? "")
            os_log("%@",log: osLog, type: osLogType, content)
        }
    }
}
