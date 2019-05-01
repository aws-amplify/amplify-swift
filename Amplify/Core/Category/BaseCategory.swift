//
//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The base class for all Category objects
public class BaseCategory<CategoryMarker, CategoryPluginType, Factory: PluginSelectorFactory>: Category
where CategoryMarker == CategoryPluginType.PluginMarker, CategoryPluginType == Factory.PluginType {
    public typealias Marker = CategoryMarker
    public typealias PluginType = CategoryPluginType
    public typealias PluginSelectorFactoryType = Factory

    /// Holds all plugins added to this category via `add(plugin:)`
    var pluginHolder = PluginHolder<PluginType>()

    var pluginSelectorFactory: PluginSelectorFactoryType?

    /// Returns the default plugin for the category
    var defaultPlugin: PluginType {
        return pluginHolder.defaultPlugin
    }

    /// Adds `plugin` to the list of CategoryPlugins that implement functionality for this category. If a plugin has
    /// already added to this category, callers must add a `PluginSelector` before adding a second plugin.
    ///
    /// - Parameter plugin: The Plugin to add
    /// - Throws:
    ///   - PluginError.emptyKey if the plugin's `key` property is empty
    ///   - PluginError.noSelector if the call to `add` would cause there to be more than one plugin added to this
    ///     category.
    public func add<P>(plugin: P) throws where P: Plugin, Marker == P.PluginMarker {
        try pluginHolder.add(plugin)
    }

    /// Adds `pluginSelectorFactory` to the category, to allow API calls to be routed to
    /// the correct plugin in cases where more than one plugin has been added to the
    /// category. Callers may add a plugin selector at any time, even if no plugins have
    /// yet been added to the category, but callers *must* add a plugin selector before
    /// the second plugin is added. PluginSelectors are only required, and only invoked,
    /// if more than one plugin is registered for a category.
    public func add(pluginSelectorFactory: PluginSelectorFactoryType) {
        self.pluginSelectorFactory = pluginSelectorFactory
    }

    /// Returns the wrapped plugin for `key`.
    ///
    /// - Parameter key: The PluginKey (String) of the plugin to retrieve
    /// - Returns: The wrapped plugin
    /// - Throws: PluginError.noSuchPlugin if no plugin exists for `key`
    public func getPlugin(for key: PluginKey) throws -> PluginType {
        return try pluginHolder.get(for: key)
    }

    /// Removes the plugin registered for `key` from the list of Plugins that implement functionality for this category.
    /// If no plugin has been added for `key`, no action is taken, making this method safe to call multiple times.
    ///
    /// - Parameter key: The key used to `add` the plugin
    public func removePlugin(for key: PluginKey) {
        pluginHolder.remove(for: key)
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

    /// For each key in the category configuration's `plugins` section, retrieves the plugin added for that
    /// key, then invokes `configure` on that plugin.
    ///
    /// - Parameter configuration: The category-specific configuration
    /// - Throws:
    ///   - PluginError.noSuchPlugin if there is no plugin added for the specified key
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    public func configure(using configuration: CategoryConfiguration) throws {
        for (key, pluginConfiguration) in configuration.plugins {
            let plugin = try getPlugin(for: key)
            try plugin.configure(using: pluginConfiguration)
        }
    }

    /// Invokes `reset` on each added plugin
    public func resetPlugins() {
        pluginHolder.plugins.values.forEach { $0.reset() }
    }
}
