//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// At its core, the Amplify class is simply a router that provides clients top-level access to categories and
/// configuration methods. It provides convenient access to default plugins via the top-level category properties,
/// but clients can access specific plugins by invoking `getPlugin` on a category and issuing methods directly to
/// that plugin.
///
/// - Warning: It is a serious error to invoke any of the category APIs (like `Analytics.record()` or
/// `API.mutate()`) without first registering plugins via `Amplify.add(plugin:)` and configuring Amplify via
/// `Amplify.configure()`. Such access will cause a preconditionFailure.
///
/// There are two exceptions to this. The `Logging` and `Hub` categories are configured with a default plugin that is
/// available at initialization.
///
/// - Tag: Amplify
public class Amplify: @unchecked Sendable {

    /// If `true`, `configure()` has already been invoked, and subsequent calls to `configure` will throw a
    /// ConfigurationError.amplifyAlreadyConfigured error.
    ///
    /// - Tag: Amplify.isConfigured
    private static let isConfiguredAtomic = AtomicValue<Bool>(initialValue: false)
    static var isConfigured: Bool {
        get { isConfiguredAtomic.get() }
        set { isConfiguredAtomic.set(newValue) }
    }

    // Storage for the categories themselves, which will be instantiated during configuration, and cleared during reset.
    // All category properties are protected with AtomicValue for thread safety.

    /// - Tag: Amplify.Analytics
    private static let analyticsAtomic = AtomicValue<AnalyticsCategory>(initialValue: AnalyticsCategory())
    public internal(set) static var Analytics: AnalyticsCategory {
        get { analyticsAtomic.get() }
        set { analyticsAtomic.set(newValue) }
    }

    /// - Tag: Amplify.API
    private static let apiAtomic = AtomicValue<APICategory>(initialValue: APICategory())
    public internal(set) static var API: APICategory {
        get { apiAtomic.get() }
        set { apiAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Auth
    private static let authAtomic = AtomicValue<AuthCategory>(initialValue: AuthCategory())
    public internal(set) static var Auth: AuthCategory {
        get { authAtomic.get() }
        set { authAtomic.set(newValue) }
    }

    /// - Tag: Amplify.DataStore
    private static let dataStoreAtomic = AtomicValue<DataStoreCategory>(initialValue: DataStoreCategory())
    public internal(set) static var DataStore: DataStoreCategory {
        get { dataStoreAtomic.get() }
        set { dataStoreAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Geo
    private static let geoAtomic = AtomicValue<GeoCategory>(initialValue: GeoCategory())
    public internal(set) static var Geo: GeoCategory {
        get { geoAtomic.get() }
        set { geoAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Hub
    private static let hubAtomic = AtomicValue<HubCategory>(initialValue: HubCategory())
    public internal(set) static var Hub: HubCategory {
        get { hubAtomic.get() }
        set { hubAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Notifications
    private static let notificationsAtomic = AtomicValue<NotificationsCategory>(initialValue: NotificationsCategory())
    public internal(set) static var Notifications: NotificationsCategory {
        get { notificationsAtomic.get() }
        set { notificationsAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Predictions
    private static let predictionsAtomic = AtomicValue<PredictionsCategory>(initialValue: PredictionsCategory())
    public internal(set) static var Predictions: PredictionsCategory {
        get { predictionsAtomic.get() }
        set { predictionsAtomic.set(newValue) }
    }

    /// - Tag: Amplify.Storage
    private static let storageAtomic = AtomicValue<StorageCategory>(initialValue: StorageCategory())
    public internal(set) static var Storage: StorageCategory {
        get { storageAtomic.get() }
        set { storageAtomic.set(newValue) }
    }

    /// Special case category. We protect this with an AtomicValue because it is used by reset()
    /// methods during setup & teardown of tests
    ///
    /// - Tag: Amplify.Logging
    public internal(set) static var Logging: LoggingCategory {
        get {
            loggingAtomic.get()
        }
        set {
            loggingAtomic.set(newValue)
        }
    }
    private static let loggingAtomic = AtomicValue<LoggingCategory>(initialValue: LoggingCategory())

    // swiftlint:disable cyclomatic_complexity

    /// Adds `plugin` to the category
    ///
    /// See: [Category.removePlugin(for:)](x-source-tag://Category.removePlugin)
    ///
    /// - Parameter plugin: The plugin to add
    /// - Tag: Amplify.add_plugin
    public static func add(plugin: some Plugin) throws {
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
        case let plugin as PushNotificationsCategoryPlugin:
            try Notifications.Push.add(plugin: plugin)
        case let plugin as StorageCategoryPlugin:
            try Storage.add(plugin: plugin)
        default:
            throw PluginError.pluginConfigurationError(
                "Plugin category does not exist.",
                "Verify that the library version is correct and supports the plugin's category."
            )
        }

        // swiftlint:enable cyclomatic_complexity
    }
}

extension Amplify: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: String(describing: self))
    }

    public var log: Logger {
        Self.log
    }
}
