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
    /// - Returns: requested Get URL
    @discardableResult
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?) async throws -> URL

    /// Retrieve the object from storage into memory.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    /// - Returns: A task that provides progress updates and the key which was used to download
    @discardableResult
    func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options?) async throws -> StorageDownloadDataTask

    /// Download to file the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - local: The local file to download destination
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A task that provides progress updates and the key which was used to download
    @discardableResult
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileTask

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A task that provides progress updates and the key which was used to upload
    @discardableResult
    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?) async throws -> StorageUploadDataTask

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A task that provides progress updates and the key which was used to upload
    @discardableResult
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?) async throws -> StorageUploadFileTask

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @discardableResult
    func remove(key: String,
                options: StorageRemoveOperation.Request.Options?) async throws -> String

    /// List the object identifiers under the hierarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - resultListener: Triggered when the list is complete
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    @discardableResult
    func list(options: StorageListOperation.Request.Options?) async throws -> StorageListResult

}
