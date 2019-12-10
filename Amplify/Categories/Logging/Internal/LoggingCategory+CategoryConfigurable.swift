//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension LoggingCategory: CategoryConfigurable {

    /// Configures the LoggingCategory using the incoming CategoryConfiguration.
    func configure(using configuration: CategoryConfiguration) throws {
        try concurrencyQueue.sync {
            let plugin: LoggingCategoryPlugin
            switch configurationState {
            case .default:
                // Default plugin is already assigned, and no configuration is applicable, exit early
                configurationState = .configured
                return
            case .pendingConfiguration(let pendingPlugin):
                plugin = pendingPlugin
            case .configured:
                let error = ConfigurationError.amplifyAlreadyConfigured(
                    "\(categoryType.displayName) has already been configured.",
                    "Remove the duplicate call to `Amplify.configure()`"
                )
                throw error
            }

            guard let pluginConfiguration = configuration.plugins[plugin.key] else {
                throw LoggingError.configuration(
                    "No configuration found for added plugin `\(plugin.key)`",
                    """
                    Either fix the configuration file to specify the plugin's key value of '\(plugin.key)',
                    or add a plugin with one of the keys specified in the configuration:
                    \(configuration.plugins.keys.joined(separator: ", "))
                    """
                )
            }

            try plugin.configure(using: pluginConfiguration)
            self.plugin = plugin
            configurationState = .configured
        }
    }

    func configure(using amplifyConfiguration: AmplifyConfiguration) throws {
        guard let configuration = categoryConfiguration(from: amplifyConfiguration) else {
            return
        }
        try configure(using: configuration)
    }

}
