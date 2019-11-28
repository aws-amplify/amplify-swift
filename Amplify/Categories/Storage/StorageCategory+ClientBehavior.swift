//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension StorageCategory: StorageCategoryClientBehavior {
    public func getURL(key: String,
                       options: StorageGetURLRequest.Options? = nil,
                       listener: StorageGetURLOperation.EventListener?) -> StorageGetURLOperation {
        return plugin.getURL(key: key, options: options, listener: listener)
    }

    public func downloadData(key: String,
                             options: StorageDownloadDataRequest.Options? = nil,
                             listener: StorageDownloadDataOperation.EventListener?) -> StorageDownloadDataOperation {
        return plugin.downloadData(key: key, options: options, listener: listener)
    }

    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileRequest.Options? = nil,
                             listener: StorageDownloadFileOperation.EventListener?) -> StorageDownloadFileOperation {
        return plugin.downloadFile(key: key, local: local, options: options, listener: listener)
    }

    public func uploadData(key: String,
                           data: Data,
                           options: StorageUploadDataRequest.Options? = nil,
                           listener: StorageUploadDataOperation.EventListener?) -> StorageUploadDataOperation {
        return plugin.uploadData(key: key, data: data, options: options, listener: listener)
    }

    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileRequest.Options? = nil,
                           listener: StorageUploadFileOperation.EventListener?) -> StorageUploadFileOperation {
        return plugin.uploadFile(key: key, local: local, options: options, listener: listener)
    }

    public func remove(key: String,
                       options: StorageRemoveRequest.Options? = nil,
                       listener: StorageRemoveOperation.EventListener?) -> StorageRemoveOperation {
        return plugin.remove(key: key, options: options, listener: listener)
    }

    public func list(options: StorageListRequest.Options? = nil,
                     listener: StorageListOperation.EventListener?) -> StorageListOperation {
        return plugin.list(options: options, listener: listener)
    }
}
