//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Configures the Amplify system with sub-configurations for each supported category
public struct AmplifyConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case analytics
        case api
        case auth
        case dataStore
        case geo
        case hub
        case logging
        case predictions
        case storage
    }

    /// Configurations for the Amplify Analytics category
    let analytics: AnalyticsCategoryConfiguration?

    /// Configurations for the Amplify API category
    let api: APICategoryConfiguration?

    /// Configurations for the Amplify Auth category
    let auth: AuthCategoryConfiguration?

    /// Configurations for the Amplify DataStore category
    let dataStore: DataStoreCategoryConfiguration?

    /// Configurations for the Amplify Geo category
    let geo: GeoCategoryConfiguration?

    /// Configurations for the Amplify Hub category
    let hub: HubCategoryConfiguration?

    /// Configurations for the Amplify Logging category
    let logging: LoggingCategoryConfiguration?

    /// Configurations for the Amplify Predictions category
    let predictions: PredictionsCategoryConfiguration?

    /// Configurations for the Amplify Storage category
    let storage: StorageCategoryConfiguration?

    public init(analytics: AnalyticsCategoryConfiguration? = nil,
                api: APICategoryConfiguration? = nil,
                auth: AuthCategoryConfiguration? = nil,
                dataStore: DataStoreCategoryConfiguration? = nil,
                geo: GeoCategoryConfiguration? = nil,
                hub: HubCategoryConfiguration? = nil,
                logging: LoggingCategoryConfiguration? = nil,
                predictions: PredictionsCategoryConfiguration? = nil,
                storage: StorageCategoryConfiguration? = nil) {
        self.analytics = analytics
        self.api = api
        self.auth = auth
        self.dataStore = dataStore
        self.geo = geo
        self.hub = hub
        self.logging = logging
        self.predictions = predictions
        self.storage = storage
    }

    /// Initialize `AmplifyConfiguration` by loading it from a URL representing the configuration file.
    public init(configurationFile url: URL) throws {
        self = try AmplifyConfiguration.loadAmplifyConfiguration(from: url)
    }

}

// MARK: - Configure

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
    /// - Parameter configuration: The AmplifyConfiguration for specified Categories
    public static func configure(_ configuration: AmplifyConfiguration? = nil) throws {
        guard !isRunningForSwiftUIPreviews else {
            log.info("Running for SwiftUI reviews, skipping configuration.")
            return
        }
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

        let configuration = try Amplify.resolve(configuration: configuration)

        // Always configure Logging, Hub and Auth first, so they are available to other categories.
        // Auth is a special case for other plugins which depend on using Auth when being configured themselves.
        let manuallyConfiguredCategories = [CategoryType.logging, .hub, .auth]
        for categoryType in manuallyConfiguredCategories {
            try configure(categoryType.category, using: configuration)
        }

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        let remainingCategories = CategoryType.allCases.filter { !manuallyConfiguredCategories.contains($0) }
        for categoryType in remainingCategories {
            switch categoryType {
            case .analytics:
                try configure(Analytics, using: configuration)
            case .api:
                try configure(API, using: configuration)
            case .dataStore:
                try configure(DataStore, using: configuration)
            case .geo:
                try configure(Geo, using: configuration)
            case .predictions:
                try configure(Predictions, using: configuration)
            case .storage:
                try configure(Storage, using: configuration)
            case .hub, .logging, .auth:
                // Already configured
                break
            }
        }
        isConfigured = true

        notifyAllHubChannels()
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
