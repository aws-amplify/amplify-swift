//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryClientBehavior {
    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?,
                listener: StorageGetURLOperation.EventListener?) -> StorageGetURLOperation

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options?,
                      listener: StorageDownloadDataOperation.EventListener?) -> StorageDownloadDataOperation

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download the object to.
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?,
                      listener: StorageDownloadFileOperation.EventListener?) -> StorageDownloadFileOperation

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?,
                    listener: StorageUploadDataOperation.EventListener?) -> StorageUploadDataOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?,
                    listener: StorageUploadFileOperation.EventListener?) -> StorageUploadFileOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String,
                options: StorageRemoveOperation.Request.Options?,
                listener: StorageRemoveOperation.EventListener?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - listener: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOperation.Request.Options?,
              listener: StorageListOperation.EventListener?) -> StorageListOperation
}
