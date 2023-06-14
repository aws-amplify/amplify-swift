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
    
    public func enable() {
        plugin.enable()
    }
    
    public func disable() {
        plugin.disable()
    }
    
    public func logger(forNamespace namespace: String) -> Logger {
        plugin.logger(forNamespace: namespace)
    }
    
    public func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        plugin.logger(forCategory: category, forNamespace: namespace)
    }
}
