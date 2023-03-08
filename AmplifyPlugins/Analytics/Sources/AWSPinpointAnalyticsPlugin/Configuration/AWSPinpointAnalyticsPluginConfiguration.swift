//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
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

    static let defaultAutoFlushEventsInterval = 60
    static let defaultTrackAppSession = true
    static let defaultAutoSessionTrackingInterval: Int = {
    #if os(macOS)
        .max
    #else
        5
    #endif
    }()

    let appId: String
    let region: String
    let autoFlushEventsInterval: Int
    let trackAppSessions: Bool
    let autoSessionTrackingInterval: Int
    
    private static let logger = Amplify.Logging.logger(forCategory: String(describing: Self.self))

    init(_ configuration: JSONValue) throws {
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
        
        let autoFlushEventsInterval = try Self.getAutoFlushEventsInterval(configObject)
        let trackAppSessions = try Self.getTrackAppSessions(configObject)
        let autoSessionTrackingInterval = try Self.getAutoSessionTrackingInterval(configObject)
        
        // Warn users in case they set different regions between pinpointTargeting and pinpointAnalytics
        if let pinpointTargetingJson = configObject[Self.pinpointTargetingConfigKey],
           let pinpointTargetingConfig = try? AWSPinpointPluginConfiguration(pinpointTargetingJson),
           pinpointTargetingConfig.region != pluginConfiguration.region {
            Self.logger.warn("Having different regions for Analytics and Targeting operations is not supported. The Analytics region will be used.")
        }

        self.init(appId: pluginConfiguration.appId,
                  region: pluginConfiguration.region,
                  autoFlushEventsInterval: autoFlushEventsInterval,
                  trackAppSessions: trackAppSessions,
                  autoSessionTrackingInterval: autoSessionTrackingInterval)
    }

    init(appId: String,
         region: String,
         autoFlushEventsInterval: Int,
         trackAppSessions: Bool,
         autoSessionTrackingInterval: Int) {
        self.appId = appId
        self.region = region
        self.autoFlushEventsInterval = autoFlushEventsInterval
        self.trackAppSessions = trackAppSessions
        self.autoSessionTrackingInterval = autoSessionTrackingInterval
    }

    private static func getAutoFlushEventsInterval(_ configuration: [String: JSONValue]) throws -> Int {
        guard let autoFlushEventsInterval = configuration[autoFlushEventsIntervalKey] else {
            return Self.defaultAutoFlushEventsInterval
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

        return Int(autoFlushEventsIntervalValue)
    }

    private static func getTrackAppSessions(_ configuration: [String: JSONValue]) throws -> Bool {
        guard let trackAppSessions = configuration[trackAppSessionsKey] else {
            return Self.defaultTrackAppSession
        }

        guard case let .boolean(trackAppSessionsValue) = trackAppSessions else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidTrackAppSessions.errorDescription,
                AnalyticsPluginErrorConstant.invalidTrackAppSessions.recoverySuggestion
            )
        }

        return trackAppSessionsValue
    }

    private static func getAutoSessionTrackingInterval(_ configuration: [String: JSONValue]) throws -> Int {
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

        return Int(autoSessionTrackingIntervalValue)
    }
}
