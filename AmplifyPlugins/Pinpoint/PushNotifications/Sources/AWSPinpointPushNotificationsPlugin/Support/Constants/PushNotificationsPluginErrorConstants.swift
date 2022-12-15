//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias PushNotificationsPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct PushNotificationsPluginErrorConstants {
    static let decodeConfigurationError: PushNotificationsPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue"
    )

    static let configurationObjectExpected: PushNotificationsPluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal with keys"
    )

    static let missingPinpointPushNotificationsConfiguration: PushNotificationsPluginErrorString = (
        "Plugin is missing `PinpointPushNotifications` section.",
        "Add the `PinpointPushNotifications` section to the plugin."
    )
}
