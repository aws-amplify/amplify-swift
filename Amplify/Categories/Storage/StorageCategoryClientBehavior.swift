//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryClientBehavior {
    typealias StorageGetURLEventHandler = (AsyncEvent<Void, URL, StorageGetURLError>) -> Void
    typealias StorageGetDataEventHandler = (AsyncEvent<Progress, Data, StorageGetDataError>) -> Void
    typealias StorageDownloadFileEventHandler = (AsyncEvent<Progress, Void, StorageDownloadFileError>) -> Void
    typealias StoragePutEventHandler = (AsyncEvent<Progress, String, StoragePutError>) -> Void
    typealias StorageRemoveEventHandler = (AsyncEvent<Void, String, StorageRemoveError>) -> Void
    typealias StorageListEventHandler = (AsyncEvent<Void, StorageListResult, StorageListError>) -> Void

    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getURL(key: String,
                options: StorageGetURLOptions?,
                onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getData(key: String,
                 options: StorageGetDataOptions?,
                 onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation

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
                      options: StorageDownloadFileOptions?,
                      onEvent: StorageDownloadFileEventHandler?) -> StorageDownloadFileOperation

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
             options: StoragePutOptions?,
             onEvent: StoragePutEventHandler?) -> StoragePutOperation

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
             options: StoragePutOptions?,
             onEvent: StoragePutEventHandler?) -> StoragePutOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String,
                options: StorageRemoveOptions?,
                onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation
}
