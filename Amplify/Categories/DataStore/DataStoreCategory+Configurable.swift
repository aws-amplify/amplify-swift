//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DataStoreCategory: CategoryConfigurable {

    func configure(using configuration: CategoryConfiguration) throws {
        // TODO add configuration logic
        for (pluginKey, pluginConfiguration) in configuration.plugins {
            let plugin = try getPlugin(for: pluginKey)
            try plugin.configure(using: pluginConfiguration)
        }
        isConfigured = true
    }

    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        let plugins: [String: JSONValue] = amplifyConfiguration.dataStore?.plugins ?? [:]
        // TODO add configuration logic
        for (pluginKey, pluginConfiguration) in plugins {
            let plugin = try getPlugin(for: pluginKey)
            try plugin.configure(using: pluginConfiguration)
        }
        isConfigured = true
    }

    func reset(onComplete: @escaping (() -> Void)) {
        let group = DispatchGroup()

        for plugin in plugins.values {
            group.enter()
            plugin.reset { group.leave() }
        }

        group.wait()

        isConfigured = false
        onComplete()
    }

}
