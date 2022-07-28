//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryBehavior {
    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - resultListener: Triggered when the operation is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?,
                resultListener: StorageGetURLOperation.ResultListener?) -> StorageGetURLOperation

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    ///   - progressListener: Triggered intermittently to represent the ongoing progress of this operation
    ///   - resultListener: Triggered when the download is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options?,
                      progressListener: ProgressListener?,
                      resultListener: StorageDownloadDataOperation.ResultListener?) -> StorageDownloadDataOperation

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download the object to.
    ///   - options: Parameters to specific plugin behavior
    ///   - progressListener: Triggered intermittently to represent the ongoing progress of this operation
    ///   - resultListener: Triggered when the download is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?,
                      progressListener: ProgressListener?,
                      resultListener: StorageDownloadFileOperation.ResultListener?) -> StorageDownloadFileOperation

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    ///   - progressListener: Triggered intermittently to represent the ongoing progress of this operation
    ///   - resultListener: Triggered when the upload is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?,
                    progressListener: ProgressListener?,
                    resultListener: StorageUploadDataOperation.ResultListener?) -> StorageUploadDataOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    ///   - progressListener: Triggered intermittently to represent the ongoing progress of this operation
    ///   - resultListener: Triggered when the upload is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?,
                    progressListener: ProgressListener?,
                    resultListener: StorageUploadFileOperation.ResultListener?) -> StorageUploadFileOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - resultListener: Triggered when the remove is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func remove(key: String,
                options: StorageRemoveOperation.Request.Options?,
                resultListener: StorageRemoveOperation.ResultListener?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - resultListener: Triggered when the list is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @available(*, deprecated, message: "Use async alternative")
    @discardableResult
    func list(options: StorageListOperation.Request.Options?,
              resultListener: StorageListOperation.ResultListener?) -> StorageListOperation

    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: The URL
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?) async throws -> StorageGetURLOperation.Success

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options?) async throws -> StorageDownloadDataOperation

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download the object to.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileOperation

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?) async throws -> StorageUploadDataOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?) async throws -> StorageUploadFileOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: Key of object which was deleted
    func remove(key: String,
                options: StorageRemoveOperation.Request.Options?) async throws -> StorageRemoveOperation.Success

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: List of keys
    func list(options: StorageListOperation.Request.Options?) async throws -> StorageListOperation.Success

}
