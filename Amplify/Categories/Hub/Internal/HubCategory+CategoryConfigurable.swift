//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HubCategory: CategoryConfigurable {

    func configure(using configuration: CategoryConfiguration) throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(categoryType.displayName) has already been configured.",
                """
                Either remove the duplicate call to `Amplify.configure()`, or call \
                `Amplify.reset()` before issuing the second call to `configure()`
                """
            )
            throw error
        }

        for (pluginKey, pluginConfiguration) in configuration.plugins {
            let plugin = try getPlugin(for: pluginKey)
            try plugin.configure(using: pluginConfiguration)
        }

        isConfigured = true
    }

    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        guard let configuration = categoryConfiguration(from: amplifyConfiguration) else {
            return
        }
        try configure(using: configuration)
    }

    public func reset() {
        plugins.values.forEach { $0.reset() }
        isConfigured = false
    }

}
