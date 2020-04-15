//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias AuthPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AuthPluginErrorConstants {

    static let decodeConfigurationError: AuthPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: AuthPluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal")


    static let mobileClientInitializeError: AuthPluginErrorString = (
        "Unable to initialize the underlying AWSMobileClient",
        "Make sure that the necessary configuration are present in the configuration file")
}
