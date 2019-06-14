//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Internal utility that holds plugins (wrapped in appropriate type-erasing wrappers) for a category.
struct PluginHolder<PluginType: Plugin & PluginInitializable> {
    private(set) var plugins = [PluginKey: PluginType]()

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
