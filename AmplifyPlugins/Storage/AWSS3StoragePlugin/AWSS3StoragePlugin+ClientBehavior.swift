//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import Amplify
import AWSPluginsCore

extension AWSS3StoragePlugin {

    /// Retrieves the preSigned URL of the S3 object.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, queues it in the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func getURL(key: String,
                       options: StorageGetURLRequest.Options? = nil,
                       listener: StorageGetURLOperation.EventListener? = nil) -> StorageGetURLOperation {
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        let getURLOperation = AWSS3StorageGetURLOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          listener: listener)

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
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func downloadData(key: String,
                             options: StorageDownloadDataRequest.Options? = nil,
                             listener: StorageDownloadDataOperation.EventListener? = nil) -> StorageDownloadDataOperation {
        let options = options ?? StorageDownloadDataRequest.Options()
        let request = StorageDownloadDataRequest(key: key, options: options)
        let downloadDataOperation = AWSS3StorageDownloadDataOperation(request,
                                                            storageService: storageService,
                                                            authService: authService,
                                                            listener: listener)

        queue.addOperation(downloadDataOperation)

        return downloadDataOperation
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
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileRequest.Options? = nil,
                             listener: StorageDownloadFileOperation.EventListener? = nil)
        -> StorageDownloadFileOperation {
        let options = options ?? StorageDownloadFileRequest.Options()
        let request = StorageDownloadFileRequest(key: key, local: local, options: options)
        let downloadFileOperation = AWSS3StorageDownloadFileOperation(request,
                                                                      storageService: storageService,
                                                                      authService: authService,
                                                                      listener: listener)

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
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func uploadData(key: String,
                           data: Data,
                           options: StorageUploadDataRequest.Options? = nil,
                           listener: StorageUploadDataOperation.EventListener? = nil) -> StorageUploadDataOperation {
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)

        let uploadDataOperation = AWSS3StorageUploadDataOperation(request,
                                                            storageService: storageService,
                                                            authService: authService,
                                                            listener: listener)

        queue.addOperation(uploadDataOperation)

        return uploadDataOperation
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
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileRequest.Options? = nil,
                           listener: StorageUploadFileOperation.EventListener? = nil) -> StorageUploadFileOperation {
        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)

        let uploadFileOperation = AWSS3StorageUploadFileOperation(request,
                                                                  storageService: storageService,
                                                                  authService: authService,
                                                                  listener: listener)

        queue.addOperation(uploadFileOperation)

        return uploadFileOperation
    }

    /// Removes the object from S3 at the specified key.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, adds it to the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func remove(key: String,
                       options: StorageRemoveRequest.Options? = nil,
                       listener: StorageRemoveOperation.EventListener? = nil) -> StorageRemoveOperation {
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        let removeOperation = AWSS3StorageRemoveOperation(request,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          listener: listener)

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
    ///   - listener: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func list(options: StorageListRequest.Options? = nil,
                     listener: StorageListOperation.EventListener? = nil) -> StorageListOperation {
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        let listOperation = AWSS3StorageListOperation(request,
                                                      storageService: storageService,
                                                      authService: authService,
                                                      listener: listener)

        queue.addOperation(listOperation)

        return listOperation
    }

    /// Retrieve the escape hatch to perform low level operations on S3.
    ///
    /// - Returns: S3 client
    public func getEscapeHatch() -> AWSS3 {
        return storageService.getEscapeHatch()
    }
}
