//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
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
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.decodeConfigurationError.errorDescription,
                AnalyticsPluginErrorConstant.decodeConfigurationError.recoverySuggestion
            )
        }

        let pluginConfiguration = try AWSPinpointAnalyticsPluginConfiguration(config)
        try configure(using: pluginConfiguration)
    }

    /// Configure AWSPinpointAnalyticsPlugin programatically using AWSPinpointAnalyticsPluginConfiguration
    public func configure(using configuration: AWSPinpointAnalyticsPluginConfiguration) throws {
        let pinpoint = try AWSPinpointFactory.sharedPinpoint(
            appId: configuration.appId,
            region: configuration.region
        )
        
        let interval = TimeInterval(configuration.autoFlushEventsInterval)
        pinpoint.setAutomaticSubmitEventsInterval(interval) { result in
            switch result {
            case .success(let events):
                Amplify.Hub.dispatchFlushEvents(events.asAnalyticsEventArray())
            case .failure(let error):
                Amplify.Hub.dispatchFlushEvents(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
        
        if configuration.trackAppSessions {
            let sessionBackgroundTimeout: TimeInterval
            if configuration.autoSessionTrackingInterval == .max {
                sessionBackgroundTimeout = .infinity
            } else {
                sessionBackgroundTimeout = TimeInterval(configuration.autoSessionTrackingInterval)
            }
            
            pinpoint.startTrackingSessions(backgroundTimeout: sessionBackgroundTimeout)
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
