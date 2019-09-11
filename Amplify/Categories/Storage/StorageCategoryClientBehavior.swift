//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Storage category that clients will use
public protocol StorageCategoryClientBehavior {
    typealias StorageGetEvent = (AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void
    typealias StoragePutEvent = (AsyncEvent<Progress, StoragePutResult, StoragePutError>) -> Void
    typealias StorageRemoveEvent = (AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void
    typealias StorageListEvent = (AsyncEvent<Void, StorageListResult, StorageListError>) -> Void

    /// Download object to memory from storage. Specify in the options to download to local file or retrieve remote URL
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func get(key: String,
             options: StorageGetOption?,
             onEvent: StorageGetEvent?) -> StorageGetOperation

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
             options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation

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
             options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation

    /// Delete object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage.
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func remove(key: String,
                options: StorageRemoveOption?,
                onEvent: StorageRemoveEvent?) -> StorageRemoveOperation

    /// List the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    ///   - onEvent: Triggered when event occurs
    /// - Returns: An operation object that provides notifications and actions related to the execution of the work
    func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation
}
