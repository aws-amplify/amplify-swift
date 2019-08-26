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
    
    /// Download object to memory from storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func get(key: String, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation
    
    /// Download object to local file from storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - local: The path to a local file.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func get(key: String, local: URL, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation
    
    /// Generate a remote URL for the specified object from storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func getURL(key: String, options: StorageGetUrlOption?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation
    
    /// Upload data to storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - data: The data in memory to be uploaded
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String, data: Data, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation
    
    /// Upload local file to storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - local: The path to a local file.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func put(key: String, local: URL, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation
    
    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - remote: The location of the object in storage. Including hierarchy relative to access level and unique identifier of the object.
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String, options: StorageRemoveOption?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation
    
    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: An instance of any type to contain specific plugin option values
    ///   - onComplete: Triggered when the operation completes
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOption?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation
}
