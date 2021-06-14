//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// API Category
public protocol APICategory: Category, APICategoryBehavior {

    /// Add a plugin to the API category
    ///
    /// - Parameter plugin: API plugin object
    func add(plugin: APICategoryPlugin) throws

    /// Retrieve an API plugin
    /// - Parameter key: the key which is defined in the plugin.
    func getPlugin(for key: PluginKey) throws -> APICategoryPlugin
}
