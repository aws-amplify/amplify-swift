//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `LoggingCategoryPlugin` that wraps another`LoggingCategoryPlugin` and saves the logs in memory
@available(iOS 13.0, *)
public class PersistentLoggingPlugin: LoggingCategoryPlugin {

    var plugin: LoggingCategoryPlugin
    var persistentLogWrapper: PersistentLogWrapper?

    public let key: String = DevMenuStringConstants.persistentLoggingPluginKey

    public func configure(using configuration: Any?) throws {
        try plugin.configure(using: configuration)
    }

    public func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        return plugin.logger(forCategory: category, logLevel: logLevel)
    }

    public func logger(forCategory category: String) -> Logger {
        return plugin.logger(forCategory: category)
    }

    public func reset(onComplete: @escaping BasicClosure) {
        persistentLogWrapper = nil
        plugin.reset(onComplete: onComplete)
    }

    init(plugin: LoggingCategoryPlugin) {
        self.plugin = plugin
    }

    public var `default`: Logger {
        if persistentLogWrapper == nil {
            persistentLogWrapper = PersistentLogWrapper(logWrapper: plugin.default)
        }

        return persistentLogWrapper!
    }
}

@available(iOS 13.0, *)
extension PersistentLoggingPlugin: AmplifyVersionable { }
