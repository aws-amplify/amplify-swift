//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os.log

/// A Logging category plugin that forwards calls to the OS's Unified Logging system
final public class AWSUnifiedLoggingPlugin: LoggingCategoryPlugin {

    /// Convenience property. Each instance of `AWSUnifiedLoggingPlugin` has the same key
    public static var key: String {
        return "AWSUnifiedLoggingPlugin"
    }

    private static let defaultCategory = "Amplify"

    /// Synchronize access to the registeredLogs cache
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.amplify.AWSUnifiedLoggingPlugin.concurrency")

    /// A map of OSLogs objects created by subsystem and category. These are created on the fly, at the first instance
    /// of a log message to that subsystem/category combination. This will also be populated with a `default` logger
    /// at initialization.
    private var registeredLogs = [String: OSLogWrapper]()

    let subsystem: String

    /// Initializes the logging system with a default log, and immediately registers a default logger
    public init() {
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.amazonaws.amplify.AWSUnifiedLoggingPlugin"

        let defaultOSLog = OSLog(subsystem: subsystem, category: AWSUnifiedLoggingPlugin.defaultCategory)
        let wrapper = OSLogWrapper(osLog: defaultOSLog,
                                   getLogLevel: { Amplify.Logging.logLevel })
        registeredLogs["default"] = wrapper
    }

    // MARK: - LoggingCategoryPlugin

    public var key: String {
        return type(of: self).key
    }

    /// For protocol conformance only--this plugin has no applicable configurations
    public func configure(using configuration: Any?) throws {
        // Do nothing
    }

    /// Removes listeners and empties the message queue
    public func reset() async {
        concurrencyQueue.sync {
            registeredLogs = [:]
        }
    }

    // MARK: - Log wrapper caching

    private func logWrapper(for category: String = AWSUnifiedLoggingPlugin.defaultCategory) -> OSLogWrapper {

        let key = cacheKey(for: subsystem, category: category)

        return concurrencyQueue.sync {
            if let wrapper = registeredLogs[key] {
                return wrapper
            }

            let osLog = OSLog(subsystem: subsystem, category: category)
            let wrapper = OSLogWrapper(osLog: osLog,
                                       getLogLevel: { Amplify.Logging.logLevel })
            registeredLogs[key] = wrapper
            return wrapper
        }
    }

    private func cacheKey(for subsystem: String, category: String) -> String {
        "\(subsystem)|\(category)"
    }
}

extension AWSUnifiedLoggingPlugin {
    public var `default`: Logger {
        // We register the default logger at initialization, and protect access via a setter method, so this is safe
        // to force-unwrap
        registeredLogs["default"]!
    }

    public func logger(forCategory category: String) -> Logger {
        let wrapper = logWrapper(for: category)
        return wrapper
    }

    public func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        let wrapper = logWrapper(for: category)
        wrapper.logLevel = logLevel
        return wrapper
    }
}

extension AWSUnifiedLoggingPlugin: AmplifyVersionable { }
