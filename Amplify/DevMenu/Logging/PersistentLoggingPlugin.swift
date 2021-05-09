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

    /// <#Description#>
    var plugin: LoggingCategoryPlugin

    /// <#Description#>
    var persistentLogWrapper: PersistentLogWrapper?

    /// <#Description#>
    public let key: String = DevMenuStringConstants.persistentLoggingPluginKey

    /// <#Description#>
    /// - Parameter configuration: <#configuration description#>
    /// - Throws: <#description#>
    public func configure(using configuration: Any?) throws {
        try plugin.configure(using: configuration)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - category: <#category description#>
    ///   - logLevel: <#logLevel description#>
    /// - Returns: <#description#>
    public func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        return plugin.logger(forCategory: category, logLevel: logLevel)
    }

    /// <#Description#>
    /// - Parameter category: <#category description#>
    /// - Returns: <#description#>
    public func logger(forCategory category: String) -> Logger {
        return plugin.logger(forCategory: category)
    }

    /// <#Description#>
    /// - Parameter onComplete: <#onComplete description#>
    public func reset(onComplete: @escaping BasicClosure) {
        persistentLogWrapper = nil
        plugin.reset(onComplete: onComplete)
    }

    /// <#Description#>
    /// - Parameter plugin: <#plugin description#>
    init(plugin: LoggingCategoryPlugin) {
        self.plugin = plugin
    }

    /// <#Description#>
    public var `default`: Logger {
        if persistentLogWrapper == nil {
            persistentLogWrapper = PersistentLogWrapper(logWrapper: plugin.default)
        }

        return persistentLogWrapper!
    }
}

@available(iOS 13.0, *)
extension PersistentLoggingPlugin: AmplifyVersionable { }
