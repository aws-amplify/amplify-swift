//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias PluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct CoreMLPluginErrorString {
    static let decodeConfigurationError: PluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: PluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys 'Bucket' and 'Region'")

    static let operationNotSupported: PluginErrorString = (
        "This operation is not supported.",
        "Operation is not currently supported by offline mode.")

    static let detectTextNoResult: PluginErrorString = (
        "Detect text return with no result",
        "The input might not have enough data points to find text")

    static let detectLabelsNoResult: PluginErrorString = (
        "Detect labels return with no result",
        "The input might not have enough data points to find labels")

    static let detectEntitiesNoResult: PluginErrorString = (
        "Detect entities returned with no result",
        "The input might not have enough data points to find entities")

    static let transcriptionNoResult: PluginErrorString = (
        "Speech to text returned with no result",
        "The audio file may be corrupt or hard to understand.")

    static let requestObjectExpected: PluginErrorString = (
        "The object sent over doesn't match the request object for this type of request",
        "Make sure you are sending over the correct type for the data needed for this request.")

}
