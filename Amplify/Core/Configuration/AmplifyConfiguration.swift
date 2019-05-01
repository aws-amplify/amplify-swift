//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Configures the Amplify system with sub-configurations for each supported category
public protocol AmplifyConfiguration {
    /// Configurations for the Amplify Analytics category
    var analytics: CategoryConfiguration? { get }

    /// Configurations for the Amplify API category
    var api: CategoryConfiguration? { get }

    /// Configurations for the Amplify Auth category
    var auth: CategoryConfiguration? { get }

    /// Configurations for the Amplify Hub category
    var hub: CategoryConfiguration? { get }

    /// Configurations for the Amplify Logging category
    var logging: CategoryConfiguration? { get }

    /// Configurations for the Amplify Storage category
    var storage: CategoryConfiguration? { get }
}

extension Amplify {

    /// Configures Amplify with the specified configuration.
    ///
    /// This method must not be invoked more than once without first calling `reset()`.
    ///
    /// - Parameter configuration: The AmplifyConfiguration for specified Categories
    /// - Throws:
    ///   - ConfigurationError.amplifyAlreadyConfigured: If `configure` has already been invoked, but `reset` has not
    ///   - PluginError.noSuchPlugin: If one of the configurations specifies a plugin key that has not been added
    public static func configure(_ configuration: AmplifyConfiguration) throws {
        guard !isConfigured else {
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "Amplify has already been configured.",
                """
                Either remove the duplicate call to `Amplify.configure()`, or call \
                `Amplify.reset()` before issuing the second call to `configure()`
                """
            )
            throw error
        }

        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                try Analytics.configure(using: configuration)
            case .api:
                try API.configure(using: configuration)
            case .auth:
                try Auth.configure(using: configuration)
            case .hub:
                try Hub.configure(using: configuration)
            case .logging:
                try Logging.configure(using: configuration)
            case .storage:
                try Storage.configure(using: configuration)
            }
        }

        isConfigured = true
    }

    /// Resets the state of the Amplify framework. Specifically, this method:
    /// - Invokes `reset` on each configured category, which clears that categories registered plugins.
    /// - Releases each configured category, and replaces the instances referred to by the static accessor properties
    ///   (e.g., `Amplify.Hub`) with new instances. These instances must subsequently have providers added, and be
    ///   configured prior to use.
    public static func reset() {
        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future
        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                Analytics.resetPlugins()
                Analytics = AnalyticsCategory()
            case .api:
                API.resetPlugins()
                API = APICategory()
            case .auth:
                Auth.resetPlugins()
                Auth = AuthCategory()
            case .hub:
                Hub.resetPlugins()
                Hub = HubCategory()
            case .logging:
                Logging.resetPlugins()
                Logging = LoggingCategory()
            case .storage:
                Storage.resetPlugins()
                Storage = StorageCategory()
            }
        }

        isConfigured = false
    }
}

/// A basic struct containing Amplify configurations. In addition to this being the value into which default
/// configurations from `amplifyconfiguration.json` are read, this structure can also be used to override global
/// configurations at runtime.
public struct BasicAmplifyConfiguration: AmplifyConfiguration {
    public let analytics: CategoryConfiguration?
    public let api: CategoryConfiguration?
    public let auth: CategoryConfiguration?
    public let hub: CategoryConfiguration?
    public let logging: CategoryConfiguration?
    public let storage: CategoryConfiguration?

    public init(analytics: CategoryConfiguration? = nil,
                api: CategoryConfiguration? = nil,
                auth: CategoryConfiguration? = nil,
                hub: CategoryConfiguration? = nil,
                logging: CategoryConfiguration? = nil,
                storage: CategoryConfiguration? = nil) {
        self.analytics = analytics
        self.api = api
        self.auth = auth
        self.hub = hub
        self.logging = logging
        self.storage = storage
    }
}
