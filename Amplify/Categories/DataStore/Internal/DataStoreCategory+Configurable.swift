//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DataStoreCategory: CategoryConfigurable {

    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        if let configuration = categoryConfiguration(from: amplifyConfiguration) {
            try configure(using: configuration)
        } else {
            try configureFirstWithEmptyConfiguration()
        }
    }

    func configure(using configuration: CategoryConfiguration) throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(categoryType.displayName) has already been configured.",
                "Remove the duplicate call to `Amplify.configure()`"
            )
            throw error
        }

        for (pluginKey, pluginConfiguration) in configuration.plugins {
            let plugin = try getPlugin(for: pluginKey)
            try plugin.configure(using: pluginConfiguration)
        }

        isConfigured = true
    }

    func configureFirstWithEmptyConfiguration() throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(categoryType.displayName) has already been configured.",
                "Remove the duplicate call to `Amplify.configure()`"
            )
            throw error
        }
        guard let dataStorePlugin = plugins.first else {
            return
        }

        try dataStorePlugin.value.configure(using: [])
        isConfigured = true
    }

    func reset(onComplete: @escaping BasicClosure) {
        let group = DispatchGroup()

        for plugin in plugins.values {
            group.enter()
            plugin.reset { group.leave() }
        }

        ModelRegistry.reset()

        group.wait()

        isConfigured = false
        onComplete()
    }

}
