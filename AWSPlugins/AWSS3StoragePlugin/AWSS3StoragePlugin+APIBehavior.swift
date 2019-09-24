//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import AWSMobileClient
import Amplify

extension AWSS3StoragePlugin {

    /// Retrieves the preSigned URL of the S3 object.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, queues it in the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func getURL(key: String,
                       options: StorageGetURLOptions?,
                       onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {

        let request = AWSS3StorageGetURLRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                targetIdentityId: options?.targetIdentityId,
                                                key: key,
                                                expires: options?.expires,
                                                pluginOptions: options?.pluginOptions)

        let getURLOperation = AWSS3StorageGetURLOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          onEvent: onEvent)

        queue.addOperation(getURLOperation)
        return getURLOperation
    }

    public func getURL(key: String) -> StorageGetURLOperation {
        return getURL(key: key, options: nil, onEvent: nil)
    }

    public func getURL(key: String, options: StorageGetURLOptions?) -> StorageGetURLOperation {
        return getURL(key: key, options: options, onEvent: nil)
    }

    public func getURL(key: String, onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {
        return getURL(key: key, options: nil, onEvent: onEvent)
    }

    /// Downloads to memory of the S3 object.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, queues it in the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func getData(key: String,
                        options: StorageGetDataOptions?,
                        onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {

        let request = AWSS3StorageGetDataRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                 targetIdentityId: options?.targetIdentityId,
                                                 key: key,
                                                 pluginOptions: options?.pluginOptions)

        let getDataOperation = AWSS3StorageGetDataOperation(request,
                                                            storageService: storageService,
                                                            authService: authService,
                                                            onEvent: onEvent)

        queue.addOperation(getDataOperation)
        return getDataOperation
    }

    public func getData(key: String) -> StorageGetDataOperation {
        return getData(key: key, options: nil, onEvent: nil)
    }

    public func getData(key: String, options: StorageGetDataOptions?) -> StorageGetDataOperation {
        return getData(key: key, options: options, onEvent: nil)
    }

    public func getData(key: String, onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {
        return getData(key: key, options: nil, onEvent: onEvent)
    }

    /// Downloads to file of the S3 object.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, queues it in the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - local: The local file URL to download the object to.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileOptions?,
                             onEvent: StorageDownloadFileEventHandler?) -> StorageDownloadFileOperation {

        let request = AWSS3StorageDownloadFileRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                      targetIdentityId: options?.targetIdentityId,
                                                      key: key,
                                                      local: local,
                                                      pluginOptions: options?.pluginOptions)

        let downloadFileOperation = AWSS3StorageDownloadFileOperation(request,
                                                             storageService: storageService,
                                                             authService: authService,
                                                             onEvent: onEvent)

        queue.addOperation(downloadFileOperation)
        return downloadFileOperation
    }

    public func downloadFile(key: String, local: URL) -> StorageDownloadFileOperation {
        downloadFile(key: key, local: local, options: nil, onEvent: nil)
    }

    public func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?)
        -> StorageDownloadFileOperation {
        downloadFile(key: key, local: local, options: options, onEvent: nil)
    }

    public func downloadFile(key: String, local: URL, onEvent: StorageDownloadFileEventHandler?)
        -> StorageDownloadFileOperation {
            downloadFile(key: key, local: local, options: nil, onEvent: onEvent)
    }

    /// Uploads the data object with the specified key to the S3 bucket.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, adds it to the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - data: The data object to be uploaded.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func putData(key: String,
                        data: Data,
                        options: StoragePutDataOptions?,
                        onEvent: StoragePutDataEventHandler?) -> StoragePutDataOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .data(data: data),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             pluginOptions: options?.pluginOptions)

        return put(request, onEvent: onEvent)
    }

    public func putData(key: String, data: Data) -> StoragePutDataOperation {
        return putData(key: key, data: data, options: nil, onEvent: nil)
    }

    public func putData(key: String, data: Data, options: StoragePutDataOptions?) -> StoragePutDataOperation {
        return putData(key: key, data: data, options: options, onEvent: nil)
    }

    public func putData(key: String, data: Data, onEvent: StoragePutDataEventHandler?) -> StoragePutDataOperation {
        return putData(key: key, data: data, options: nil, onEvent: onEvent)
    }

    /// Uploads the file located at the local URL with the specified key to the S3 bucket.
    ///
    /// Stores the input in a storage request, and calls the put method. Internally, it constructs the operation
    /// to perform the work, and adds it to the OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - local: The URL representing the file on the device.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileOptions?,
                           onEvent: StorageUploadFileEventHandler?) -> StorageUploadFileOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .file(file: local),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             pluginOptions: options?.pluginOptions)

        return put(request, onEvent: onEvent)
    }

    public func uploadFile(key: String, local: URL) -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: nil, onEvent: nil)
    }

    public func uploadFile(key: String, local: URL, options: StorageUploadFileOptions?) -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: options, onEvent: nil)
    }

    public func uploadFile(key: String, local: URL, onEvent: StorageUploadFileEventHandler?)
        -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: nil, onEvent: onEvent)
    }

    /// Removes the object from S3 at the specified key.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, adds it to the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func remove(key: String,
                       options: StorageRemoveOptions?,
                       onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        let request = AWSS3StorageRemoveRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                key: key,
                                                pluginOptions: options?.pluginOptions)
        let removeOperation = AWSS3StorageRemoveOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          onEvent: onEvent)
        queue.addOperation(removeOperation)

        return removeOperation
    }

    public func remove(key: String) -> StorageRemoveOperation {
        return remove(key: key, options: nil, onEvent: nil)
    }

    public func remove(key: String, options: StorageRemoveOptions?) -> StorageRemoveOperation {
        return remove(key: key, options: options, onEvent: nil)
    }

    public func remove(key: String, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        return remove(key: key, options: nil, onEvent: onEvent)
    }

    /// Lists all of the keys in the bucket, under specified access level.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, adds it to the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {
        let request = AWSS3StorageListRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                              targetIdentityId: options?.targetIdentityId,
                                              path: options?.path,
                                              pluginOptions: options?.pluginOptions)
        let listOperation = AWSS3StorageListOperation(request,
                                                      storageService: storageService,
                                                      authService: authService,
                                                      onEvent: onEvent)
        queue.addOperation(listOperation)

        return listOperation
    }

    public func list() -> StorageListOperation {
        return list(options: nil, onEvent: nil)
    }

    public func list(options: StorageListOptions?) -> StorageListOperation {
        return list(options: options, onEvent: nil)
    }

    public func list(onEvent: StorageListEventHandler?) -> StorageListOperation {
        return list(options: nil, onEvent: onEvent)
    }

    /// Retrieve the escape hatch to perform low level operations on S3
    ///
    /// - Returns: S3 client
    public func getEscapeHatch() -> AWSS3 {
        return storageService.getEscapeHatch()
    }

    /// Private method to consolidate the call path for the Put API with the two different method signatures, uploading
    /// from data object and uploading from file.
    ///
    /// Constructs an operation to perform the work, and adds it to the OperationQueue to perform the work
    /// asychronously.
    private func put(_ request: AWSS3StoragePutRequest, onEvent: StoragePutEventHandler?) -> StoragePutOperation {

        let putOperation = AWSS3StoragePutOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)
        queue.addOperation(putOperation)

        return putOperation
    }
}
