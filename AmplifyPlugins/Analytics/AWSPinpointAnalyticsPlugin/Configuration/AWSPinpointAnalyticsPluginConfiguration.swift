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
    let targetingRegion: String
    let autoFlushEventsInterval: Int
    let trackAppSessions: Bool
    let autoSessionTrackingInterval: Int

    init(_ configuration: JSONValue) throws {
        guard case let .object(configObject) = configuration else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.configurationObjectExpected.errorDescription,
                AnalyticsPluginErrorConstant.configurationObjectExpected.recoverySuggestion
            )
        }

        guard let pinpointAnalyticsConfig =
            configObject[AWSPinpointAnalyticsPluginConfiguration.pinpointAnalyticsConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingPinpointAnalyicsConfiguration.errorDescription,
                AnalyticsPluginErrorConstant.missingPinpointAnalyicsConfiguration.recoverySuggestion
            )
        }

        guard case let .object(pinpointAnalyticsConfigObject) = pinpointAnalyticsConfig else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.pinpointAnalyticsConfigurationExpected.errorDescription,
                AnalyticsPluginErrorConstant.pinpointAnalyticsConfigurationExpected.recoverySuggestion
            )
        }

        guard let pinpointTargetingConfig = configObject[
            AWSPinpointAnalyticsPluginConfiguration.pinpointTargetingConfigKey
        ] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingPinpointTargetingConfiguration.errorDescription,
                AnalyticsPluginErrorConstant.missingPinpointTargetingConfiguration.recoverySuggestion
            )
        }

        guard case let .object(pinpointTargetingConfigObject) = pinpointTargetingConfig else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.pinpointTargetingConfigurationExpected.errorDescription,
                AnalyticsPluginErrorConstant.pinpointTargetingConfigurationExpected.recoverySuggestion
            )
        }

        let appId = try AWSPinpointAnalyticsPluginConfiguration.getAppId(pinpointAnalyticsConfigObject)
        let region = try AWSPinpointAnalyticsPluginConfiguration.getRegion(pinpointAnalyticsConfigObject)
        let targetingRegion = try AWSPinpointAnalyticsPluginConfiguration.getRegion(pinpointTargetingConfigObject)
        let autoFlushEventsInterval =
            try AWSPinpointAnalyticsPluginConfiguration.getAutoFlushEventsInterval(configObject)
        let trackAppSessions = try AWSPinpointAnalyticsPluginConfiguration.getTrackAppSessions(configObject)
        let autoSessionTrackingInterval =
            try AWSPinpointAnalyticsPluginConfiguration.getAutoSessionTrackingInterval(configObject)

        self.init(appId: appId,
                  region: region,
                  targetingRegion: targetingRegion,
                  autoFlushEventsInterval: autoFlushEventsInterval,
                  trackAppSessions: trackAppSessions,
                  autoSessionTrackingInterval: autoSessionTrackingInterval)
    }

    init(appId: String,
         region: String,
         targetingRegion: String,
         autoFlushEventsInterval: Int,
         trackAppSessions: Bool,
         autoSessionTrackingInterval: Int) {
        self.appId = appId
        self.region = region
        self.targetingRegion = targetingRegion
        self.autoFlushEventsInterval = autoFlushEventsInterval
        self.trackAppSessions = trackAppSessions
        self.autoSessionTrackingInterval = autoSessionTrackingInterval
    }

    private static func getAppId(_ configuration: [String: JSONValue]) throws -> String {
        guard let appId = configuration[appIdConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingAppId.errorDescription,
                AnalyticsPluginErrorConstant.missingAppId.recoverySuggestion
            )
        }

        guard case let .string(appIdValue) = appId else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidAppId.errorDescription,
                AnalyticsPluginErrorConstant.invalidAppId.recoverySuggestion
            )
        }

        if appIdValue.isEmpty {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.emptyAppId.errorDescription,
                AnalyticsPluginErrorConstant.emptyAppId.recoverySuggestion
            )
        }

        return appIdValue
    }

    private static func getRegion(_ configuration: [String: JSONValue]) throws -> String {
        guard let region = configuration[regionConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.missingRegion.errorDescription,
                AnalyticsPluginErrorConstant.missingRegion.recoverySuggestion
            )
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.invalidRegion.errorDescription,
                AnalyticsPluginErrorConstant.invalidRegion.recoverySuggestion
            )
        }

        // TODO: Validate if Unknown is a valid type
        if regionValue.isEmpty || regionValue == "Unknown" {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.emptyRegion.errorDescription,
                AnalyticsPluginErrorConstant.emptyRegion.recoverySuggestion
            )
        }

        return regionValue
    }

    private static func getAutoFlushEventsInterval(_ configuration: [String: JSONValue]) throws -> Int {
        guard let autoFlushEventsInterval = configuration[autoFlushEventsIntervalKey] else {
            return AWSPinpointAnalyticsPluginConfiguration.defaultAutoFlushEventsInterval
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
            return AWSPinpointAnalyticsPluginConfiguration.defaultTrackAppSession
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
            return AWSPinpointAnalyticsPluginConfiguration.defaultAutoSessionTrackingInterval
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
