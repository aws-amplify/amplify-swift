//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import AWSClientRuntime
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

public struct AWSPinpointPushNotificationsPluginConfiguration {
    // TODO: Validate this value with CLI
    static let pinpointConfigKey = "pinpoint"

    let appId: String
    let region: String

    private static let logger = Amplify.Logging.logger(forCategory: String(describing: Self.self))

    init(_ configuration: JSONValue) throws {
        guard case let .object(configObject) = configuration else {
            throw PluginError.pluginConfigurationError(
                PushNotificationsPluginErrorConstants.configurationObjectExpected.errorDescription,
                PushNotificationsPluginErrorConstants.configurationObjectExpected.recoverySuggestion
            )
        }

        guard let pinpointConfig = configObject[Self.pinpointConfigKey] else {
            throw PluginError.pluginConfigurationError(
                PushNotificationsPluginErrorConstants.missingPinpointPushNotificationsConfiguration.errorDescription,
                PushNotificationsPluginErrorConstants.missingPinpointPushNotificationsConfiguration.recoverySuggestion
            )
        }

        let pluginConfiguration = try AWSPinpointPluginConfiguration(pinpointConfig)

        self.init(appId: pluginConfiguration.appId,
                  region: pluginConfiguration.region)
    }

    init(appId: String,
         region: String) {
        self.appId = appId
        self.region = region
    }
}
