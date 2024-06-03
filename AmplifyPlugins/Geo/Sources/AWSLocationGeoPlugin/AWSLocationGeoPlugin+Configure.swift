//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) import Amplify
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
import AWSLocation
import AWSClientRuntime

extension AWSLocationGeoPlugin {
    /// Configures AWSLocationPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin.
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty.
    public func configure(using configuration: Any?) throws {
        let pluginConfiguration: AWSLocationGeoPluginConfiguration
        if let configuration = configuration as? AmplifyOutputsData {
            pluginConfiguration = try AWSLocationGeoPluginConfiguration(config: configuration)
        } else if let configJSON = configuration as? JSONValue {
            pluginConfiguration = try AWSLocationGeoPluginConfiguration(config: configJSON)
        } else {
            throw GeoPluginConfigError.configurationInvalid(section: .plugin)
        }

        try configure(using: pluginConfiguration)
    }

    /// Configure AWSLocationPlugin programatically using AWSLocationPluginConfiguration
    public func configure(using configuration: AWSLocationGeoPluginConfiguration) throws {
        let authService = AWSAuthService()
        let credentialsProvider = authService.getCredentialsProvider()
        let region = configuration.regionName
        // TODO: FrameworkMetadata Replacement
        let serviceConfiguration = try LocationClient.LocationClientConfiguration(
            region: region,
            credentialsProvider: credentialsProvider
        )

        serviceConfiguration.httpClientEngine = .userAgentEngine(for: serviceConfiguration)

        let location = LocationClient(config: serviceConfiguration)
        let locationService = AWSLocationAdapter(location: location)

        configure(locationService: locationService,
                  authService: authService,
                  pluginConfig: configuration)
    }

    // MARK: - Internal

    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - locationService: The location service object.
    ///   - authService: The authentication service object.
    ///   - pluginConfig: The configuration for the plugin.
    func configure(locationService: AWSLocationBehavior,
                   authService: AWSAuthServiceBehavior,
                   pluginConfig: AWSLocationGeoPluginConfiguration) {
        self.locationService = locationService
        self.authService = authService
        self.pluginConfig = pluginConfig
    }
}
