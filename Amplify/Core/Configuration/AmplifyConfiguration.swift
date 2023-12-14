//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents Amplify's configuration for all categories intended to be used in an application.
///
/// See: [Amplify.configure](x-source-tag://Amplify.configure)
///
/// - Tag: AmplifyConfiguration
public struct AmplifyConfiguration: Codable {
    public enum CodingKeys: String, CodingKey {
        case analytics
        case api
        case auth
        case dataStore
        case geo
        case hub
        case logging
        case notifications
        case predictions
        case storage
    }

    /// Configurations for the Amplify Analytics category
    var analytics: AnalyticsCategoryConfiguration?

    /// Configurations for the Amplify API category
    var api: APICategoryConfiguration?

    /// Configurations for the Amplify Auth category
    var auth: AuthCategoryConfiguration?

    /// Configurations for the Amplify DataStore category
    var dataStore: DataStoreCategoryConfiguration?

    /// Configurations for the Amplify Geo category
    var geo: GeoCategoryConfiguration?

    /// Configurations for the Amplify Hub category
    var hub: HubCategoryConfiguration?

    /// Configurations for the Amplify Logging category
    var logging: LoggingCategoryConfiguration?

    /// Configurations for the Amplify Notifications category
    var notifications: NotificationsCategoryConfiguration?

    /// Configurations for the Amplify Predictions category
    var predictions: PredictionsCategoryConfiguration?

    /// Configurations for the Amplify Storage category
    var storage: StorageCategoryConfiguration?

    /// - Tag: Amplify.init
    public init(analytics: AnalyticsCategoryConfiguration? = nil,
                api: APICategoryConfiguration? = nil,
                auth: AuthCategoryConfiguration? = nil,
                dataStore: DataStoreCategoryConfiguration? = nil,
                geo: GeoCategoryConfiguration? = nil,
                hub: HubCategoryConfiguration? = nil,
                logging: LoggingCategoryConfiguration? = nil,
                notifications: NotificationsCategoryConfiguration? = nil,
                predictions: PredictionsCategoryConfiguration? = nil,
                storage: StorageCategoryConfiguration? = nil) {
        self.analytics = analytics
        self.api = api
        self.auth = auth
        self.dataStore = dataStore
        self.geo = geo
        self.hub = hub
        self.logging = logging
        self.notifications = notifications
        self.predictions = predictions
        self.storage = storage
    }

    @resultBuilder
    public struct Builder {
        public static func buildBlock(_ pluginConfigurations: PluginConfiguration...) -> [PluginConfiguration] {
            pluginConfigurations
        }
    }
    
    /// Initialize `AmplifyConfiguration` by loading it from a URL representing the configuration file.
    ///
    /// - Tag: Amplify.configureWithConfigurationFile
    public init(configurationFile url: URL, withOverride configuration: AmplifyConfiguration? = nil) throws {
        self = try AmplifyConfiguration.loadAmplifyConfiguration(from: url, withOverride: configuration)
    }
}

// MARK: - Configure

public enum ConfigurationMergeStrategy {
    case throwOnConflict
    case overwriteOnConflict
}

extension Amplify {

    @discardableResult
    public static func configure(mergeStrategy: ConfigurationMergeStrategy? = nil,
                                 @AmplifyConfiguration.Builder builder: () -> [PluginConfiguration]) throws -> AmplifyConfiguration? {
        
        var configuration = AmplifyConfiguration()
        let pluginConfigurations = builder()
        pluginConfigurations.forEach { config in
            switch config.categoryKey {
            case .analytics:
                if configuration.analytics == nil {
                    configuration.analytics = AnalyticsCategoryConfiguration()
                }
                configuration.analytics?.plugins[config.pluginKey] = config.jsonConfig
            case .api:
                if configuration.api == nil {
                    configuration.api = APICategoryConfiguration()
                }
                configuration.api?.plugins[config.pluginKey] = config.jsonConfig
            case .auth:
                if configuration.auth == nil {
                    configuration.auth = AuthCategoryConfiguration()
                }
                configuration.auth?.plugins[config.pluginKey] = config.jsonConfig
            case .dataStore:
                if configuration.dataStore == nil {
                    configuration.dataStore = DataStoreCategoryConfiguration()
                }
                configuration.dataStore?.plugins[config.pluginKey] = config.jsonConfig
            case .geo:
                if configuration.geo == nil {
                    configuration.geo = GeoCategoryConfiguration()
                }
                configuration.geo?.plugins[config.pluginKey] = config.jsonConfig
            case .hub:
                if configuration.hub == nil {
                    configuration.hub = HubCategoryConfiguration()
                }
                configuration.hub?.plugins[config.pluginKey] = config.jsonConfig
            case .logging:
                if configuration.logging == nil {
                    configuration.logging = LoggingCategoryConfiguration()
                }
                configuration.logging?.plugins[config.pluginKey] = config.jsonConfig
            case .notifications:
                if configuration.notifications == nil {
                    configuration.notifications = NotificationsCategoryConfiguration()
                }
                configuration.notifications?.plugins[config.pluginKey] = config.jsonConfig
            case .predictions:
                if configuration.predictions == nil {
                    configuration.predictions = PredictionsCategoryConfiguration()
                }
                configuration.predictions?.plugins[config.pluginKey] = config.jsonConfig
            case .storage:
                if configuration.storage == nil {
                    configuration.storage = StorageCategoryConfiguration()
                }
                configuration.storage?.plugins[config.pluginKey] = config.jsonConfig
            }
        }
        
        return try configure(configuration)
    }
    
