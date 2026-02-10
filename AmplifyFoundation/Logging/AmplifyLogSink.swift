//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import os.log

public final class AmplifyLogSink : LogSinkBehavior {
    public var id: String
    private let logLevel : LogLevel
    private let subsystem: String
    
    public init(logLevel: LogLevel) {
        self.id = UUID().uuidString
        self.logLevel = logLevel
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.amazonaws.amplify.logSink"
    }
    
    public func isEnabled(for logLevel: LogLevel) -> Bool {
        self.logLevel >= logLevel
    }
    
    public func emit(message: LogMessage) {
        if isEnabled(for: message.level) {
            let osLog = OSLog(subsystem: subsystem, category: message.name)
            switch message.level {
            case .error:
                os_log(
                    "%@",
                    log: osLog,
                    type: OSLogType.error,
                    message.content + (message.error?.localizedDescription ?? "")
                )
            case .warn:
                os_log(
                    "%@",
                    log: osLog,
                    type: OSLogType.info,
                    message.content + (message.error?.localizedDescription ?? "")
                )
            case .info:
                os_log(
                    "%@",
                    log: osLog,
                    type: OSLogType.info,
                    message.content + (message.error?.localizedDescription ?? "")
                )
            case .debug:
                os_log(
                    "%@",
                    log: osLog,
                    type: OSLogType.debug,
                    message.content + (message.error?.localizedDescription ?? "")
                )
            case .verbose:
                os_log(
                    "%@",
                    log: osLog,
                    type: OSLogType.debug,
                    message.content + (message.error?.localizedDescription ?? "")
                )
            }
        }
    }
}
