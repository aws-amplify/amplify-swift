//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryClientBehavior {
    func stub()

    typealias StorageGetCompletionEvent = (CompletionEvent<StorageGetResult, StorageGetError>) -> Void
    typealias StorageGetUrlCompletionEvent = (CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void
    typealias StoragePutCompletionEvent = (CompletionEvent<StoragePutResult, StoragePutError>) -> Void
    typealias StorageRemoveCompletionEvent = (CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void
    typealias StorageListCompletionEvent = (CompletionEvent<StorageListResult, StorageListError>) -> Void

    /// Download object to memory from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func get(key: String,
             options: StorageGetOption?,
             onComplete: StorageGetCompletionEvent?) -> StorageGetOperation

    /// Download object to local file from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func get(key: String,
             local: URL,
             options: StorageGetOption?,
             onComplete: StorageGetCompletionEvent?) -> StorageGetOperation

    /// Generate a remote URL for the specified object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getURL(key: String,
                options: StorageGetUrlOption?,
                onComplete: StorageGetUrlCompletionEvent?) -> StorageGetUrlOperation

    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - data: The data in memory to be uploaded
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String,
             data: Data,
             options: StoragePutOption?,
             onComplete: StoragePutCompletionEvent?) -> StoragePutOperation

    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - local: The path to a local file.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String,
             local: URL,
             options: StoragePutOption?,
             onComplete: StoragePutCompletionEvent?) -> StoragePutOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String,
                options: StorageRemoveOption?,
                onComplete: StorageRemoveCompletionEvent?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOption?, onComplete: StorageListCompletionEvent?) -> StorageListOperation
}
