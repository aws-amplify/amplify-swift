//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension LoggingCategory: LoggingCategoryClientBehavior {
    public var `default`: Logger {
        plugin.default
    }

    public func logger(forCategory category: String) -> Logger {
        plugin.logger(forCategory: category)
    }

    public func logger(forCategory category: CategoryType) -> Logger {
        plugin.logger(forCategory: category.displayName)
    }

    public func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        plugin.logger(forCategory: category, logLevel: logLevel)
    }
}
