//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension StorageCategory: StorageCategoryBehavior {
    @discardableResult
    public func getURL(key: String,
                       options: StorageGetURLRequest.Options? = nil,
                       resultListener: StorageGetURLOperation.ResultListener?) -> StorageGetURLOperation {
        return plugin.getURL(key: key, options: options, resultListener: resultListener)
    }

    @discardableResult
    public func downloadData(key: String,
                             options: StorageDownloadDataRequest.Options? = nil,
                             progressListener: ProgressListener? = nil,
                             resultListener: StorageDownloadDataOperation.ResultListener?
    ) -> StorageDownloadDataOperation {
        return plugin.downloadData(key: key,
                                   options: options,
                                   progressListener: progressListener,
                                   resultListener: resultListener)
    }

    @discardableResult
    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileRequest.Options? = nil,
                             progressListener: ProgressListener? = nil,
                             resultListener: StorageDownloadFileOperation.ResultListener?
    ) -> StorageDownloadFileOperation {
        return plugin.downloadFile(key: key,
                                   local: local,
                                   options: options,
                                   progressListener: progressListener,
                                   resultListener: resultListener)
    }

    @discardableResult
    public func uploadData(key: String,
                           data: Data,
                           options: StorageUploadDataRequest.Options? = nil,
                           progressListener: ProgressListener? = nil,
                           resultListener: StorageUploadDataOperation.ResultListener?
    ) -> StorageUploadDataOperation {
        return plugin.uploadData(key: key,
                                 data: data,
                                 options: options,
                                 progressListener: progressListener,
                                 resultListener: resultListener)
    }

    @discardableResult
    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileRequest.Options? = nil,
                           progressListener: ProgressListener? = nil,
                           resultListener: StorageUploadFileOperation.ResultListener?
    ) -> StorageUploadFileOperation {
        return plugin.uploadFile(key: key,
                                 local: local,
                                 options: options,
                                 progressListener: progressListener,
                                 resultListener: resultListener)
    }

    @discardableResult
    public func remove(key: String,
                       options: StorageRemoveRequest.Options? = nil,
                       resultListener: StorageRemoveOperation.ResultListener?) -> StorageRemoveOperation {
        return plugin.remove(key: key, options: options, resultListener: resultListener)
    }

    @discardableResult
    public func list(options: StorageListRequest.Options? = nil,
                     resultListener: StorageListOperation.ResultListener?) -> StorageListOperation {
        return plugin.list(options: options, resultListener: resultListener)
    }

    // MARK: - Async API -

    @discardableResult
    public func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?) async throws -> URL {
        try await plugin.getURL(key: key, options: options)
    }

    @discardableResult
    public func remove(key: String,
                       options: StorageRemoveRequest.Options? = nil) async throws -> String {
        try await plugin.remove(key: key, options: options)
    }

    @discardableResult
    public func list(options: StorageListOperation.Request.Options?) async throws -> StorageListResult {
        try await plugin.list(options: options)
    }
}
