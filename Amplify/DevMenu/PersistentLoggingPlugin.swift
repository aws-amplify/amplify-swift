//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class PersistentLoggingPlugin: LoggingCategoryPlugin {

    var plugin: LoggingCategoryPlugin

    public let key: String = "PersistentLoggingPlugin"

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
        plugin.reset(onComplete: onComplete)
    }

    init(plugin: AWSUnifiedLoggingPlugin) {
        self.plugin = plugin
    }

    public var `default`: Logger {
        PersistentLogWrapper(logWrapper: plugin.default)
    }
}
