//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import AWSPluginsCore
import Foundation

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
        let authService = AWSAuthService()
        let credentialsProvider = authService.getCredentialsProvider()

        var isDebug = false
        #if DEBUG
        isDebug = true
        log.verbose("Setting PinpointContextConfiguration.isDebug to true")
        #endif

        if configuration.region != configuration.targetingRegion {
            log.warn("Different regions between Analytics and Targeting is not supported. The Analytics region will be used.")
        }

        let sessionBackgroundTimeout: TimeInterval
        if configuration.autoSessionTrackingInterval == .max {
            sessionBackgroundTimeout = .infinity
        } else {
            sessionBackgroundTimeout = TimeInterval(configuration.autoSessionTrackingInterval)
        }
        let contextConfiguration = PinpointContextConfiguration(appId: configuration.appId,
                                                                region: configuration.region,
                                                                credentialsProvider: credentialsProvider,
                                                                isDebug: isDebug,
                                                                shouldTrackAppSessions: configuration.trackAppSessions,
                                                                sessionBackgroundTimeout: sessionBackgroundTimeout)
        let pinpoint = try PinpointContext(with: contextConfiguration)

        var autoFlushEventsTimer: DispatchSourceTimer?
        if configuration.autoFlushEventsInterval != 0 {
            let timeInterval = TimeInterval(configuration.autoFlushEventsInterval)
            autoFlushEventsTimer = RepeatingTimer.createRepeatingTimer(
                timeInterval: timeInterval,
                eventHandler: { [weak self] in
                    self?.log.debug("AutoFlushTimer triggered, flushing events")
                    self?.flushEvents()
            })
        }

        configure(pinpoint: pinpoint,
                  authService: authService,
                  autoFlushEventsTimer: autoFlushEventsTimer)
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    func configure(pinpoint: AWSPinpointBehavior,
                   authService: AWSAuthServiceBehavior,
                   autoFlushEventsTimer: DispatchSourceTimer?) {
        self.pinpoint = pinpoint
        self.authService = authService
        globalProperties = [:]
        isEnabled = true
        self.autoFlushEventsTimer = autoFlushEventsTimer
        self.autoFlushEventsTimer?.resume()
    }
}
