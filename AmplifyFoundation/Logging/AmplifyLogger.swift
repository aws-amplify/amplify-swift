//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import os
import Foundation

public final class AmplifyLogger: Logger {
    static let lock: NSLocking = NSLock()
    static var _logLevel = LogLevel.error
    
    private let osLog: OSLog
    private let subsystem: String
    
    public init(namespace: String) {
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.amazonaws.amplify.logger"
        self.namespace = namespace
        self.osLog = OSLog(subsystem: subsystem, category: namespace)
    }
    
    public var namespace: String
    
    public var logLevel: LogLevel {
        get {
            AmplifyLogger.lock.lock()
            defer {
                AmplifyLogger.lock.unlock()
            }
            
            return AmplifyLogger._logLevel
        }
        set {
            AmplifyLogger.lock.lock()
            defer {
                AmplifyLogger.lock.unlock()
            }
            
            AmplifyLogger._logLevel = newValue
        }
    }
    
    public func error(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= LogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            message()
        )
    }
    
    public func error(_ error: @autoclosure () -> Error) {
        guard logLevel.rawValue >= LogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            error().localizedDescription
        )
    }
    
    public func warn(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= LogLevel.warn.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }
    
    public func info(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= LogLevel.info.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }
    
    public func debug(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }
    
    public func verbose(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }
}

public final class AmplifyLoggerProvider: LoggerProvider {
    public func resolve(forNamespace namespace: String) -> Logger {
        AmplifyLogger(namespace: namespace)
    }
}
