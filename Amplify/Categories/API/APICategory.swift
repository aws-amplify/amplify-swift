//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class APICategory: Category {
    enum PluginOrSelector {
        case plugin(APICategoryPlugin)
        case selector(APIPluginSelector)
    }

    public let categoryType = CategoryType.api

    var plugins = [PluginKey: APICategoryPlugin]()

    var pluginSelectorFactory: PluginSelectorFactory?

    /// Returns either the only plugin added to the category, or a selector created from the added factory. Accessing
    /// this property if no plugins are added, or if more than one plugin is added without a pluginSelectorFactory,
    /// will cause a preconditionFailure.
    var pluginOrSelector: PluginOrSelector {
        if plugins.count == 1, let plugin = plugins.first?.value {
            return .plugin(plugin)
        }

        guard !plugins.isEmpty else {
            preconditionFailure("No plugins added to \(categoryType.displayName) category.")
        }

        guard let pluginSelectorFactory = pluginSelectorFactory else {
            preconditionFailure("No plugin selector factory added to \(categoryType.displayName) category.")
        }

        guard let selector = pluginSelectorFactory.makeSelector() as? APIPluginSelector else {
            preconditionFailure(
                """
                \(String(describing: pluginSelectorFactory)) can't make a selector for the
                \(categoryType.displayName) category.
                """)
        }

        return .selector(selector)
    }

    // MARK: - Configuration

    /// For each key in the category configuration's `plugins` section, retrieves the plugin added for that
    /// key, then invokes `configure` on that plugin.
    ///
    /// - Parameter configuration: The category-specific configuration
    /// - Throws:
    ///   - PluginError.noSuchPlugin if there is no plugin added for the specified key
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    public func configure(using configuration: CategoryConfiguration) throws {
        for (pluginKey, pluginConfiguration) in configuration.plugins {
            let plugin = try getPlugin(for: pluginKey)
            try plugin.configure(using: pluginConfiguration)
        }
    }

    /// Convenience method for configuring the category using the top-level AmplifyConfiguration
    ///
    /// - Parameter amplifyConfiguration: The AmplifyConfiguration
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        guard let configuration = categoryConfiguration(from: amplifyConfiguration) else {
            return
        }
        try configure(using: configuration)
    }

    // MARK: - Plugin handling

    /// Adds `plugin` to the list of Plugins that implement functionality for this category. If a plugin has
    /// already added to this category, callers must add a `PluginSelector` before adding a second plugin.
    ///
    /// - Parameter plugin: The Plugin to add
    /// - Throws:
    ///   - PluginError.emptyKey if the plugin's `key` property is empty
    ///   - PluginError.noSelector if the call to `add` would cause there to be more than one plugin added to this
    ///     category.
    public func add(plugin: APICategoryPlugin) throws {
        let key = plugin.key
        guard !key.isEmpty else {
            let pluginDescription = String(describing: plugin)
            let error = PluginError.emptyKey("Plugin \(pluginDescription) has an empty `key`.",
                "Set the `key` property for \(String(describing: plugin))")
            throw error
        }

        if plugins.isEmpty {
            plugins[plugin.key] = plugin
            pluginSelectorFactory?.add(plugin: plugin)
            return
        }

        guard pluginSelectorFactory != nil else {
            let error = PluginError.noSelector(
                "No selector added for the \(categoryType.displayName) category",
                """
                A plugin has already been added to the \(categoryType.displayName) category. Add a
                PluginSelectorFactory by calling Amplify.\(categoryType.displayName).set(selectorFactory:) before
                attempting to add more than one plugin.
                """)
            throw error
        }

        plugins[plugin.key] = plugin
        pluginSelectorFactory?.add(plugin: plugin)
    }

    /// Returns the added plugin with the specified `key` property.
    ///
    /// - Parameter key: The PluginKey (String) of the plugin to retrieve
    /// - Returns: The wrapped plugin
    /// - Throws: PluginError.noSuchPlugin if no plugin exists for `key`
    public func getPlugin(for key: PluginKey) throws -> APICategoryPlugin {
        guard let plugin = plugins[key] else {
            let keys = plugins.keys.joined(separator: ", ")
            let error = PluginError.noSuchPlugin("No plugin has been added for '\(key)'.",
                "Either add a plugin for '\(key)', or use one of the known keys: \(keys)")
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
        pluginSelectorFactory?.removePlugin(for: key)
    }

    /// Adds `pluginSelectorFactory` to the category, to allow API calls to be routed to
    /// the correct plugin in cases where more than one plugin has been added to the
    /// category. Callers may add a plugin selector at any time, even if no plugins have
    /// yet been added to the category, but callers *must* add a plugin selector before
    /// the second plugin is added. PluginSelectors are only required, and only invoked,
    /// if more than one plugin is registered for a category.
    public func set(pluginSelectorFactory: PluginSelectorFactory) throws {
        guard pluginSelectorFactory.categoryType == categoryType else {
            let error = PluginError.invalidSelectorFactory(
                "Invalid selector factory",
                """
                The factory \(String(describing: pluginSelectorFactory)) cannot be cast to the necessary selector
                factory type for the category '\(categoryType.displayName)'. Verify that the call to \(#function)
                is using an appropriate PluginSelectorFactory class.
                """)
            throw error
        }
        self.pluginSelectorFactory = pluginSelectorFactory

        plugins.values.forEach { self.pluginSelectorFactory?.add(plugin: $0) }
    }

    /// Invokes `reset` on each added plugin
    public func resetPlugins() {
        plugins.values.forEach { $0.reset() }
    }

}
