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
    private var storageService: AWSS3StorageServiceBehaviour?
    private var bucket: String?

    public var key: PluginKey {
        return AWSS3StoragePlugin.AWSS3StoragePluginKey
    }

    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            guard let bucket = configuration["Bucket"] as? String else {
                throw PluginError.pluginConfigurationError(
                    "Region not in configuration", "Region should be in the configuration")
            }
            guard let region = configuration["Region"] as? String else {
                throw PluginError.pluginConfigurationError(
                    "Region not in configuration", "Region should be in the configuration")
            }
            guard let credentialsProvider = configuration["CredentialsProvider"] as? [String: Any] else {
                throw PluginError.pluginConfigurationError(
                    "CredentialsProvider not in configuration", "CredentialsProvider should be in the configuration")
            }
            guard let poolId = credentialsProvider["PoolId"] as? String else {
                throw PluginError.pluginConfigurationError(
                    "PoolId not in configuration", "PoolId should be in the configuration")
            }
            guard let credentialsProviderRegion = credentialsProvider["Region"] as? String else {
                throw PluginError.pluginConfigurationError(
                    "CredentialsProvider.Region not in configuration",
                    "CredentialsProvider.Region should be in the configuration")
            }

            let storageService = AWSS3StorageService(region: region,
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
    }

    public func get(key: String,
                    options: StorageGetOption?,
                    onComplete: StorageGetCompletionEvent?) -> StorageGetOperation {
        throwIfNotConfigured()

        let request = AWSS3StorageGetRequest.Builder(bucket: self.bucket!, key: key)
            .accessLevel(options?.accessLevel ?? .Public)
            .build()
        let operation = AWSS3StorageGetOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)

        return operation
    }

    public func get(key: String,
                    local: URL,
                    options: StorageGetOption?,
                    onComplete: StorageGetCompletionEvent?) -> StorageGetOperation {
        throwIfNotConfigured()

        let request = AWSS3StorageGetRequest.Builder(bucket: self.bucket!, key: key)
            .accessLevel(options?.accessLevel ?? .Public)
            .fileURL(local)
            .build()

        let operation = AWSS3StorageGetOperation(request, service: self.storageService!, onComplete: onComplete)

        queue.addOperation(operation)

        return operation
    }

    public func getURL(key: String,
                       options: StorageGetUrlOption?,
                       onComplete: StorageGetUrlCompletionEvent?) -> StorageGetUrlOperation {
        throwIfNotConfigured()

        let requestBuilder = AWSS3StorageGetUrlRequest.Builder(bucket: self.bucket!, key: key)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let expires = options.expires {
                _ = requestBuilder.expires(expires)
            }
        }
        let request = requestBuilder.build()
        let operation = AWSS3StorageGetUrlOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)
        return operation
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOption?,
                    onComplete: StoragePutCompletionEvent?) -> StoragePutOperation {
        throwIfNotConfigured()

        let requestBuilder = AWSS3StoragePutRequest.Builder(bucket: self.bucket!, key: key)
            .data(data)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let contentType = options.contentType {
                _ = requestBuilder.contentType(contentType)
            }
        }

        let request = requestBuilder.build()

        let operation = AWSS3StoragePutOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)
        return operation
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOption?,
                    onComplete: StoragePutCompletionEvent?) -> StoragePutOperation {
        throwIfNotConfigured()

        let requestBuilder = AWSS3StoragePutRequest.Builder(bucket: self.bucket!, key: key)
            .local(local)
            .accessLevel(options?.accessLevel ?? .Public)

        if let options = options {
            if let contentType = options.contentType {
                _ = requestBuilder.contentType(contentType)
            }
        }
        let request = requestBuilder.build()

        let operation = AWSS3StoragePutOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)
        return operation
    }

    public func remove(key: String,
                       options: StorageRemoveOption?,
                       onComplete: StorageRemoveCompletionEvent?) -> StorageRemoveOperation {
        throwIfNotConfigured()

        let request  = AWSS3StorageRemoveRequest.Builder(bucket: self.bucket!, key: key).build()

        let operation = AWSS3StorageRemoveOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)
        return operation
    }

    public func list(options: StorageListOption?, onComplete: StorageListCompletionEvent?) -> StorageListOperation {
        throwIfNotConfigured()

        let requestBuilder = AWSS3StorageListRequest.Builder(bucket: self.bucket!)

        if let options  = options {
            if let limit = options.limit {
                _ = requestBuilder.limit(limit)
            }

            if let prefix = options.prefix {
                _ = requestBuilder.prefix(prefix)
            }
        }

        let request = requestBuilder.build()

        let operation = AWSS3StorageListOperation(request, service: self.storageService!, onComplete: onComplete)
        queue.addOperation(operation)
        return operation
    }

    public func stub() {
    }
}
