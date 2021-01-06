//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

extension StorageCategoryBehavior {

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func downloadData(
        key: String,
        options: StorageDownloadDataRequest.Options? = nil
    ) -> StorageDownloadDataOperation {
        downloadData(key: key,
                     options: options,
                     progressListener: nil,
                     resultListener: nil)
    }

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download the object to.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func downloadFile(
        key: String,
        local: URL,
        options: StorageDownloadFileRequest.Options? = nil
    ) -> StorageDownloadFileOperation {
        downloadFile(key: key,
                     local: local,
                     options: options,
                     progressListener: nil,
                     resultListener: nil)
    }

    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func getURL(
        key: String,
        options: StorageGetURLRequest.Options? = nil
    ) -> StorageGetURLOperation {
        getURL(key: key, options: nil, resultListener: nil)
    }

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func list(options: StorageListRequest.Options? = nil) -> StorageListOperation {
        list(options: options, resultListener: nil)
    }

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func remove(
        key: String,
        options: StorageRemoveRequest.Options? = nil
    ) -> StorageRemoveOperation {
        remove(key: key, options: options, resultListener: nil)
    }

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func uploadData(
        key: String,
        data: Data,
        options: StorageUploadDataRequest.Options? = nil
    ) -> StorageUploadDataOperation {
        uploadData(key: key,
                   data: data,
                   options: options,
                   progressListener: nil,
                   resultListener: nil)
    }

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related
    ///   to the execution of the work
    public func uploadFile(
        key: String,
        local: URL,
        options: StorageUploadFileRequest.Options? = nil
    ) -> StorageUploadFileOperation {
        uploadFile(key: key,
                   local: local,
                   options: options,
                   progressListener: nil,
                   resultListener: nil)
    }

}
