//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
        "Make sure the value for the plugin is a dictionary literal with keys 'Bucket' and 'Region'")

    static let missingBucket: PluginErrorString = (
        "The 'Bucket' key is missing from the configuration",
        "Make sure 'Bucket' is in the dictionary for the plugin configuration")

    static let invalidBucket: PluginErrorString = (
        "The bucket is invalid",
        "The bucket should be a string value")

    static let emptyBucket: PluginErrorString = (
        "The bucket value is empty",
        "Add the bucket as the value to the 'Bucket' key in the plugin configuration")

    static let missingRegion: PluginErrorString = (
        "The 'Region' key is missing from the configuration",
        "Make sure 'Region' is in the dictionary for the plugin configuration")

    static let emptyRegion: PluginErrorString = (
        "The region value is empty",
        "Add the region as the value to the 'Region' key in the plugin configuration")

    static let invalidRegion: PluginErrorString = (
        "The region is invalid",
        "Make sure the region is of the AWS regions, like 'us-east-1', etc...")

    static let invalidDefaultAccessLevel: PluginErrorString = (
        "The default access level specified is invalid",
        "Specify an override with one of the valid access level values such as 'guest', 'protected', or 'private'.")

    static let serviceConfigurationInitializationError: PluginErrorString = (
        "Could not initialize service configuration",
        "This should not happen")

    static let transferUtilityInitializationError: PluginErrorString = (
        "Could not initialize transfer utility",
        "This should not happen")

}
