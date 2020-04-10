//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol APICategory: Category, APICategoryBehavior {
    func add(plugin: APICategoryPlugin) throws
    func getPlugin(for key: PluginKey) throws -> APICategoryPlugin
}
