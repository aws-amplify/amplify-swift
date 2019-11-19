//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

}
