//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint

public struct AWSPinpointAnalyticsPluginConfiguration {

    static let pinpointAnalyticsConfigKey = "PinpointAnalytics"
    static let pinpointTargetingConfigKey = "PinpointTargeting"
    static let autoFlushEventsIntervalKey = "AutoFlushEventsInterval"
    static let trackAppSessionsKey = "TrackAppSessions"
    static let autoSessionTrackingIntervalKey = "AutoSessionTrackingInterval"
    static let appIdConfigKey = "AppId"
    static let regionConfigKey = "Region"

    static let defaultAutoFlushEventsInterval = 10
    static let defaultTrackAppSession = true
    static let defaultAutoSessionTrackingInterval = 5

    let appId: String
    let region: AWSRegionType
    let targetingRegion: AWSRegionType
    let autoFlushEventsInterval: Int
    let trackAppSessions: Bool
    let autoSessionTrackingInterval: Int

    init(_ configuration: JSONValue) throws {
        guard case let .object(configObject) = configuration else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.configurationObjectExpected.errorDescription,
                AnalyticsErrorConstants.configurationObjectExpected.recoverySuggestion)
        }

        guard let pinpointAnalyticsConfig =
            configObject[AWSPinpointAnalyticsPluginConfiguration.pinpointAnalyticsConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.missingPinpointAnalyicsConfiguration.errorDescription,
                AnalyticsErrorConstants.missingPinpointAnalyicsConfiguration.recoverySuggestion)
        }

        guard case let .object(pinpointAnalyticsConfigObject) = pinpointAnalyticsConfig else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.pinpointAnalyticsConfigurationExpected.errorDescription,
                AnalyticsErrorConstants.pinpointAnalyticsConfigurationExpected.recoverySuggestion)
        }

        guard let pinpointTargetingConfig = configObject[
            AWSPinpointAnalyticsPluginConfiguration.pinpointTargetingConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.missingPinpointTargetingConfiguration.errorDescription,
                AnalyticsErrorConstants.missingPinpointTargetingConfiguration.recoverySuggestion)
        }

        guard case let .object(pinpointTargetingConfigObject) = pinpointTargetingConfig else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.pinpointTargetingConfigurationExpected.errorDescription,
                AnalyticsErrorConstants.pinpointTargetingConfigurationExpected.recoverySuggestion)
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
         region: AWSRegionType,
         targetingRegion: AWSRegionType,
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
                AnalyticsErrorConstants.missingAppId.errorDescription,
                AnalyticsErrorConstants.missingAppId.recoverySuggestion)
        }

        guard case let .string(appIdValue) = appId else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidAppId.errorDescription,
                AnalyticsErrorConstants.invalidAppId.recoverySuggestion)
        }

        if appIdValue.isEmpty {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.emptyAppId.errorDescription,
                AnalyticsErrorConstants.emptyAppId.recoverySuggestion)
        }

        return appIdValue
    }

    private static func getRegion(_ configuration: [String: JSONValue]) throws -> AWSRegionType {
        guard let region = configuration[regionConfigKey] else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.missingRegion.errorDescription,
                AnalyticsErrorConstants.missingRegion.recoverySuggestion)
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidRegion.errorDescription,
                AnalyticsErrorConstants.invalidRegion.recoverySuggestion)
        }

        if regionValue.isEmpty {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.emptyRegion.errorDescription,
                AnalyticsErrorConstants.emptyRegion.recoverySuggestion)
        }

        let regionType = regionValue.aws_regionTypeValue()
        guard regionType != AWSRegionType.Unknown else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidRegion.errorDescription,
                AnalyticsErrorConstants.invalidRegion.recoverySuggestion)
        }

        return regionType
    }

    private static func getAutoFlushEventsInterval(_ configuration: [String: JSONValue]) throws -> Int {
        guard let autoFlushEventsInterval = configuration[autoFlushEventsIntervalKey] else {
            return AWSPinpointAnalyticsPluginConfiguration.defaultAutoFlushEventsInterval
        }

        guard case let .number(autoFlushEventsIntervalValue) = autoFlushEventsInterval else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidAutoFlushEventsInterval.errorDescription,
                AnalyticsErrorConstants.invalidAutoFlushEventsInterval.recoverySuggestion)
        }

        if autoFlushEventsIntervalValue < 0 {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidAutoFlushEventsInterval.errorDescription,
                AnalyticsErrorConstants.invalidAutoFlushEventsInterval.recoverySuggestion)
        }

        return Int(autoFlushEventsIntervalValue)
    }

    private static func getTrackAppSessions(_ configuration: [String: JSONValue]) throws -> Bool {
        guard let trackAppSessions = configuration[trackAppSessionsKey] else {
            return AWSPinpointAnalyticsPluginConfiguration.defaultTrackAppSession
        }

        guard case let .boolean(trackAppSessionsValue) = trackAppSessions else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidTrackAppSessions.errorDescription,
                AnalyticsErrorConstants.invalidTrackAppSessions.recoverySuggestion)
        }

        return trackAppSessionsValue
    }

    private static func getAutoSessionTrackingInterval(_ configuration: [String: JSONValue]) throws -> Int {

        guard let autoSessionTrackingInterval = configuration[autoSessionTrackingIntervalKey] else {
            return AWSPinpointAnalyticsPluginConfiguration.defaultAutoSessionTrackingInterval
        }

        guard case let .number(autoSessionTrackingIntervalValue) = autoSessionTrackingInterval else {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidAutoSessionTrackingInterval.errorDescription,
                AnalyticsErrorConstants.invalidAutoSessionTrackingInterval.recoverySuggestion)
        }

        // TODO: more upper limit validation here due to some iOS background processing limitations
        if autoSessionTrackingIntervalValue < 0 {
            throw PluginError.pluginConfigurationError(
                AnalyticsErrorConstants.invalidAutoSessionTrackingInterval.errorDescription,
                AnalyticsErrorConstants.invalidAutoSessionTrackingInterval.recoverySuggestion)
        }

        return Int(autoSessionTrackingIntervalValue)
    }
}
