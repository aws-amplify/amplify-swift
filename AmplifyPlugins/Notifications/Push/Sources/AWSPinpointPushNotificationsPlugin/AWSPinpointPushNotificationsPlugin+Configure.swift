//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
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
        let pluginConfiguration: AWSPinpointPluginConfiguration
        if let config = configuration as? AmplifyOutputsData {
            guard let notifications = config.notifications else {
                throw PluginError.pluginConfigurationError(
                    PushNotificationsPluginErrorConstants.missinAmplifyOutputsPinpointNotificationsConfiguration.errorDescription,
                    PushNotificationsPluginErrorConstants.missinAmplifyOutputsPinpointNotificationsConfiguration.errorDescription
                )
            }

            pluginConfiguration = AWSPinpointPluginConfiguration(
                appId: notifications.amazonPinpointAppId,
                region: notifications.awsRegion)
        } else if let config = configuration as? JSONValue {
            pluginConfiguration = try AWSPinpointPluginConfiguration(config)
        } else {
            throw PluginError.pluginConfigurationError(
                PushNotificationsPluginErrorConstants.decodeConfigurationError.errorDescription,
                PushNotificationsPluginErrorConstants.decodeConfigurationError.recoverySuggestion
            )
        }

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

    private func requestNotificationsPermissions(using helper: RemoteNotificationsBehaviour) async {
        guard !options.isEmpty else {
            return
        }

        do {
            let result = try await helper.requestAuthorization(options)
            Amplify.Hub.dispatchRequestNotificationsPermissions(result)
        } catch {
            Amplify.Hub.dispatchRequestNotificationsPermissions(error)
        }
    }

    // MARK: Internal
    /// Internal configure method to set the properties of the plugin
    func configure(pinpoint: AWSPinpointBehavior,
                   remoteNotificationsHelper: RemoteNotificationsBehaviour) {
        self.pinpoint = pinpoint
        Task {
            await remoteNotificationsHelper.registerForRemoteNotifications()
            await requestNotificationsPermissions(using: remoteNotificationsHelper)
        }
    }
}
