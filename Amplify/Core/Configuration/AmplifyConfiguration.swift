//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Configures the Amplify system with sub-configurations for each supported category
public struct AmplifyConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case analytics
        case api
        case dataStore
        case hub
        case logging
        case predictions
        case storage
    }

    /// Configurations for the Amplify Analytics category
    let analytics: AnalyticsCategoryConfiguration?

    /// Configurations for the Amplify API category
    let api: APICategoryConfiguration?

    /// Configurations for the Amplify API category
    let dataStore: DataStoreCategoryConfiguration?

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
                dataStore: DataStoreCategoryConfiguration? = nil,
                hub: HubCategoryConfiguration? = nil,
                logging: LoggingCategoryConfiguration? = nil,
                predictions: PredictionsCategoryConfiguration? = nil,
                storage: StorageCategoryConfiguration? = nil) {
        self.analytics = analytics
        self.api = api
        self.dataStore = dataStore
        self.hub = hub
        self.logging = logging
        self.predictions = predictions
        self.storage = storage
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

        // Always configure Logging and Hub first, so they are available to other categoories.
        try configure(Logging, using: configuration)
        try configure(Hub, using: configuration)

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        let remainingCategories = CategoryType.allCases.filter { $0 != .hub && $0 != .logging }
        for categoryType in remainingCategories {
            switch categoryType {
            case .analytics:
                try configure(Analytics, using: configuration)
            case .api:
                try configure(API, using: configuration)
            case .dataStore:
                try configure(DataStore, using: configuration)
            case .predictions:
                try configure(Predictions, using: configuration)
            case .storage:
                try configure(Storage, using: configuration)

            case .hub, .logging:
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
}
