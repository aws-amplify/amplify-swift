//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias AnalyticsPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AnalyticsPluginErrorConstant {
    static let decodeConfigurationError: AnalyticsPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue"
    )

    static let configurationObjectExpected: AnalyticsPluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys"
    )

    static let missingPinpointAnalyicsConfiguration: AnalyticsPluginErrorString = (
        "Plugin is missing `PinpointAnalytics` section.",
        "Add the `PinpointAnalytics` section to the plugin."
    )

    static let pinpointAnalyticsConfigurationExpected: AnalyticsPluginErrorString = (
        "Configuration at `PinpointAnalytics` is not a dictionary literal",
        "Make sure the value for the `PinpointAnalytics` is a dictionary literal with `AppId` and `Region`"
    )

    static let pinpointTargetingConfigurationExpected: AnalyticsPluginErrorString = (
        "Configuration at `PinpointTargeting` is not a dictionary literal",
        "Make sure the value for the `PinpointTargeting` is a dictionary literal with `Region`"
    )

    static let missingAppId: AnalyticsPluginErrorString = (
        "AppId is missing",
        "Add AppId to the configuration"
    )

    static let invalidAppId: AnalyticsPluginErrorString = (
        "AppId is not a string",
        "Ensure AppId is a string"
    )

    static let emptyAppId: AnalyticsPluginErrorString = (
        "AppId is specified but is empty",
        "AppId should not be empty"
    )

    static let missingRegion: AnalyticsPluginErrorString = (
        "Region is missing",
        "Add region to the configuration"
    )

    static let invalidRegion: AnalyticsPluginErrorString = (
        "Region is invalid",
        "Ensure Region is a valid region value"
    )

    static let emptyRegion: AnalyticsPluginErrorString = (
        "Region is empty",
        "Ensure should not be empty"
    )

    static let invalidAutoFlushEventsInterval: AnalyticsPluginErrorString = (
        "AutoFlushEventsInterval is not a number or is less than 0",
        "Ensure AutoFlushEventsInterval is zero or positive number"
    )

    static let invalidTrackAppSessions: AnalyticsPluginErrorString = (
        "TrackAppSessions is not a boolean value",
        "Ensure TrackAppSessions is either `true` or `false`"
    )

    static let invalidAutoSessionTrackingInterval: AnalyticsPluginErrorString = (
        "AutoSessionTrackingInterval is not a number of is less than 0",
        "Ensure AutoSessionTrackingInterval is zero or positive number"
    )

    // swiftlint:disable:next identifier_name
    static let pinpointAnalyticsServiceConfigurationError: AnalyticsPluginErrorString = (
        "Could not instantiate service configuration from pinpoint analytics region",
        "Make sure the pinpoint analytics region and cognito credentials provider are correct"
    )

    // swiftlint:disable:next identifier_name
    static let pinpointTargetingServiceConfigurationError: AnalyticsPluginErrorString = (
        "Could not instantiate service configuration from pinpoint targeting region",
        "Make sure the pinpoint targeting region and cognito credentials provider are correct"
    )
}
