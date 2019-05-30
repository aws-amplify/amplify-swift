//
//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Internal utility that holds plugins (wrapped in appropriate type-erasing wrappers) for a category.
struct PluginHolder<PluginType: Plugin & PluginInitializable> {
    private(set) var plugins = [PluginKey: PluginType]()

    /// Wraps `plugin` in the `PluginType` wrapper and adds it to the `plugins` map associated with `plugin.key`. A
    /// plugin must supply a non-empty key--if `plugin.key.isEmpty` evalutes to true, this method throws a
    /// preconditionFailure
    ///
    /// - Parameter plugin: The Plugin to store. `plugin`'s `PluginMarker` associatedtype must match that of this
    ///   instances `PluginType` generic parameter.
    /// - Throws: PluginError.emptyKey if `plugin.key` is empty
    mutating func add(_ plugin: PluginType) throws {
        let key = plugin.key
        guard !key.isEmpty else {
            let pluginDescription = String(describing: plugin)
            let error = PluginError.emptyKey("Plugin \(pluginDescription) has an empty `key`.",
                "Set the `key` property for \(String(describing: plugin))")
            throw error
        }

        let wrappedPlugin = PluginType(instance: plugin)
        plugins[key] = wrappedPlugin
    }

    /// Returns the wrapped plugin for `key`.
    ///
    /// - Parameter key: The PluginKey (String) of the plugin to retrieve
    /// - Returns: The wrapped plugin
    /// - Throws: PluginError.noSuchPlugin if no plugin exists for `key`
    func get(for key: PluginKey) throws -> PluginType {
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
    mutating func remove(for key: PluginKey) {
        plugins.removeValue(forKey: key)
    }

    /// Printable string of the category name for use in error/debug messages
    private var categoryName: String {
        let name = ""
        return name
    }

    /// Returns the default plugin for use in cases where there are more than one plugin registered. If no plugins have
    /// been added, of it more than one plugin has been added without specifying a
    var defaultPlugin: PluginType {
        guard !plugins.isEmpty else {
            preconditionFailure("No plugins registered. Add at least one plugin for the \(categoryName) category")
        }

        if plugins.count == 1 {
            guard let plugin = plugins.values.first else {
                // Should never happen
                let failureMessage = """
                Only one plugin key, `\(plugins.keys.first!)`, is registered for the \(categoryName) category, \
                but its value is nil
                """
                preconditionFailure(failureMessage)
            }
            return plugin
        }

        // plugins.count > 1
//        guard let key = defaultPluginKey else {
//            let keys = plugins.keys.joined(separator: ", ")
//            let failureMessage = """
//            No default plugin key specified. Set `defaultPluginKey` for the \(categoryName) category to one of the \
//            registered plugin keys: \(keys)
//            """
//            preconditionFailure(failureMessage)
//        }
        let key = "TODO"

        guard let defaultPlugin = plugins[key] else {
            // Should never happen
            let failureMessage = """
            Default plugin key, `\(key)`, was specified for the \(categoryName) category, but its value is nil
            """
            preconditionFailure(failureMessage)
        }

        return defaultPlugin
    }

}
