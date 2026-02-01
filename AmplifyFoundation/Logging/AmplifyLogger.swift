//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import os
import Foundation

public final class FoundationAmplifyLogger: FoundationLogger {
    static let lock: NSLocking = NSLock()
    static var _logLevel = FoundationLogLevel.error
    
    private let osLog: OSLog
    private let subsystem: String
    
    public init(namespace: String) {
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.amazonaws.amplify.logger"
        self.namespace = namespace
        self.osLog = OSLog(subsystem: subsystem, category: namespace)
    }
    
    public var namespace: String
    
    public var logLevel: FoundationLogLevel {
        get {
            FoundationAmplifyLogger.lock.lock()
            defer {
                FoundationAmplifyLogger.lock.unlock()
            }
            
            return FoundationAmplifyLogger._logLevel
        }
        set {
            FoundationAmplifyLogger.lock.lock()
            defer {
                FoundationAmplifyLogger.lock.unlock()
            }
            
            FoundationAmplifyLogger._logLevel = newValue
        }
    }
    
    public func error(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= FoundationLogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            message()
        )
    }
    
    public func error(_ error: @autoclosure () -> Error) {
        guard logLevel.rawValue >= FoundationLogLevel.error.rawValue else { return }
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.error,
            error().localizedDescription
        )
    }
    
    public func warn(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= FoundationLogLevel.warn.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }
    
    public func info(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= FoundationLogLevel.info.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.info,
            message()
        )
    }
    
    public func debug(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= FoundationLogLevel.debug.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }
    
    public func verbose(_ message: @autoclosure () -> String) {
        guard logLevel.rawValue >= FoundationLogLevel.verbose.rawValue else { return }
        
        os_log(
            "%@",
            log: osLog,
            type: OSLogType.debug,
            message()
        )
    }
}

public final class FoundationAmplifyLoggerProvider: FoundationLoggerProvider {
    public func resolve(forNamespace namespace: String) -> any FoundationLogger {
        FoundationAmplifyLogger(namespace: namespace)
    }
}
