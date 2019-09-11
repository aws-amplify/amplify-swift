//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
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
    public func configure(using configuration: Any) throws {
        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError("Unexpected configuration object not castable to JSONValue",
                                                       "")
        }

        guard case let .object(configObject) = config else {
            throw PluginError.pluginConfigurationError("Did not find config object",
                                                       "")
        }

        let bucket = try AWSS3StoragePlugin.getBucket(configObject)
        let region = try AWSS3StoragePlugin.getRegionType(configObject)
        let defaultAccessLevel = try AWSS3StoragePlugin.getDefaultAccessLevel(configObject)

        let authService = AWSAuthService()
        authService.configure()

        let storageService = AWSS3StorageService()
        try storageService.configure(region: region,
                                     bucket: bucket,
                                     cognitoCredentialsProvider: authService.getCognitoCredentialsProvider(),
                                     identifier: key)

        configure(storageService: storageService, authService: authService, defaultAccessLevel: defaultAccessLevel)
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

    /// Retrieves the bucket from configuration, validates, and returns it.
    private static func getBucket(_ configuration: [String: JSONValue]) throws -> String {
        guard let bucket = configuration[PluginConstants.Bucket] else {
            throw PluginError.pluginConfigurationError("Bucket not in configuration",
                                                       "Bucket should be in the configuration")
        }

        guard case let .string(bucketValue) = bucket else {
            throw PluginError.pluginConfigurationError("Missing bucket value",
                                                       "")
        }

        if bucketValue.isEmpty {
            throw PluginError.pluginConfigurationError("Bucket is empty",
                                                       "Bucket should not be empty in the configuration")
        }

        return bucketValue
    }

    /// Retrieves the region from configuration, validates, and transforms to and returns the AWSRegionType
    private static func getRegionType(_ configuration: [String: JSONValue]) throws -> AWSRegionType {
        guard let region = configuration[PluginConstants.Region] else {
            throw PluginError.pluginConfigurationError("Region not in configuration",
                                                       "Region should be in the configuration")
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError("Missing region value",
                                                       "")
        }

        if regionValue.isEmpty {
            throw PluginError.pluginConfigurationError("Region is empty",
                                                       "")
        }

        let regionType = regionValue.aws_regionTypeValue()
        guard regionType != AWSRegionType.Unknown else {
            throw PluginError.pluginConfigurationError("Region is Unknown",
                                                       "")
        }

        return regionType
    }

    /// Checks if the access level is specified in the configurationand and retrieves it. Returns the default
    /// public access level if none is found in the configuration.
    private static func getDefaultAccessLevel(_ configuration: [String: JSONValue]) throws -> StorageAccessLevel {
        if let defaultAccessLevelConfig = configuration[PluginConstants.DefaultAccessLevel] {
            guard case let .string(defaultAccessLevelString) = defaultAccessLevelConfig else {
                throw PluginError.pluginConfigurationError("Default Access Level configured but not a string",
                                                           "")
            }

            let defaultAccessLevelOptional = StorageAccessLevel.init(rawValue: defaultAccessLevelString)
            guard let defaultAccessLevel = defaultAccessLevelOptional else {
                throw PluginError.pluginConfigurationError("Default Access Level not correct string",
                                                           "")
            }

            return defaultAccessLevel
        }

        return .public
    }
}
