//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias AnalyticsErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AnalyticsErrorConstants {
    static let decodeConfigurationError: AnalyticsErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: AnalyticsErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys")

    static let missingPinpointAnalyicsConfiguration: AnalyticsErrorString = (
        "Plugin is missing `PinpointAnalytics` section.",
        "Add the `PinpointAnalytics` section to the plugin.")

    static let pinpointAnalyticsConfigurationExpected: AnalyticsErrorString = (
        "Configuration at `PinpointAnalytics` is not a dictionary literal",
        "Make sure the value for the `PinpointAnalytics` is a dictionary literal with `AppId` and `Region`")

    static let missingPinpointTargetingConfiguration: AnalyticsErrorString = (
        "Plugin is missing `PinpointTargeting` section.",
        "Add the `PinpointTargeting` section to the plugin.")

    static let pinpointTargetingConfigurationExpected: AnalyticsErrorString = (
        "Configuration at `PinpointTargeting` is not a dictionary literal",
        "Make sure the value for the `PinpointTargeting` is a dictionary literal with `Region`")

    static let missingAppId: AnalyticsErrorString = (
        "AppId is missing",
        "Add AppId to the configuration")

    static let invalidAppId: AnalyticsErrorString = (
        "AppId is not a string",
        "Ensure AppId is a string")

    static let emptyAppId: AnalyticsErrorString = (
        "AppId is specified but is empty",
        "AppId should not be empty")

    static let missingRegion: AnalyticsErrorString = (
        "Region is missing",
        "Add region to the configuration")

    static let invalidRegion: AnalyticsErrorString = (
        "Region is invalid",
        "Ensure Region is a valid region value")

    static let emptyRegion: AnalyticsErrorString = (
        "Region is empty",
        "Ensure should not be empty")

    static let invalidAutoFlushEventsInterval: AnalyticsErrorString = (
        "AutoFlushEventsInterval is not a number or is less than 0",
        "Ensure AutoFlushEventsInterval is zero or positive number")

    static let invalidTrackAppSessions: AnalyticsErrorString = (
        "TrackAppSessions is not a boolean value",
        "Ensure TrackAppSessions is either `true` or `false`")

    static let invalidAutoSessionTrackingInterval: AnalyticsErrorString = (
        "AutoSessionTrackingInterval is not a number of is less than 0",
        "Ensure AutoSessionTrackingInterval is zero or positive number")

    static let pinpointAnalyticsServiceConfigurationError: AnalyticsErrorString = (
        "Could not instantiate service configuration from pinpoint analytics region",
        "Make sure the pinpoint analytics region and cognito credentials provider are correct")

    static let pinpointTargetingServiceConfigurationError: AnalyticsErrorString = (
        "Could not instantiate service configuration from pinpoint targeting region",
        "Make sure the pinpoint targeting region and cognito credentials provider are correct")
}
