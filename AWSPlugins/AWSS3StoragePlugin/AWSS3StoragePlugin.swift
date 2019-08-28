//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3

public class AWSS3StoragePlugin: StorageCategoryPlugin {

    public static let AWSS3StoragePluginKey = "AWSS3StoragePlugin"
    private static let AWSS3StoragePluginNotConfiguredError = """
        AWSS3StoragePlugin not configured.
        Call Amplify.configure() to configure. This could happen if Amplify.reset().
        """

    private var queue: OperationQueue = OperationQueue()

    // TODO: figure out how to
    private var storageService: AWSS3StorageServiceBehaviour!
    private var bucket: String!

    public var key: PluginKey {
        return AWSS3StoragePlugin.AWSS3StoragePluginKey
    }

    // into extensions- init, execution, ~validation
    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            guard let bucket = configuration["Bucket"] as? String else {
                throw PluginError.pluginConfigurationError("Region not in configuration",
                                                           "Region should be in the configuration")
            }
            guard let region = configuration["Region"] as? String else {
                throw PluginError.pluginConfigurationError("Region not in configuration",
                                                           "Region should be in the configuration")
            }

            // TODO: remove and replace with awsmobileclient
            guard let credentialsProvider = configuration["CredentialsProvider"] as? [String: Any] else {
                throw PluginError.pluginConfigurationError("CredentialsProvider not in configuration",
                                                           "CredentialsProvider should be in the configuration")
            }
            guard let poolId = credentialsProvider["PoolId"] as? String else {
                throw PluginError.pluginConfigurationError("PoolId not in configuration",
                                                           "PoolId should be in the configuration")
            }
            guard let credentialsProviderRegion = credentialsProvider["Region"] as? String else {
                throw PluginError.pluginConfigurationError("CredentialsProvider.Region not in configuration",
                                                           "CredentialsProvider.Region should be in the configuration")
            }

            let storageService = try AWSS3StorageService(region: region,
                                                     poolId: poolId,
                                                     credentialsProviderRegion: credentialsProviderRegion, key: key)

            self.configure(storageService: storageService, bucket: bucket)
        }
    }

    internal func configure(storageService: AWSS3StorageServiceBehaviour,
                            bucket: String,
                            queue: OperationQueue = OperationQueue()) {
        self.storageService = storageService
        self.bucket = bucket
        self.queue = queue
    }

    public func reset() {
        self.storageService = nil
        self.bucket = nil
    }

    private func throwIfNotConfigured() {
        if !(self.storageService != nil && self.bucket != nil) {
            fatalError(AWSS3StoragePlugin.AWSS3StoragePluginNotConfiguredError)
        }
        // TODO: remove self everywhere
        // TODO: weaken self
        //
    }

    public func get(key: String,
                    options: StorageGetOption?,
                    onEvent: StorageGetEvent?) -> StorageGetOperation {

        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: bucket!, key: key)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let expires = options.expires {
                _ = requestBuilder.expires(expires)
            }
            if let local = options.local {
                _ = requestBuilder.fileURL(local)
            }
        }
        let request = requestBuilder.build()
        let operation = AWSS3StorageGetOperation(request, service: storageService!, onEvent: onEvent)
        queue.addOperation(operation)

        return operation
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let requestBuilder = AWSS3StoragePutRequest.Builder(bucket: bucket, key: key)
            .data(data)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let contentType = options.contentType {
                _ = requestBuilder.contentType(contentType)
            }
        }

        let request = requestBuilder.build()

        let operation = AWSS3StoragePutOperation(request, service: storageService, onEvent: onEvent)
        queue.addOperation(operation)
        return operation
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let requestBuilder = AWSS3StoragePutRequest.Builder(bucket: bucket, key: key)
            .local(local)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let contentType = options.contentType {
                _ = requestBuilder.contentType(contentType)
            }
        }
        let request = requestBuilder.build()

        let operation = AWSS3StoragePutOperation(request, service: storageService, onEvent: onEvent)
        queue.addOperation(operation)
        return operation
    }

    public func remove(key: String,
                       options: StorageRemoveOption?,
                       onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {

        let request  = AWSS3StorageRemoveRequest.Builder(bucket: bucket, key: key).build()

        let operation = AWSS3StorageRemoveOperation(request, service: storageService, onEvent: onEvent)
        queue.addOperation(operation)
        return operation
    }

    public func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {

        let requestBuilder = AWSS3StorageListRequest.Builder(bucket: bucket)

        if let options  = options {
            if let limit = options.limit {
                _ = requestBuilder.limit(limit)
            }

            if let prefix = options.prefix {
                _ = requestBuilder.prefix(prefix)
            }
        }

        let request = requestBuilder.build()

        let operation = AWSS3StorageListOperation(request, service: storageService, onEvent: onEvent)
        queue.addOperation(operation)
        return operation
    }

    public func stub() {
    }
}
