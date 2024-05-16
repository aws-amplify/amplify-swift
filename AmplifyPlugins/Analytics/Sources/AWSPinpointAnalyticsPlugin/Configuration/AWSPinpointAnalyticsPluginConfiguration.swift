//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import AWSPinpoint
import AWSClientRuntime
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

public struct AWSPinpointAnalyticsPluginConfiguration {
    static let pinpointAnalyticsConfigKey = "pinpointAnalytics"
    static let pinpointTargetingConfigKey = "pinpointTargeting"
    static let autoFlushEventsIntervalKey = "autoFlushEventsInterval"
    static let trackAppSessionsKey = "trackAppSessions"
    static let autoSessionTrackingIntervalKey = "autoSessionTrackingInterval"
    static let appIdConfigKey = "appId"
    static let regionConfigKey = "region"

    static let defaultAutoSessionTrackingInterval: TimeInterval = {
    #if os(macOS)
        .infinity
    #else
        5
    #endif
    }()

    let appId: String
    let region: String

    let autoSessionTrackingInterval: TimeInterval

    let options: AWSPinpointAnalyticsPlugin.Options

    private static let logger = Amplify.Logging.logger(forCategory: CategoryType.analytics.displayName, forNamespace: String(describing: Self.self))

    init(_ configuration: JSONValue, _ options: AWSPinpointAnalyticsPlugin.Options? = nil) throws {
        guard case let .object(configObject) = configuration else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.configurationObjectExpected.errorDescription,
                AnalyticsPluginErrorConstant.configurationObjectExpected.recoverySuggestion
            )
        }

        guard let pinpointAnalyticsConfig = configObject[Self.pinpointAnalyticsConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingPinpointAnalyicsConfiguration.errorDescription,
                AnalyticsPluginErrorConstant.missingPinpointAnalyicsConfiguration.recoverySuggestion
            )
        }

        let pluginConfiguration = try AWSPinpointPluginConfiguration(pinpointAnalyticsConfig)

        let configOptions: AWSPinpointAnalyticsPlugin.Options
        if let options {
            configOptions = options
        } else {
            configOptions = .init(
                autoFlushEventsInterval: try Self.getAutoFlushEventsInterval(configObject),
                trackAppSessions: try Self.getTrackAppSessions(configObject))
        }
        let autoSessionTrackingInterval = try Self.getAutoSessionTrackingInterval(configObject)

        // Warn users in case they set different regions between pinpointTargeting and pinpointAnalytics
        if let pinpointTargetingJson = configObject[Self.pinpointTargetingConfigKey],
           let pinpointTargetingConfig = try? AWSPinpointPluginConfiguration(pinpointTargetingJson),
           pinpointTargetingConfig.region != pluginConfiguration.region {
            Self.logger.warn("Having different regions for Analytics and Targeting operations is not supported. The Analytics region will be used.")
        }

        self.init(appId: pluginConfiguration.appId,
                  region: pluginConfiguration.region,
                  autoSessionTrackingInterval: autoSessionTrackingInterval,
                  options: configOptions)
    }

    init(_ configuration: AmplifyOutputsData,
         options: AWSPinpointAnalyticsPlugin.Options) throws {
        guard let analyticsConfig = configuration.analytics else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingAnalyticsCategoryConfiguration.errorDescription,
                AnalyticsPluginErrorConstant.missingAnalyticsCategoryConfiguration.recoverySuggestion
            )
        }

        guard let pinpointAnalyticsConfig = analyticsConfig.amazonPinpoint else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingAmazonPinpointConfiguration.errorDescription,
                AnalyticsPluginErrorConstant.missingAmazonPinpointConfiguration.recoverySuggestion
            )
        }

        self.init(appId: pinpointAnalyticsConfig.appId,
                  region: pinpointAnalyticsConfig.awsRegion,
                  autoSessionTrackingInterval: Self.defaultAutoSessionTrackingInterval,
                  options: options)
    }

    init(appId: String,
         region: String,
         autoSessionTrackingInterval: TimeInterval,
         options: AWSPinpointAnalyticsPlugin.Options) {
        self.appId = appId
        self.region = region
        self.autoSessionTrackingInterval = autoSessionTrackingInterval
        self.options = options
    }

    private static func getAutoFlushEventsInterval(_ configuration: [String: JSONValue]) throws -> TimeInterval {
        guard let autoFlushEventsInterval = configuration[autoFlushEventsIntervalKey] else {
            return AWSPinpointAnalyticsPlugin.Options.defaultAutoFlushEventsInterval
        }

        guard case let .number(autoFlushEventsIntervalValue) = autoFlushEventsInterval else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidAutoFlushEventsInterval.errorDescription,
                AnalyticsPluginErrorConstant.invalidAutoFlushEventsInterval.recoverySuggestion
            )
        }

        if autoFlushEventsIntervalValue < 0 {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidAutoFlushEventsInterval.errorDescription,
                AnalyticsPluginErrorConstant.invalidAutoFlushEventsInterval.recoverySuggestion
            )
        }

        return TimeInterval(autoFlushEventsIntervalValue)
    }

    private static func getTrackAppSessions(_ configuration: [String: JSONValue]) throws -> Bool {
        guard let trackAppSessions = configuration[trackAppSessionsKey] else {
            return AWSPinpointAnalyticsPlugin.Options.defaultTrackAppSession
        }

        guard case let .boolean(trackAppSessionsValue) = trackAppSessions else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidTrackAppSessions.errorDescription,
                AnalyticsPluginErrorConstant.invalidTrackAppSessions.recoverySuggestion
            )
        }

        return trackAppSessionsValue
    }

    private static func getAutoSessionTrackingInterval(_ configuration: [String: JSONValue]) throws -> TimeInterval {
        guard let autoSessionTrackingInterval = configuration[autoSessionTrackingIntervalKey] else {
            return Self.defaultAutoSessionTrackingInterval
        }

        guard case let .number(autoSessionTrackingIntervalValue) = autoSessionTrackingInterval else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidAutoSessionTrackingInterval.errorDescription,
                AnalyticsPluginErrorConstant.invalidAutoSessionTrackingInterval.recoverySuggestion
            )
        }

        // TODO: more upper limit validation here due to some iOS background processing limitations
        if autoSessionTrackingIntervalValue < 0 {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidAutoSessionTrackingInterval.errorDescription,
                AnalyticsPluginErrorConstant.invalidAutoSessionTrackingInterval.recoverySuggestion
            )
        }

        return autoSessionTrackingIntervalValue
    }
}
