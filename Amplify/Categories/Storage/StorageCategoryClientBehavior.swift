//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryClientBehavior {

    // EventHandler for GetURL
    typealias StorageGetURLEventHandler = (AsyncEvent<Void, URL, StorageError>) -> Void

    // EventHandler for GetData
    typealias StorageGetDataEventHandler = (AsyncEvent<Progress, Data, StorageError>) -> Void

    // Eventhandler for DownloadFile
    typealias StorageDownloadFileEventHandler = (AsyncEvent<Progress, Void, StorageError>) -> Void

    // EventHandlers for PutData and UploadFile
    typealias StoragePutEventHandler = (AsyncEvent<Progress, String, StorageError>) -> Void
    typealias StoragePutDataEventHandler = StoragePutEventHandler
    typealias StorageUploadFileEventHandler = StoragePutEventHandler

    // EventHandler for Remove
    typealias StorageRemoveEventHandler = (AsyncEvent<Void, String, StorageError>) -> Void

    // EventHandler for List
    typealias StorageListEventHandler = (AsyncEvent<Void, StorageListResult, StorageError>) -> Void

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

    func getURL(key: String) -> StorageGetURLOperation

    func getURL(key: String, options: StorageGetURLOptions?) -> StorageGetURLOperation

    func getURL(key: String, onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation

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

    func getData(key: String) -> StorageGetDataOperation

    func getData(key: String, options: StorageGetDataOptions?) -> StorageGetDataOperation

    func getData(key: String, onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation

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

    func downloadFile(key: String, local: URL) -> StorageDownloadFileOperation

    func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?) -> StorageDownloadFileOperation

    func downloadFile(key: String, local: URL, onEvent: StorageDownloadFileEventHandler?)
        -> StorageDownloadFileOperation

    /// Put data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func putData(key: String,
                 data: Data,
                 options: StoragePutDataOptions?,
                 onEvent: StoragePutDataEventHandler?) -> StoragePutDataOperation

    func putData(key: String, data: Data) -> StoragePutDataOperation

    func putData(key: String, data: Data, options: StoragePutDataOptions?) -> StoragePutDataOperation

    func putData(key: String, data: Data, onEvent: StoragePutDataEventHandler?) -> StoragePutDataOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOptions?,
                    onEvent: StorageUploadFileEventHandler?) -> StorageUploadFileOperation

    func uploadFile(key: String, local: URL) -> StorageUploadFileOperation

    func uploadFile(key: String, local: URL, options: StorageUploadFileOptions?) -> StorageUploadFileOperation

    func uploadFile(key: String, local: URL, onEvent: StorageUploadFileEventHandler?) -> StorageUploadFileOperation

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

    func remove(key: String) -> StorageRemoveOperation

    func remove(key: String, options: StorageRemoveOptions?) -> StorageRemoveOperation

    func remove(key: String, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation

    func list() -> StorageListOperation

    func list(options: StorageListOptions?) -> StorageListOperation

    func list(onEvent: StorageListEventHandler?) -> StorageListOperation
}
