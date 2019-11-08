//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// At its core, the Amplify class is simply a router that provides clients top-level access to categories and
/// configuration methods. It provides convenient access to default plugins via the top-level category properties,
/// but clients can access specific plugins by invoking `getPlugin` on a category and issuing methods directly to
/// that plugin.
///
/// - Warning: It is a serious programmer to invoke any of the category APIs (like `Analytics.record()` or
/// `Logging.debug()`) without first registering plugins via `Amplify.add(plugin:)` and configuring Amplify via
/// `Amplify.configure()`. Such access will cause a preconditionFailure.
public class Amplify {

    /// If `true`, `configure()` has already been invoked, and subsequent calls to `configure` will throw a
    /// ConfigurationError.amplifyAlreadyConfigured error.
    static var isConfigured = false

    // Storage for the categories themselves, which will be instantiated during configuration, and cleared during reset
    public static internal(set) var Analytics = AnalyticsCategory()
    public static internal(set) var API = APICategory()
    public static internal(set) var DataStore = DataStoreCategory()
    public static internal(set) var Hub = HubCategory()
    public static internal(set) var Logging = LoggingCategory()
    public static internal(set) var Predictions = PredictionsCategory()
    public static internal(set) var Storage = StorageCategory()

    /// Adds `plugin` to the Analytics category
    ///
    /// - Parameter plugin: The AnalyticsCategoryPlugin to add
    /// - Throws: PluginError.emptyKey if `plugin.key` is empty
    public static func add<P: Plugin>(plugin: P) throws {
        if let plugin = plugin as? AnalyticsCategoryPlugin {
            try Analytics.add(plugin: plugin)
        } else if let plugin = plugin as? APICategoryPlugin {
            try API.add(plugin: plugin)
        } else if let plugin = plugin as? DataStoreCategoryPlugin {
            try DataStore.add(plugin: plugin)
        } else if let plugin = plugin as? HubCategoryPlugin {
            try Hub.add(plugin: plugin)
        } else if let plugin = plugin as? LoggingCategoryPlugin {
            try Logging.add(plugin: plugin)
        } else if let plugin = plugin as? PredictionsCategoryPlugin {
            try Predictions.add(plugin: plugin)
        } else if let plugin = plugin as? StorageCategoryPlugin {
            try Storage.add(plugin: plugin)
        } else {
            throw PluginError.pluginConfigurationError(
                "Plugin category does not exist.",
                "Verify that the library version is correct and supports the plugin's category.")
        }
    }

}
