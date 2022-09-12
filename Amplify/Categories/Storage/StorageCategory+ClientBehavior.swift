//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension StorageCategory: StorageCategoryBehavior {

    public var activeTransfers: AmplifyAsyncSequence<StorageActiveTransfer> {
        get async throws {
            try await plugin.activeTransfers
        }
    }

    @discardableResult
    public func getURL(key: String,
                       options: StorageGetURLOperation.Request.Options? = nil) async throws -> URL {
        try await plugin.getURL(key: key, options: options)
    }

    @discardableResult
    public func downloadData(key: String,
                             options: StorageDownloadDataOperation.Request.Options? = nil) async throws -> StorageDownloadDataTask {
        try await plugin.downloadData(key: key, options: options)
    }

    @discardableResult
    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileTask {
        try await plugin.downloadFile(key: key, local: local, options: options)
    }

    @discardableResult
    public func uploadData(key: String,
                           data: Data,
                           options: StorageUploadDataOperation.Request.Options? = nil) async throws -> StorageUploadDataTask {
        try await plugin.uploadData(key: key, data: data, options: options)
    }

    @discardableResult
    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileOperation.Request.Options? = nil) async throws -> StorageUploadFileTask {
        try await plugin.uploadFile(key: key, local: local, options: options)
    }

    @discardableResult
    public func remove(key: String,
                       options: StorageRemoveRequest.Options? = nil) async throws -> String {
        try await plugin.remove(key: key, options: options)
    }

    @discardableResult
    public func list(options: StorageListOperation.Request.Options? = nil) async throws -> StorageListResult {
        try await plugin.list(options: options)
    }

    public func handleBackgroundEvents(identifier: String) async -> Bool {
        await plugin.handleBackgroundEvents(identifier: identifier)
    }

}
