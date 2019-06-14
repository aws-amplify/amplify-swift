//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An Amplify Category stores certain global states, holds references to plugins for the category, and routes method
/// requests to those plugins appropriately.
public protocol Category: class, CategoryTypeable {

    // MARK: - Configuration

    /// Configures the category and added plugins using `configuration`
    ///
    /// - Parameter configuration: The CategoryConfiguration
    /// - Throws:
    ///   - PluginError.noSuchPlugin: If the specified configuration references a plugin that has not been added
    ///     using `add(plugin:)`
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    func configure(using configuration: CategoryConfiguration) throws

    // MARK: - Plugin handling

    // NOTE: `add(plugin:)`, `getPlugin(for key:)`, and `set(pluginSelectorFactory:` must be implemented in the actual
    // category classes, since they operate on specific plugin types

    /// Removes the plugin registered for `key` from the list of Plugins that implement functionality for this category.
    /// If no plugin has been added for `key`, no action is taken, making this method safe to call multiple times.
    ///
    /// - Parameter key: The key used to `add` the plugin
    func removePlugin(for key: PluginKey)

    /// Adds `pluginSelectorFactory` to the category, to allow API calls to be routed to
    /// the correct plugin in cases where more than one plugin has been added to the
    /// category. Callers may add a plugin selector at any time, even if no plugins have
    /// yet been added to the category, but callers *must* add a plugin selector before
    /// the second plugin is added. PluginSelectors are only required, and only invoked,
    /// if more than one plugin is registered for a category.
    func set(pluginSelectorFactory: PluginSelectorFactory) throws

    /// Invokes `reset` on each added plugin
    func resetPlugins()

}
