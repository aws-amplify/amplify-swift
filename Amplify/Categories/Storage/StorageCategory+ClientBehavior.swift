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

    public func getData(key: String,
                        options: StorageGetDataRequest.Options? = nil,
                        listener: StorageGetDataOperation.EventListener?) -> StorageGetDataOperation {
        return plugin.getData(key: key, options: options, listener: listener)
    }

    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileRequest.Options? = nil,
                             listener: StorageDownloadFileOperation.EventListener?) -> StorageDownloadFileOperation {
        return plugin.downloadFile(key: key, local: local, options: options, listener: listener)
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutRequest.Options? = nil,
                    listener: StoragePutOperation.EventListener?) -> StoragePutOperation {
        return plugin.put(key: key, data: data, options: options, listener: listener)
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutRequest.Options? = nil,
                    listener: StoragePutOperation.EventListener?) -> StoragePutOperation {
        return plugin.put(key: key, local: local, options: options, listener: listener)
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
