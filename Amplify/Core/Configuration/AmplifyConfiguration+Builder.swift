//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyConfiguration {
    @resultBuilder
    public struct Builder {
        public static func buildBlock(_ plugins: any Plugin...) -> [any Plugin] {
            plugins
        }
        
        public static func buildOptional(_ plugins: [any Plugin]?) -> [any Plugin] {
            plugins ?? []
        }
    }
}

extension Amplify {
    
    /// Configures Amplify with the specified configuration.
    ///
    /// This method must be invoked after registering plugins, and before using any Amplify category. It must not be
    /// invoked more than once.
    ///
    /// **Lifecycle**
    ///
    /// Internally, Amplify configures the Hub and Logging categories first, so they are available to plugins in the
    /// remaining categories during the configuration phase. Plugins for the Hub and Logging categories must not
    /// assume that any other categories are available.
    ///
    /// After Amplify has configured all of its categories, it will dispatch a `HubPayload.EventName.Amplify.configured`
    /// event to each Amplify Hub channel. After this point, plugins may invoke calls on other Amplify categories.
    ///
    ///     do {
    ///         try Amplify.configure {
    ///             AWSCognitoAuthPlugin()
    ///             AWSLocationGeoPlugin()
    ///             AWSPinpointAnalyticsPlugin()
    ///
    ///             let models = AmplifyModels()
    ///             AWSDataStorePlugin(modelRegistration: models)
    ///         }
    ///         print("🎉 Amplify successfully configured")
    ///     } catch {
    ///         print("🙀 Something went wrong configuring Amplify - error: \(error)"
    ///     }
    ///
    /// - Parameter builder: The AmplifyConfiguration for specified Categories
    public static func configure(@AmplifyConfiguration.Builder builder: () -> [any Plugin]) throws {
        let plugins = builder()
        try plugins.forEach { plugin in
            try add(plugin: plugin)
        }
        try Amplify.configure()
    }
    
    // This was added as an internal overload of the existing public generic API.
    // This could replace the existing generic API in the future.
    internal static func add(plugin: any Plugin) throws {
        log.debug("Adding plugin: \(plugin))")
        switch plugin {
        case let plugin as AnalyticsCategoryPlugin:
            try Analytics.add(plugin: plugin)
        case let plugin as APICategoryPlugin:
            try API.add(plugin: plugin)
        case let plugin as AuthCategoryPlugin:
            try Auth.add(plugin: plugin)
        case let plugin as DataStoreCategoryPlugin:
            try DataStore.add(plugin: plugin)
        case let plugin as GeoCategoryPlugin:
            try Geo.add(plugin: plugin)
        case let plugin as HubCategoryPlugin:
            try Hub.add(plugin: plugin)
        case let plugin as LoggingCategoryPlugin:
            try Logging.add(plugin: plugin)
        case let plugin as PredictionsCategoryPlugin:
            try Predictions.add(plugin: plugin)
        case let plugin as StorageCategoryPlugin:
            try Storage.add(plugin: plugin)
        default:
            throw PluginError.pluginConfigurationError(
                "Plugin category does not exist.",
                "Verify that the library version is correct and supports the plugin's category."
            )
        }
    }
}
