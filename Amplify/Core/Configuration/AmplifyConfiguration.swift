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
        case analytics = "Analytics"
        case api = "API"
        case dataStore = "DataStore"
        case hub = "Hub"
        case logging = "Logging"
        case predictions = "Predictions"
        case storage = "Storage"
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
    /// - Parameter configuration: The AmplifyConfiguration for specified Categories
    public static func configure(_ configuration: AmplifyConfiguration? = nil) throws {
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

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                try Analytics.configure(using: configuration)
            case .api:
                try API.configure(using: configuration)
            case .dataStore:
                try DataStore.configure(using: configuration)
            case .hub:
                try Hub.configure(using: configuration)
            case .logging:
                try Logging.configure(using: configuration)
            case .predictions:
                try Predictions.configure(using: configuration)
            case .storage:
                try Storage.configure(using: configuration)
            }
        }

        isConfigured = true
    }

}
