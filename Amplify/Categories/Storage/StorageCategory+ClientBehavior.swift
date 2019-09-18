//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
extension StorageCategory: StorageCategoryClientBehavior {
    private func plugin(from selector: StoragePluginSelector) -> StorageCategoryPlugin {
        guard let key = selector.selectedPluginKey else {
            preconditionFailure(
                """
                \(String(describing: selector)) did not set `selectedPluginKey` for the function `\(#function)`
                """)
        }
        guard let plugin = try? getPlugin(for: key) else {
            preconditionFailure(
                """
                \(String(describing: selector)) set `selectedPluginKey` to \(key) for the function `\(#function)`,
                but there is no plugin added for that key.
                """)
        }
        return plugin
    }

    public func getURL(key: String,
                       options: StorageGetURLOptions?,
                       onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.getURL(key: key, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).getURL(key: key, options: options, onEvent: onEvent)
        }
    }

    public func getData(key: String,
                        options: StorageGetDataOptions?,
                        onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.getData(key: key, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).getData(key: key, options: options, onEvent: onEvent)
        }
    }

    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileOptions?,
                             onEvent: StorageDownloadFileEventHandler?) -> StorageDownloadFileOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.downloadFile(key: key, local: local, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).downloadFile(key: key, local: local, options: options, onEvent: onEvent)
        }
    }

    public func put(key: String,
                    data: Data,
                    options: StoragePutOptions?,
                    onEvent: StoragePutEventHandler?) -> StoragePutOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.put(key: key, data: data, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).put(key: key, data: data, options: options, onEvent: onEvent)
        }
    }

    public func put(key: String,
                    local: URL,
                    options: StoragePutOptions?,
                    onEvent: StoragePutEventHandler?) -> StoragePutOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.put(key: key, local: local, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).put(key: key, local: local, options: options, onEvent: onEvent)
        }
    }

    public func remove(key: String,
                       options: StorageRemoveOptions?,
                       onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.remove(key: key, options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).remove(key: key, options: options, onEvent: onEvent)
        }
    }

    public func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {

        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.list(options: options, onEvent: onEvent)
        case .selector(let selector):
            return plugin(from: selector).list(options: options, onEvent: onEvent)
        }
    }
}
