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
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?,
                onEvent: StorageGetURLOperation.EventHandler?) -> StorageGetURLOperation

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getData(key: String,
                 options: StorageGetDataOperation.Request.Options?,
                 onEvent: StorageGetDataOperation.EventHandler?) -> StorageGetDataOperation

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download the object to.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?,
                      onEvent: StorageDownloadFileOperation.EventHandler?) -> StorageDownloadFileOperation

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String,
             data: Data,
             options: StoragePutOperation.Request.Options?,
             onEvent: StoragePutOperation.EventHandler?) -> StoragePutOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String,
             local: URL,
             options: StoragePutOperation.Request.Options?,
             onEvent: StoragePutOperation.EventHandler?) -> StoragePutOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String,
                options: StorageRemoveOperation.Request.Options?,
                onEvent: StorageRemoveOperation.EventHandler?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOperation.Request.Options?,
              onEvent: StorageListOperation.EventHandler?) -> StorageListOperation
}
