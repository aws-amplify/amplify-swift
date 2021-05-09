//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol APICategory: Category, APICategoryBehavior {

    /// <#Description#>
    /// - Parameter plugin: <#plugin description#>
    func add(plugin: APICategoryPlugin) throws

    /// <#Description#>
    /// - Parameter key: <#key description#>
    func getPlugin(for key: PluginKey) throws -> APICategoryPlugin
}
