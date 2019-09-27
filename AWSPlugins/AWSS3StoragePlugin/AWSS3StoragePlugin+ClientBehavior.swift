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
                       options: StorageGetURLRequest.Options? = nil,
                       onEvent: StorageGetURLOperation.EventHandler? = nil) -> StorageGetURLOperation {
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        let getURLOperation = AWSS3StorageGetURLOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          onEvent: onEvent)

        queue.addOperation(getURLOperation)

        return getURLOperation
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
                        options: StorageGetDataRequest.Options? = nil,
                        onEvent: StorageGetDataOperation.EventHandler? = nil) -> StorageGetDataOperation {
        let options = options ?? StorageGetDataRequest.Options()
        let request = StorageGetDataRequest(key: key, options: options)
        let getDataOperation = AWSS3StorageGetDataOperation(request,
                                                            storageService: storageService,
                                                            authService: authService,
                                                            onEvent: onEvent)

        queue.addOperation(getDataOperation)

        return getDataOperation
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
                             options: StorageDownloadFileRequest.Options? = nil,
                             onEvent: StorageDownloadFileOperation.EventHandler? = nil)
        -> StorageDownloadFileOperation {
        let options = options ?? StorageDownloadFileRequest.Options()
        let request = StorageDownloadFileRequest(key: key, local: local, options: options)
        let downloadFileOperation = AWSS3StorageDownloadFileOperation(request,
                                                                      storageService: storageService,
                                                                      authService: authService,
                                                                      onEvent: onEvent)

        queue.addOperation(downloadFileOperation)

        return downloadFileOperation
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
    public func put(key: String,
                    data: Data,
                    options: StoragePutRequest.Options? = nil,
                    onEvent: StoragePutOperation.EventHandler? = nil) -> StoragePutOperation {
        let options = options ?? StoragePutRequest.Options()
        let request = StoragePutRequest(key: key, source: .data(data), options: options)
        return put(request, onEvent: onEvent)
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
    public func put(key: String,
                    local: URL,
                    options: StoragePutRequest.Options? = nil,
                    onEvent: StoragePutOperation.EventHandler? = nil) -> StoragePutOperation {
        let options = options ?? StoragePutRequest.Options()
        let request = StoragePutRequest(key: key, source: .local(local), options: options)
        return put(request, onEvent: onEvent)
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
                       options: StorageRemoveRequest.Options? = nil,
                       onEvent: StorageRemoveOperation.EventHandler? = nil) -> StorageRemoveOperation {
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        let removeOperation = AWSS3StorageRemoveOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          onEvent: onEvent)

        queue.addOperation(removeOperation)

        return removeOperation
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
    public func list(options: StorageListRequest.Options? = nil,
                     onEvent: StorageListOperation.EventHandler? = nil) -> StorageListOperation {
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        let listOperation = AWSS3StorageListOperation(request,
                                                      storageService: storageService,
                                                      authService: authService,
                                                      onEvent: onEvent)

        queue.addOperation(listOperation)

        return listOperation
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
    private func put(_ request: StoragePutRequest,
                     onEvent: StoragePutOperation.EventHandler? = nil) -> StoragePutOperation {

        let putOperation = AWSS3StoragePutOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)

        queue.addOperation(putOperation)

        return putOperation
    }
}
