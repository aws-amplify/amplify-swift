//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import AWSPluginsCore
import Amplify
import Combine
import Foundation

/// CloudWatchLoggingPlugin attempts to extract the proper CloudWatch
/// values from the application's Amplify configuration in order to
/// upload to a given log group. If no such configuration exists, this plugin
/// delegates all calls to the default Console logger implementation.
///
/// - Tag: CloudWatchLoggingPlugin
public class AWSCloudWatchLoggingPlugin: LoggingCategoryPlugin {    
    /// An instance of the authentication service.
    var loggingClient: AWSCloudWatchLoggingCategoryClient!
    
    private var loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration?
    private var remoteLoggingConstraintsProvider: RemoteLoggingConstraintsProvider?
    
    public var key: PluginKey {
        return PluginConstants.awsCloudWatchLoggingPluginKey
    }
    
    public var `default`: Logger {
        loggingClient.default
    }
    
    public init(
        loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration? = nil,
        remoteLoggingConstraintsProvider: RemoteLoggingConstraintsProvider? = nil
    ) {
        self.loggingPluginConfiguration = loggingPluginConfiguration
        self.remoteLoggingConstraintsProvider = remoteLoggingConstraintsProvider
        if let configuration = self.loggingPluginConfiguration {
            let authService = AWSAuthService()
            self.loggingClient = AWSCloudWatchLoggingCategoryClient(
                enable: configuration.enable,
                credentialsProvider: authService.getCredentialsProvider(),
                authentication: Amplify.Auth,
                loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: configuration),
                logGroupName: configuration.logGroupName,
                region: configuration.region,
                localStoreMaxSizeInMB: configuration.localStoreMaxSizeInMB,
                flushIntervalInSeconds: configuration.flushIntervalInSeconds
            )
            if let remoteConfig = configuration.defaultRemoteConfiguration, self.remoteLoggingConstraintsProvider == nil {
                self.remoteLoggingConstraintsProvider = DefaultRemoteLoggingConstraintsProvider(
                    endpoint: remoteConfig.endpoint,
                    region: configuration.region,
                    refreshIntervalInSeconds: remoteConfig.refreshIntervalInSeconds)
            }
        }
    }

    public func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        return loggingClient.logger(forCategory: category, logLevel: logLevel)
    }

    public func logger(forCategory category: String) -> Logger {
        return loggingClient.logger(forCategory: category)
    }
    
    public func logger(forNamespace namespace: String) -> Logger {
        return loggingClient.logger(forCategory: namespace)
    }
    
    public func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        return loggingClient.logger(forCategory: category, forNamespace: namespace)
    }
    
    /// enable plugin
    public func enable() {
        loggingClient.enable()
    }
    
    /// disable plugin
    public func disable() {
        loggingClient.disable()
    }
    
    /// send logs on-demand to AWS CloudWatch
    public func flushLogs() async throws {
        try await loggingClient.flushLogs()
    }
    
    /// Retrieve the escape hatch to perform low level operations on AWSCloudWatch
    ///
    /// - Returns: AWS CloudWatch Client
    public func getEscapeHatch() -> CloudWatchLogsClientProtocol {
        return loggingClient.getInternalClient()
    }
    
    /// Resets the state of the plugin.
    ///
    /// Calls the reset methods on the storage service and authentication service to clean up resources. Setting the
    /// storage service, authentication service, and queue to nil to allow deallocation.
    public func reset() async {
        await loggingClient.reset()
    }
    
    /// Configures AWSS3StoragePlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves the bucket, region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        if self.loggingPluginConfiguration == nil, let configuration = try? AWSCloudWatchLoggingPluginConfiguration(bundle: Bundle.main) {
            self.loggingPluginConfiguration = configuration
            let authService = AWSAuthService()
            
            if let remoteConfig = configuration.defaultRemoteConfiguration, self.remoteLoggingConstraintsProvider == nil {
                self.remoteLoggingConstraintsProvider = DefaultRemoteLoggingConstraintsProvider(
                    endpoint: remoteConfig.endpoint,
                    region: configuration.region,
                    refreshIntervalInSeconds: remoteConfig.refreshIntervalInSeconds)
            }
            
            self.loggingClient = AWSCloudWatchLoggingCategoryClient(
                enable: configuration.enable,
                credentialsProvider: authService.getCredentialsProvider(),
                authentication: Amplify.Auth,
                loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: configuration),
                logGroupName: configuration.logGroupName,
                region: configuration.region,
                localStoreMaxSizeInMB: configuration.localStoreMaxSizeInMB,
                flushIntervalInSeconds: configuration.flushIntervalInSeconds
            )
        }
        
        if self.loggingPluginConfiguration == nil {
            throw LoggingError.configuration(
                """
                Missing configuration for AWSCloudWatchLoggingPlugin
                """,
                """
                Expected to find the file, `amplifyconfiguration_logging.json` in the app bundle, but
                it was not present. Either add amplifyconfiguration_logging.json to your app's "Copy Bundle Resources" build phase or provide the plugin
                configuration when constructing the AWSCloudWatchLoggingPlugin.
                """
            )
        }
        
        if self.remoteLoggingConstraintsProvider == nil {
            let localStore: LoggingConstraintsLocalStore = UserDefaults.standard
            localStore.reset()
        }
        
        DispatchQueue.main.async {
            self.loggingClient.takeUserIdentifierFromCurrentUser()
        }
    }
}

extension AWSCloudWatchLoggingPlugin: AmplifyVersionable { }
