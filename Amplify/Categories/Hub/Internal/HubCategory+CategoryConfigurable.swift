//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension HubCategory: CategoryConfigurable {

    /// Configures the HubCategory using the incoming CategoryConfiguration. If the incoming configuration does not
    /// specify a Hub plugin, then we will inject the DefaultHubCategoryPlugin.
    func configure(using configuration: CategoryConfiguration) throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(categoryType.displayName) has already been configured.",
                "Remove the duplicate call to `Amplify.configure()`"
            )
            throw error
        }

        if configuration.plugins.isEmpty && plugins.isEmpty {
            try configureDefaultPlugin(using: configuration)
        } else {
            for (pluginKey, pluginConfiguration) in configuration.plugins {
                let plugin = try getPlugin(for: pluginKey)
                try plugin.configure(using: pluginConfiguration)
            }
        }

        isConfigured = true
    }

    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        guard let configuration = categoryConfiguration(from: amplifyConfiguration) else {
            try configureDefaultPlugin(using: nil)
            isConfigured = true
            return
        }
        try configure(using: configuration)
    }

    func reset(onComplete: @escaping BasicClosure) {
        let group = DispatchGroup()

        for plugin in plugins.values {
            group.enter()
            plugin.reset { group.leave() }
        }

        group.wait()

        isConfigured = false
        onComplete()
    }

    func configureDefaultPlugin(using configuration: CategoryConfiguration?) throws {
        let pluginConfiguration = configuration?.plugins[DefaultHubCategoryPlugin.key] ?? [:]
        let defaultPlugin = DefaultHubCategoryPlugin()
        try add(plugin: defaultPlugin)
        try defaultPlugin.configure(using: pluginConfiguration)
    }
}
