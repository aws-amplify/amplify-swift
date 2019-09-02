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

    public init() {
    }

    // into extensions- init, execution, ~validation
    public func configure(using configuration: Any) throws {
        if let configuration = configuration as? [String: Any] {
            guard let bucket = configuration["Bucket"] as? String else {
                throw PluginError.pluginConfigurationError("Bucket not in configuration",
                                                           "Bucket should be in the configuration")
            }
            guard let region = configuration["Region"] as? String else {
                throw PluginError.pluginConfigurationError("Region not in configuration",
                                                           "Region should be in the configuration")
            }

            let storageService = try AWSS3StorageService(region: region,
                                                         key: key)

            self.configure(storageService: storageService, bucket: bucket)
        }
    }

    func configure(storageService: AWSS3StorageServiceBehaviour,
                            bucket: String,
                            queue: OperationQueue = OperationQueue()) {
        self.storageService = storageService
        self.bucket = bucket
        self.queue = queue
    }

    public func reset() {
        // TODO: storageService.reset() as well.
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

        let request = requestBuilder.build()
        let getOperation = AWSS3StorageGetOperation(request, service: storageService!, onEvent: onEvent)

        if let error = request.validate() {
            return getOperation.failFast(error)
        }

        let fetchIdentityOperation = FetchIdentityOperation()

        let adapterOperation = BlockOperation {
            [unowned fetchIdentityOperation, unowned getOperation] in
            if let error = fetchIdentityOperation.storageError {
                getOperation.error = error
            } else if let identity = fetchIdentityOperation.identity {
                _ = getOperation.identity = identity as String
            }
        }

        getOperation.addDependency(adapterOperation)
        adapterOperation.addDependency(fetchIdentityOperation)
        queue.addOperations([fetchIdentityOperation, adapterOperation, getOperation], waitUntilFinished: false)

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

        let request = requestBuilder.build()
        let removeOperation = AWSS3StorageRemoveOperation(request, service: storageService, onEvent: onEvent)
        if let error = request.validate() {
            return removeOperation.failFast(error)
        }

        let fetchIdentityOperation = FetchIdentityOperation()

        let adapterOperation = BlockOperation {
            [unowned fetchIdentityOperation, unowned removeOperation] in
            if let error = fetchIdentityOperation.storageError {
                let error = StorageRemoveError.unknown(error.errorDescription, error.localizedDescription)
                removeOperation.error = error
            } else if let identity = fetchIdentityOperation.identity {
                _ = removeOperation.identity = identity as String
            }
        }

        removeOperation.addDependency(adapterOperation)
        adapterOperation.addDependency(fetchIdentityOperation)
        queue.addOperations([fetchIdentityOperation, adapterOperation, removeOperation], waitUntilFinished: false)

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
        let request = requestBuilder.build()
        let listOperation = AWSS3StorageListOperation(request, service: storageService, onEvent: onEvent)

        if let error = request.validate() {
            return listOperation.failFast(error)
        }

        let fetchIdentityOperation = FetchIdentityOperation()

        let adapterOperation = BlockOperation {
            [unowned fetchIdentityOperation, unowned listOperation] in
            if let error = fetchIdentityOperation.storageError {
                let error = StorageListError.unknown(error.errorDescription, error.localizedDescription)
                listOperation.error = error
            } else if let identity = fetchIdentityOperation.identity {
                _ = listOperation.identity = identity as String
            }
        }

        listOperation.addDependency(adapterOperation)
        adapterOperation.addDependency(fetchIdentityOperation)
        queue.addOperations([fetchIdentityOperation, adapterOperation, listOperation], waitUntilFinished: false)

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

        let request = requestBuilder.build()
        let putOperation = AWSS3StoragePutOperation(request, service: storageService, onEvent: onEvent)

        if let error = request.validate() {
            return putOperation.failFast(error)
        }

        let fetchIdentityOperation = FetchIdentityOperation()

        let adapterOperation = BlockOperation {
            [unowned fetchIdentityOperation, unowned putOperation] in
            if let error = fetchIdentityOperation.storageError {
                let error = StoragePutError.unknown(error.errorDescription, error.localizedDescription)
                putOperation.error = error
            } else if let identity = fetchIdentityOperation.identity {
                _ = putOperation.identity = identity as String
            }
        }

        putOperation.addDependency(adapterOperation)
        adapterOperation.addDependency(fetchIdentityOperation)
        queue.addOperations([fetchIdentityOperation, adapterOperation, putOperation], waitUntilFinished: false)

        return putOperation
    }
}
