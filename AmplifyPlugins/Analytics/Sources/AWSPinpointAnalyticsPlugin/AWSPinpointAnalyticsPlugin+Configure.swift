//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import AWSPluginsCore
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import Network

extension AWSPinpointAnalyticsPlugin {
    /// Configures AWSPinpointAnalyticsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        let pluginConfiguration: AWSPinpointAnalyticsPluginConfiguration
        if let config = configuration as? AmplifyOutputsData {
            print(config)

            if let configuredOptions = options {
                pluginConfiguration = try AWSPinpointAnalyticsPluginConfiguration(config, options: configuredOptions)
            } else {
                let defaultOptions = AWSPinpointAnalyticsPlugin.Options.default
                options = defaultOptions
                pluginConfiguration = try AWSPinpointAnalyticsPluginConfiguration(config, options: defaultOptions)
            }
        } else if let config = configuration as? JSONValue {
            pluginConfiguration = try AWSPinpointAnalyticsPluginConfiguration(config, options)
            options = pluginConfiguration.options
        } else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.decodeConfigurationError.errorDescription,
                AnalyticsPluginErrorConstant.decodeConfigurationError.recoverySuggestion
            )
        }

        try configure(using: pluginConfiguration)
    }

    /// Configure AWSPinpointAnalyticsPlugin programatically using AWSPinpointAnalyticsPluginConfiguration
    public func configure(using configuration: AWSPinpointAnalyticsPluginConfiguration) throws {
        let pinpoint = try AWSPinpointFactory.sharedPinpoint(
            appId: configuration.appId,
            region: configuration.region
        )

        pinpoint.setAutomaticSubmitEventsInterval(configuration.options.autoFlushEventsInterval) { result in
            switch result {
            case .success(let events):
                Amplify.Hub.dispatchFlushEvents(events.asAnalyticsEventArray())
            case .failure(let error):
                Amplify.Hub.dispatchFlushEvents(AnalyticsErrorHelper.getDefaultError(error))
            }
        }

        if configuration.options.trackAppSessions {
            pinpoint.startTrackingSessions(backgroundTimeout: configuration.autoSessionTrackingInterval)
        }

        let networkMonitor = NWPathMonitor()
        networkMonitor.startMonitoring(
            using: DispatchQueue(
                label: "com.amazonaws.Amplify.AWSPinpointAnalyticsPlugin.NetworkMonitor"
            )
        )

        configure(
            pinpoint: pinpoint,
            networkMonitor: networkMonitor,
            globalProperties: [:],
            isEnabled: true
        )
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    func configure(pinpoint: AWSPinpointBehavior,
                   networkMonitor: NetworkMonitor,
                   globalProperties: AtomicDictionary<String, AnalyticsPropertyValue> = [:],
                   isEnabled: Bool = true) {
        self.pinpoint = pinpoint
        self.networkMonitor = networkMonitor
        self.globalProperties = globalProperties
        self.isEnabled = isEnabled
    }
}
