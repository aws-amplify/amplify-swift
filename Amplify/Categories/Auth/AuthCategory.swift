//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// - Note: `@unchecked Sendable` to satisfy the `Sendable` requirement that the category behavior
///   protocol now carries. The conformance must be declared here because the behavior conformance
///   lives in an extension in another file.
///
///   The conformance is **unchecked in the literal sense**: `plugins` and `isConfigured` are plain
///   mutable state with no lock, and `add(plugin:)` / `removePlugin(for:)` mutate `plugins` after
///   configuration. In practice `Amplify.configure()` runs once during start-up and the state is
///   read-only afterwards, but nothing in this type enforces that — a caller that adds or removes a
///   plugin concurrently with category access races. That predates this annotation; the annotation
///   only stops the compiler from asking about it.
public final class AuthCategory: Category, @unchecked Sendable {

    public let categoryType =  CategoryType.auth

    var plugins = [PluginKey: AuthCategoryPlugin]()

    /// Returns the plugin added to the category, if only one plugin is added. Accessing this property if no plugins
    /// are added, or if more than one plugin is added, will cause a preconditionFailure.
    var plugin: AuthCategoryPlugin {
        guard isConfigured else {
            return Fatal.preconditionFailure(
                """
                \(categoryType.displayName) category is not configured. Call Amplify.configure() before using \
                any methods on the category.
                """
            )
        }

        guard !plugins.isEmpty else {
            return Fatal.preconditionFailure("No plugins added to \(categoryType.displayName) category.")
        }

        guard plugins.count == 1 else {
            return Fatal.preconditionFailure(
                """
                More than 1 plugin added to \(categoryType.displayName) category. \
                You must invoke operations on this category by getting the plugin you want, as in:
                #"Amplify.\(categoryType.displayName).getPlugin(for: "ThePluginKey").foo()
                """
            )
        }

        return plugins.first!.value
    }

    var isConfigured = false

    /// `true` when `Amplify.configure()` has run for this category and a plugin is registered.
    ///
    /// Reading ``plugin`` in either of the opposite states trips a `preconditionFailure`, which aborts
    /// the process rather than failing the call. Exposed over `@_spi` so the AWS plugin modules can
    /// report an error instead: they hold long-lived clients that can outlive `Amplify.reset()`, and for
    /// those a missing Auth category is a recoverable condition, not a programmer error.
    ///
    /// - Important: This is **advisory, not a guarantee**. It reads `isConfigured` and `plugins` without
    ///   synchronization, and a caller acts on the result after it returns, so `Amplify.reset()` running
    ///   in between still leads to the `preconditionFailure` it was meant to avoid. It narrows the window
    ///   rather than closing it. Closing it would mean giving ``plugin`` a non-trapping counterpart, which
    ///   is a larger change to the category contract.
    @_spi(InternalAmplifyConfiguration)
    public var isConfiguredWithPlugin: Bool {
        isConfigured && !plugins.isEmpty
    }

    // MARK: - Plugin handling

    /// Adds `plugin` to the list of Plugins that implement functionality for this category.
    ///
    /// - Parameter plugin: The Plugin to add
    public func add(plugin: AuthCategoryPlugin) throws {
        let key = plugin.key
        guard !key.isEmpty else {
            let pluginDescription = String(describing: plugin)
            let error = AuthError.configuration(
                "Plugin \(pluginDescription) has an empty `key`.",
                "Set the `key` property for \(String(describing: plugin))"
            )
            throw error
        }

        guard !isConfigured else {
            let pluginDescription = String(describing: plugin)
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(pluginDescription) cannot be added after `Amplify.configure()`.",
                "Do not add plugins after calling `Amplify.configure()`."
            )
            throw error
        }

        plugins[plugin.key] = plugin
    }

    /// Returns the added plugin with the specified `key` property.
    ///
    /// - Parameter key: The PluginKey (String) of the plugin to retrieve
    /// - Returns: The wrapped plugin
    public func getPlugin(for key: PluginKey) throws -> AuthCategoryPlugin {
        guard let plugin = plugins[key] else {
            let keys = plugins.keys.joined(separator: ", ")
            let error = AuthError.configuration(
                "No plugin has been added for '\(key)'.",
                "Either add a plugin for '\(key)', or use one of the known keys: \(keys)"
            )
            throw error
        }
        return plugin
    }

    /// Removes the plugin registered for `key` from the list of Plugins that implement functionality for this category.
    /// If no plugin has been added for `key`, no action is taken, making this method safe to call multiple times.
    ///
    /// - Parameter key: The key used to `add` the plugin
    public func removePlugin(for key: PluginKey) {
        plugins.removeValue(forKey: key)
    }
}

extension AuthCategory: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
