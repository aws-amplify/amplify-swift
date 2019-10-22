//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias PluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct PluginErrorConstants {
    static let decodeConfigurationError: PluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: PluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys")

    static let missingPinpointAnalyicsConfiguration: PluginErrorString = (
        "Plugin is missing `PinpointAnalytics` section.",
        "Add the `PinpointAnalytics` section to the plugin.")

    static let pinpointAnalyticsConfigurationExpected: PluginErrorString = (
        "Configuration at `PinpointAnalytics` is not a dictionary literal",
        "Make sure the value for the `PinpointAnalytics` is a dictionary literal with `AppId` and `Region`")

    static let missingPinpointTargetingConfiguration: PluginErrorString = (
        "Plugin is missing `PinpointTargeting` section.",
        "Add the `PinpointTargeting` section to the plugin.")

    static let pinpointTargetingConfigurationExpected: PluginErrorString = (
        "Configuration at `PinpointTargeting` is not a dictionary literal",
        "Make sure the value for the `PinpointTargeting` is a dictionary literal with `Region`")

    static let missingAppId: PluginErrorString = (
        "AppId is missing",
        "Add AppId to the configuration")

    static let invalidAppId: PluginErrorString = (
        "AppId is not a string",
        "Ensure AppId is a string")

    static let emptyAppId: PluginErrorString = (
        "AppId is specified but is empty",
        "AppId should not be empty")

    static let missingRegion: PluginErrorString = (
        "Region is missing",
        "Add region to the configuration")

    static let invalidRegion: PluginErrorString = (
        "Region is invalid",
        "Ensure Region is a valid region value")

    static let emptyRegion: PluginErrorString = (
        "Region is empty",
        "Ensure should not be empty")

    static let invalidAutoFlushEventsInterval: PluginErrorString = (
        "AutoFlushEventsInterval is not a number or is less than 0",
        "Ensure AutoFlushEventsInterval is zero or positive number")

    static let invalidTrackAppSessions: PluginErrorString = (
        "TrackAppSessions is not a boolean value",
        "Ensure TrackAppSessions is either `true` or `false`")

    static let invalidAutoSessionTrackingInterval: PluginErrorString = (
        "AutoSessionTrackingInterval is not a number of is less than 0",
        "Ensure AutoSessionTrackingInterval is zero or positive number")

    static let pinpointAnalyticsServiceConfigurationError: PluginErrorString = (
        "Could not instantiate service configuration from pinpoint analytics region",
        "Make sure the pinpoint analytics region and cognito credentials provider are correct")

    static let pinpointTargetingServiceConfigurationError: PluginErrorString = (
        "Could not instantiate service configuration from pinpoint targeting region",
        "Make sure the pinpoint targeting region and cognito credentials provider are correct")
}
