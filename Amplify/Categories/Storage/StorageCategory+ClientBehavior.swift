//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
extension StorageCategory: StorageCategoryClientBehavior {
    public func getURL(key: String,
                       options: StorageGetURLOptions?,
                       onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {
        return plugin.getURL(key: key, options: options, onEvent: onEvent)
    }

    public func getData(key: String,
                        options: StorageGetDataOptions?,
                        onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {
        return plugin.getData(key: key, options: options, onEvent: onEvent)
    }

    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileOptions?,
                             onEvent: StorageDownloadFileEventHandler?) -> StorageDownloadFileOperation {
        return plugin.downloadFile(key: key, local: local, options: options, onEvent: onEvent)
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOptions?,
                    onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        return plugin.put(key: key, data: data, options: options, onEvent: onEvent)
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOptions?,
                    onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        return plugin.put(key: key, local: local, options: options, onEvent: onEvent)
    }

    public func remove(key: String,
                       options: StorageRemoveOptions?,
                       onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        return plugin.remove(key: key, options: options, onEvent: onEvent)
    }

    public func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {
        return plugin.list(options: options, onEvent: onEvent)
    }
}
