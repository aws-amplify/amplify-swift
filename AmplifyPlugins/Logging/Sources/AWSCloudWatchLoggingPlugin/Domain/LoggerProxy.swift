//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// As its name suggests, the `LoggerProxy` class acts as a layer of
/// indirection that conforms to Amplify's [Logger](x-source-tag://Logger)
/// protocol that delegates all work to its targets.
///
/// - Tag: LogProxy
final class LoggerProxy {
    
    /// The default LogLevel used when no targets are available.
    ///
    /// - Tag: LogProxy.defaultLogLevel
    var defaultLogLevel: Amplify.LogLevel = .error
    
    private let targets: [Logger]
    
    /// - Tag: LogProxy.init
    init(targets: [Logger]) {
        self.targets = targets
    }
    
}

extension LoggerProxy: Logger {
    
    var logLevel: Amplify.LogLevel {
        get {
            if let logger = targets.first {
                return logger.logLevel
            }
            return defaultLogLevel
        }
        set(newValue) {
            for logger in targets {
                var updated = logger
                updated.logLevel = newValue
            }
        }
    }
    
    func error(_ message: @autoclosure () -> String) {
        targets.forEach { $0.error(message()) }
    }
    
    func error(error: Error) {
        targets.forEach { $0.error(error: error) }
    }
    
    func warn(_ message: @autoclosure () -> String) {
        targets.forEach { $0.warn(message()) }
    }
    
    func info(_ message: @autoclosure () -> String) {
        targets.forEach { $0.info(message()) }
    }
    
    func debug(_ message: @autoclosure () -> String) {
        targets.forEach { $0.debug(message()) }
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        targets.forEach { $0.verbose(message()) }
    }
}
