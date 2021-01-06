//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias PluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct PluginErrorMessage {
    static let decodeConfigurationError: PluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: PluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys 'identify', 'convert' and 'interpret'")

    static let missingCollectionId: PluginErrorString = (
        "The CollectionId is missing from the configuration",
        "Make sure CollectionId is in the dictionary for the plugin configuration")

    static let invalidCollection: PluginErrorString = (
        "The collection is invalid",
        "The collection should be a string value")

    static let emptyCollection: PluginErrorString = (
        "The collection value is empty",
        "Add the collection as the value to the 'collectionId' key in the plugin configuration")

    static let missingRegion: PluginErrorString = (
        "The 'Region' key is missing from the configuration",
        "Make sure 'Region' is in the dictionary for the plugin configuration")

    static let emptyRegion: PluginErrorString = (
        "The region value is empty",
        "Add the region as the value to the 'Region' key in the plugin configuration")

    static let invalidRegion: PluginErrorString = (
        "The region is invalid",
        "Make sure the region is one of the AWS regions, like 'us-east-1', etc...")

    static let serviceConfigurationInitializationError: PluginErrorString = (
        "Could not initialize service configuration",
        "This should not happen")

}
