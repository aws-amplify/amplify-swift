//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3
import AWSMobileClient

public class AWSS3StoragePlugin: StorageCategoryPlugin {

    private static let AWSS3StoragePluginKey = "AWSS3StoragePlugin"

    // TODO move this variable somewhere else into constant file
    private static let AWSS3StoragePluginNotConfiguredError = """
        AWSS3StoragePlugin not configured.
        Call Amplify.configure() to configure. This could happen if Amplify.reset().
        """

    private var queue: OperationQueue = OperationQueue()

    private var storageService: AWSS3StorageServiceBehaviour!
    private var bucket: String!
    private var mobileClient: AWSMobileClientBehavior!

    public var key: PluginKey {
        return AWSS3StoragePlugin.AWSS3StoragePluginKey
    }

    public init() {
    }

    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            guard let bucket = configuration["Bucket"] as? String else {
                throw PluginError.pluginConfigurationError("Bucket not in configuration",
                                                           "Bucket should be in the configuration")
            }

            if bucket.isEmpty {
                throw PluginError.pluginConfigurationError("Bucket is empty in configuration",
                                                           "Bucket should not be empty in the configuration")
            }

            guard let region = configuration["Region"] as? String else {
                throw PluginError.pluginConfigurationError("Region not in configuration",
                                                           "Region should be in the configuration")
            }

            if region.isEmpty {
                throw PluginError.pluginConfigurationError("Region should not be empty in configuration",
                                                           "Region should not be empty in the configuration")
            }

            let mobileClient = AWSMobileClientImpl(AWSMobileClient.sharedInstance())
            let storageService = try AWSS3StorageService(region: region,
                                                         mobileClient: mobileClient,
                                                         pluginKey: key)

            self.configure(storageService: storageService, bucket: bucket, mobileClient: mobileClient)
        }
    }

    func configure(storageService: AWSS3StorageServiceBehaviour,
                   bucket: String,
                   mobileClient: AWSMobileClientBehavior,
                   queue: OperationQueue = OperationQueue()) {
        self.storageService = storageService
        self.bucket = bucket
        self.mobileClient = mobileClient
        self.queue = queue
    }

    public func reset() {
        // TODO: storageService.reset() as well. need to understand how to deinit
        self.storageService = nil
        self.bucket = nil
    }

    public func get(key: String,
                    options: StorageGetOption?,
                    onEvent: StorageGetEvent?) -> StorageGetOperation {

        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: bucket!,
                                                            key: key,
                                                            accessLevel: options?.accessLevel ?? .Public)
        if let options = options {
            if let local = options.local {
                _ = requestBuilder.fileURL(local)
            }
        }

        let getOperation = AWSS3StorageGetOperation(requestBuilder.build(),
                                                    service: storageService!,
                                                    mobileClient: mobileClient!,
                                                    onEvent: onEvent)
        queue.addOperation(getOperation)
        return getOperation
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {
        return put(key: key, data: data, local: nil, options: options, onEvent: onEvent)
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {
        return put(key: key, data: nil, local: local, options: options, onEvent: onEvent)
    }

    public func remove(key: String,
                       options: StorageRemoveOption?,
                       onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {

        let requestBuilder  = AWSS3StorageRemoveRequest.Builder(bucket: bucket,
                                                                key: key,
                                                                accessLevel: options?.accessLevel ?? .Public)

        if let options = options {
            // TODO: extract extra variables
        }

        let removeOperation = AWSS3StorageRemoveOperation(requestBuilder.build(),
                                                          service: storageService,
                                                          mobileClient: mobileClient!,
                                                          onEvent: onEvent)
        queue.addOperation(removeOperation)

        return removeOperation
    }

    public func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {

        let requestBuilder = AWSS3StorageListRequest.Builder(bucket: bucket,
                                                             accessLevel: options?.accessLevel ?? .Public)

        if let options  = options {
            if let limit = options.limit {
                _ = requestBuilder.limit(limit)
            }

            if let prefix = options.prefix {
                _ = requestBuilder.prefix(prefix)
            }
        }

        let listOperation = AWSS3StorageListOperation(requestBuilder.build(),
                                                      service: storageService,
                                                      mobileClient: mobileClient!,
                                                      onEvent: onEvent)
        queue.addOperation(listOperation)

        return listOperation
    }

    public func stub() {
    }

    private func put(key: String,
                     data: Data?,
                     local: URL?,
                     options: StoragePutOption?,
                     onEvent: StoragePutEvent?) -> StoragePutOperation {

        let requestBuilder = AWSS3StoragePutRequest.Builder(bucket: bucket,
                                                            key: key,
                                                            accessLevel: options?.accessLevel ?? .Public)
        if let data = data {
            _ = requestBuilder.data(data)
        } else if let local = local {
            _ = requestBuilder.fileURL(local)
        }

        if let options = options {
            if let contentType = options.contentType {
                _ = requestBuilder.contentType(contentType)
            }
        }

        let putOperation = AWSS3StoragePutOperation(requestBuilder.build(),
                                                    service: storageService,
                                                    mobileClient: mobileClient!,
                                                    onEvent: onEvent)
        queue.addOperation(putOperation)

        return putOperation
    }

    // TODO: escape hatch implementation
//    func getS3() ->  {
//        return storageService.getS3().
//    }
}
