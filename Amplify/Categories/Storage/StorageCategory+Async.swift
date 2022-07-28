//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension StorageCategory {

    public func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?) async throws -> StorageGetURLOperation.Success {
        try await plugin.getURL(key: key, options: options)
    }

    public func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options?) async throws -> StorageDownloadDataOperation {
        try await plugin.downloadData(key: key, options: options)
    }

    public func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileOperation {
        try await plugin.downloadFile(key: key, local: local, options: options)
    }

    public func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?) async throws -> StorageUploadDataOperation {
        try await plugin.uploadData(key: key, data: data, options: options)
    }

    public func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?) async throws -> StorageUploadFileOperation {
        try await plugin.uploadFile(key: key, local: local, options: options)
    }

    public func remove(key: String,
                options: StorageRemoveOperation.Request.Options?) async throws -> StorageRemoveOperation.Success {
        try await plugin.remove(key: key, options: options)
    }

    public func list(options: StorageListOperation.Request.Options?) async throws -> StorageListOperation.Success {
        try await plugin.list(options: options)
    }

}
