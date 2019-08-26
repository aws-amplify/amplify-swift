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

    public func get(key: String, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.get(key: key, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).get(key: key, options: options, onComplete: onComplete)
        }
    }
    
    public func get(key: String, local: URL, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.get(key: key, local: local, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).get(key: key, local: local, options: options, onComplete: onComplete)
        }
    }
    
    public func getURL(key: String, options: StorageGetUrlOption?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.getURL(key: key, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).getURL(key: key, options: options, onComplete: onComplete)
        }
    }
    
    public func put(key: String, data: Data, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.put(key: key, data: data, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).put(key: key, data: data, options: options, onComplete: onComplete)
        }
    }
    
    public func put(key: String, local: URL, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.put(key: key, local: local, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).put(key: key, local: local, options: options, onComplete: onComplete)
        }
    }
    
    public func remove(key: String, options: StorageRemoveOption?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.remove(key: key, options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).remove(key: key, options: options, onComplete: onComplete)
        }
    }
    
    public func list(options: StorageListOption?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.list(options: options, onComplete: onComplete)
        case .selector(let selector):
            return plugin(from: selector).list(options: options, onComplete: onComplete)
        }
    }
    
    public func stub() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.stub()
        case .selector(let selector):
            plugin(from: selector).stub()
        }
    }
}
