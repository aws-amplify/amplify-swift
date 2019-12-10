//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol APICategory: Category, APICategoryClientBehavior {
    func add(plugin: APICategoryPlugin) throws
    func getPlugin(for key: PluginKey) throws -> APICategoryPlugin
}
