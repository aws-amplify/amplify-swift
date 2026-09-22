//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(visionOS)
import Foundation

/// `LoggingCategoryPlugin` that wraps another`LoggingCategoryPlugin` and saves the logs in memory
///
/// - Note: `@unchecked Sendable` because `Plugin` is `Sendable` and the lazily-created wrapper is mutable
///   state; `lock` guards it. Deliberately not `final` — this type is public API, and `@unchecked
///   Sendable` does not require `final`, so marking it so would needlessly break any subclass.
public class PersistentLoggingPlugin: LoggingCategoryPlugin, @unchecked Sendable {

    private let lock = NSLock()
    let plugin: LoggingCategoryPlugin
    private var _persistentLogWrapper: PersistentLogWrapper?

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

    public func reset() async {
        lock.withLock { _persistentLogWrapper = nil }
        await plugin.reset()
    }

    init(plugin: LoggingCategoryPlugin) {
        self.plugin = plugin
    }

    public var `default`: Logger {
        if let existing = lock.withLock({ _persistentLogWrapper }) {
            return existing
        }
        // Built outside the lock so we never call into the wrapped plugin while holding it. Two racing
        // callers may each build one; the loser's is discarded and both see the same wrapper.
        let created = PersistentLogWrapper(logWrapper: plugin.default)
        return lock.withLock {
            if let existing = _persistentLogWrapper {
                return existing
            }
            _persistentLogWrapper = created
            return created
        }
    }
}

extension PersistentLoggingPlugin: AmplifyVersionable { }
#endif
