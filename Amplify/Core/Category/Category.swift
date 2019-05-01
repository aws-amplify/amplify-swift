//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An Amplify Category stores certain global states, holds references to plugins for the category, and routes method
/// requests to those plugins appropriately.
public protocol Category: class {
    /// `Marker` is the CategoryMarker the conforming type is associated with. Conforms to `CategoryMarker`, but since
    /// that is inferred in subsequent definitions, it's not necessary to declare that conformance here.
    associatedtype Marker

    /// The concrete "wrapper type" for the plugins. At a minimum, the PluginType will
    /// conform to `Plugin` and thus provide configuration and reset behavior; as well
    /// as `PluginWrapper`, allowing for the category to store different underlying
    /// types of Plugins in a collection.
    associatedtype PluginType
        where PluginType.PluginMarker == Marker, PluginType.PluginInitializableMarker == Marker

    /// The base PluginSelectorFactory class for this category in cases where more than one plugin is added. See
    /// `PluginSelectorFactory` and `PluginSelector` for more details.
    associatedtype PluginSelectorFactoryType: PluginSelectorFactory
        where PluginSelectorFactoryType.PluginType == PluginType

    /// Adds `plugin` to the list of Plugins that implement functionality for this category. If a plugin has
    /// already added to this category, callers must add a `PluginSelector` before adding a second plugin.
    ///
    /// - Parameter plugin: The Plugin to add
    /// - Throws:
    ///   - PluginError.emptyKey if the plugin's `key` property is empty
    ///   - PluginError.noSelector if the call to `add` would cause there to be more than one plugin added to this
    ///     category.
    func add<P: Plugin>(plugin: P) throws where P.PluginMarker == Self.Marker

    /// Adds `pluginSelectorFactory` to the category, to allow API calls to be routed to
    /// the correct plugin in cases where more than one plugin has been added to the
    /// category. Callers may add a plugin selector at any time, even if no plugins have
    /// yet been added to the category, but callers *must* add a plugin selector before
    /// the second plugin is added. PluginSelectors are only required, and only invoked,
    /// if more than one plugin is registered for a category.
    func add(pluginSelectorFactory: PluginSelectorFactoryType)

    /// Returns the wrapped Plugin registered with `key`.
    ///
    /// - Parameter key: The key used to `add` the plugin
    /// - Returns: The Plugin registered with `key`
    /// - Throws: PluginError.noSuchPlugin if there is no plugin added for the specified key
    func getPlugin(for key: PluginKey) throws -> PluginType

    /// Removes the plugin registered for `key` from the list of Plugins that implement functionality for this category.
    /// If no plugin has been added for `key`, no action is taken, making this method safe to call multiple times.
    ///
    /// - Parameter key: The key used to `add` the plugin
    func removePlugin(for key: PluginKey)

    /// Configures the category and added plugins using `configuration`
    ///
    /// - Parameter configuration: The CategoryConfiguration
    /// - Throws:
    ///   - PluginError.noSuchPlugin: If the specified configuration references a plugin that has not been added
    ///     using `add(plugin:)`
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    func configure(using configuration: CategoryConfiguration) throws
}
