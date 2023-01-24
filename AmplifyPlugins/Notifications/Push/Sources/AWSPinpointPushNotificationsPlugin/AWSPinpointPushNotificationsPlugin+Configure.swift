//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyUtilsNotifications
import AWSPluginsCore
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension AWSPinpointPushNotificationsPlugin {
    /// Configures AWSPinpointPushNotificationsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                PushNotificationsPluginErrorConstants.decodeConfigurationError.errorDescription,
                PushNotificationsPluginErrorConstants.decodeConfigurationError.recoverySuggestion
            )
        }

        let pluginConfiguration = try AWSPinpointPluginConfiguration(config)
        try configure(using: pluginConfiguration)
    }

    /// Configure AWSPinpointPushNotificationsPlugin programatically using AWSPinpointPushNotificationsPluginConfiguration
    private func configure(using configuration: AWSPinpointPluginConfiguration) throws {
        let pinpoint = try AWSPinpointFactory.sharedPinpoint(
            appId: configuration.appId,
            region: configuration.region
        )

        configure(pinpoint: pinpoint,
                  remoteNotificationsHelper: .default)
    }

    // MARK: Internal
    /// Internal configure method to set the properties of the plugin
    func configure(pinpoint: AWSPinpointBehavior,
                   remoteNotificationsHelper: RemoteNotificationsBehaviour) {
        self.pinpoint = pinpoint
        Task {
            do {
                let result = try await remoteNotificationsHelper.requestAuthorization(options)
                Amplify.Hub.dispatchRegisterForRemoteNotifications(result)
            } catch {
                Amplify.Hub.dispatchRegisterForRemoteNotifications(error)
            }
        }
    }
}
