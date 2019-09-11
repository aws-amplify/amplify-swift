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

    /// Retrieves the preSigned URL, downloads to memory, or downloads to file of the S3 object.
    ///
    /// Stores the input in a storage request, constructs an operation to perform the work, queues it in the
    /// OperationQueue to perform the work asychronously.
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in the bucket.
    ///   - options: Additional parameters to specify API behavior.
    ///   - onEvent: The closure to receive status updates.
    /// - Returns: An operation object representing the work to be done.
    public func get(key: String,
                    options: StorageGetOption?,
                    onEvent: StorageGetEvent?) -> StorageGetOperation {

        let storageGetDestination = options?.storageGetDestination ?? .url(expires: nil)
        let request = AWSS3StorageGetRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             targetIdentityId: options?.targetIdentityId,
                                             key: key,
                                             storageGetDestination: storageGetDestination,
                                             options: options?.options)

        let getOperation = AWSS3StorageGetOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)

        queue.addOperation(getOperation)
        return getOperation
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
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .data(data: data),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             options: options?.options)

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
                    options: StoragePutOption?,
                    onEvent: StoragePutEvent?) -> StoragePutOperation {

        let request = AWSS3StoragePutRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                             key: key,
                                             uploadSource: .file(file: local),
                                             contentType: options?.contentType,
                                             metadata: options?.metadata,
                                             options: options?.options)

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
                       options: StorageRemoveOption?,
                       onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {
        let request = AWSS3StorageRemoveRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                                key: key,
                                                options: options?.options)
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
    public func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {
        let request = AWSS3StorageListRequest(accessLevel: options?.accessLevel ?? defaultAccessLevel,
                                              targetIdentityId: options?.targetIdentityId,
                                              path: options?.path,
                                              options: options?.options)
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
    public func getEscapeHatch() -> AWSS3? {
        return storageService.getEscapeHatch()
    }

    /// Private method to consolidate the call path for the Put API with the two different method signatures, uploading
    /// from data object and uploading from file.
    ///
    /// Constructs an operation to perform the work, and adds it to the OperationQueue to perform the work
    /// asychronously.
    private func put(_ request: AWSS3StoragePutRequest, onEvent: StoragePutEvent?) -> StoragePutOperation {

        let putOperation = AWSS3StoragePutOperation(request,
                                                    storageService: storageService,
                                                    authService: authService,
                                                    onEvent: onEvent)
        queue.addOperation(putOperation)

        return putOperation
    }
}