    @discardableResult
    public static func configure() throws -> AmplifyConfiguration? {
        log.info("Configuring")
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "Amplify has already been configured.",
                """
                Remove the duplicate call to `Amplify.configure()`
                """
            )
            throw error
        }

        let resolvedConfiguration: AmplifyConfiguration
        do {
            resolvedConfiguration = try Amplify.resolve(configuration: nil)
        } catch {
            log.info("Failed to find Amplify configuration.")
            if isRunningForSwiftUIPreviews {
                log.info("Running for SwiftUI previews with no configuration file present, skipping configuration.")
                return nil
            } else {
                throw error
            }
        }

        return try configure(resolvedConfiguration)
    }
    
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
    /// - Parameter configuration: The AmplifyConfiguration for specified Categories
    ///
    /// - Tag: Amplify.configure
    @discardableResult
    public static func configure(_ configuration: AmplifyConfiguration,
                                 mergeStrategy: ConfigurationMergeStrategy? = nil) throws -> AmplifyConfiguration? {
        log.info("Configuring")
        log.debug("Configuration: \(String(describing: configuration))")
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "Amplify has already been configured.",
                """
                Remove the duplicate call to `Amplify.configure()`
                """
            )
            throw error
        }

        let resolvedConfiguration: AmplifyConfiguration
        do {
            resolvedConfiguration = try Amplify.resolve(configuration: configuration)
        } catch {
            log.info("Failed to find Amplify configuration.")
            if isRunningForSwiftUIPreviews {
                log.info("Running for SwiftUI previews with no configuration file present, skipping configuration.")
                return nil
            } else {
                throw error
            }
        }

        // Always configure logging first since Auth dependings on logging
        try configure(CategoryType.logging.category, using: resolvedConfiguration)

        // Always configure Hub and Auth next, so they are available to other categories.
        // Auth is a special case for other plugins which depend on using Auth when being configured themselves.
        let manuallyConfiguredCategories = [CategoryType.hub, .auth]
        for categoryType in manuallyConfiguredCategories {
            try configure(categoryType.category, using: resolvedConfiguration)
        }

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        let remainingCategories = CategoryType.allCases.filter { !manuallyConfiguredCategories.contains($0) }
        for categoryType in remainingCategories {
            switch categoryType {
            case .analytics:
                try configure(Analytics, using: resolvedConfiguration)
            case .api:
                try configure(API, using: resolvedConfiguration)
            case .dataStore:
                try configure(DataStore, using: resolvedConfiguration)
            case .geo:
                try configure(Geo, using: resolvedConfiguration)
            case .predictions:
                try configure(Predictions, using: resolvedConfiguration)
            case .pushNotifications:
                try configure(Notifications.Push, using: resolvedConfiguration)
            case .storage:
                try configure(Storage, using: resolvedConfiguration)
            case .hub, .logging, .auth:
                // Already configured
                break
            }
        }
        isConfigured = true

        notifyAllHubChannels()
        return resolvedConfiguration
    }

    /// Notifies all hub channels that Amplify is configured, in case any plugins need to be notified of the end of the
    /// configuration phase (e.g., to set up cross-channel dependencies)
    private static func notifyAllHubChannels() {
        let payload = HubPayload(eventName: HubPayload.EventName.Amplify.configured)
        for channel in HubChannel.amplifyChannels {
            Hub.plugins.values.forEach { $0.dispatch(to: channel, payload: payload) }
        }
    }

    /// If `candidate` is `CategoryConfigurable`, then invokes `candidate.configure(using: configuration)`.
    private static func configure(_ candidate: Category, using configuration: AmplifyConfiguration) throws {
        guard let configurable = candidate as? CategoryConfigurable else {
            return
        }

        try configurable.configure(using: configuration)
    }

    /// Configures a list of plugins with the specified CategoryConfiguration. If any configurations do not match the
    /// specified plugins, emits a log warning.
    static func configure(plugins: [Plugin], using configuration: CategoryConfiguration?) throws {
        var pluginConfigurations = configuration?.plugins

        for plugin in plugins {
            let pluginConfiguration = pluginConfigurations?[plugin.key]
            try plugin.configure(using: pluginConfiguration)
            pluginConfigurations?.removeValue(forKey: plugin.key)
        }

        if let pluginKeys = pluginConfigurations?.keys {
            for unusedPluginKey in pluginKeys {
                log.warn("No plugin found for configuration key `\(unusedPluginKey)`. Add a plugin for that key.")
            }
        }
    }

    //// Indicates is the runtime is for SwiftUI Previews
    private static var isRunningForSwiftUIPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    }

}
