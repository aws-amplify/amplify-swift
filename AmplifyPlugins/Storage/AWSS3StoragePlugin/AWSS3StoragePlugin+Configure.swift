//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSS3

extension AWSS3StoragePlugin {

    /// Configures AWSS3StoragePlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves the bucket, region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.decodeConfigurationError.errorDescription,
                                                       PluginErrorConstants.decodeConfigurationError.recoverySuggestion)
        }

        guard case let .object(configObject) = config else {
            throw StorageError.configuration(
                PluginErrorConstants.configurationObjectExpected.errorDescription,
                PluginErrorConstants.configurationObjectExpected.recoverySuggestion)
        }

        do {
            let authService = AWSAuthService()

            let region = try AWSS3StoragePlugin.getRegion(configObject)
            let bucket = try AWSS3StoragePlugin.getBucket(configObject)
            let defaultAccessLevel = try AWSS3StoragePlugin.getDefaultAccessLevel(configObject)

            let storageService = try AWSS3StorageService(authService: authService,
                                                         region: region,
                                                         bucket: bucket)

            configure(storageService: storageService, authService: authService, defaultAccessLevel: defaultAccessLevel)
        } catch let storageError as StorageError {
            throw storageError
        } catch {
            let amplifyError = StorageError.configuration(
                "Error configuring \(String(describing: self))",
                """
                There was an error configuring the plugin. See the underlying error for more details.
                """,
                error)
            throw amplifyError
        }
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - storageService: The S3 storage service object.
    ///   - authService: The authentication service object.
    ///   - defaultAccessLevel: The access level to be used for all API calls by default.
    ///   - queue: The queue which operations are stored and dispatched for asychronous processing.
    func configure(storageService: AWSS3StorageServiceBehaviour,
                   authService: AWSAuthServiceBehavior,
                   defaultAccessLevel: StorageAccessLevel,
                   queue: OperationQueue = OperationQueue()) {
        self.storageService = storageService
        self.authService = authService
        self.queue = queue
        self.defaultAccessLevel = defaultAccessLevel

    }

    // MARK: Private helper methods

    /// Retrieves the region from configuration, validates, and returns it.
    private static func getRegion(_ configuration: [String: JSONValue]) throws -> String {
        guard let region = configuration[PluginConstants.region] else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.missingRegion.errorDescription,
                                                       PluginErrorConstants.missingRegion.recoverySuggestion)
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.invalidRegion.errorDescription,
                                                       PluginErrorConstants.invalidRegion.recoverySuggestion)
        }

        if regionValue.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.emptyRegion.errorDescription,
                                                       PluginErrorConstants.emptyRegion.recoverySuggestion)
        }

        return regionValue
    }

    /// Retrieves the bucket from configuration, validates, and returns it.
    private static func getBucket(_ configuration: [String: JSONValue]) throws -> String {
        guard let bucket = configuration[PluginConstants.bucket] else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.missingBucket.errorDescription,
                                                       PluginErrorConstants.missingBucket.recoverySuggestion)
        }

        guard case let .string(bucketValue) = bucket else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.invalidBucket.errorDescription,
                                                       PluginErrorConstants.invalidBucket.recoverySuggestion)
        }

        if bucketValue.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.emptyBucket.errorDescription,
                                                       PluginErrorConstants.emptyBucket.recoverySuggestion)
        }

        return bucketValue
    }

    /// Checks if the access level is specified in the configurationand and retrieves it. Returns the default
    /// public access level if none is found in the configuration.
    private static func getDefaultAccessLevel(_ configuration: [String: JSONValue]) throws -> StorageAccessLevel {
        if let defaultAccessLevelConfig = configuration[PluginConstants.defaultAccessLevel] {
            guard case let .string(defaultAccessLevelString) = defaultAccessLevelConfig else {
                throw PluginError.pluginConfigurationError(
                    PluginErrorConstants.invalidDefaultAccessLevel.errorDescription,
                    PluginErrorConstants.invalidDefaultAccessLevel.recoverySuggestion)
            }

            let defaultAccessLevelOptional = StorageAccessLevel.init(rawValue: defaultAccessLevelString)
            guard let defaultAccessLevel = defaultAccessLevelOptional else {
                throw PluginError.pluginConfigurationError(
                    PluginErrorConstants.invalidDefaultAccessLevel.errorDescription,
                    PluginErrorConstants.invalidDefaultAccessLevel.recoverySuggestion)
            }

            return defaultAccessLevel
        }

        return .guest
    }
}
