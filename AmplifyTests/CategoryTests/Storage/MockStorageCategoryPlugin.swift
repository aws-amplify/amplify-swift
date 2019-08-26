//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {
    func get(key: String, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func get(key: String, local: URL, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func getURL(key: String, options: StorageGetUrlOption?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation {
        return MockStorageGetUrlOperation(categoryType: .storage)
    }
    
    func put(key: String, data: Data, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func put(key: String, local: URL, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func remove(key: String, options: StorageRemoveOption?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation {
        return MockStorageRemoveOperation(categoryType: .storage)
    }
    
    func list(options: StorageListOption?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation {
        return MockStorageListOperation(categoryType: .storage)
    }
    
    
    var key: String {
        return "MockStorageCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func stub() {
        notify()
    }
    
    func get(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        notify()
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func get(remote: String, local: URL, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        notify()
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func getURL(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation {
        notify()
        return MockStorageGetUrlOperation(categoryType: .storage)
    }
    
    func put(remote: String, data: Data, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        notify()
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func put(remote: String, local: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        notify()
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func remove(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation {
        notify()
        return MockStorageRemoveOperation(categoryType: .storage)
    }
    
    func list(path: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation {
        notify()
        return MockStorageListOperation(categoryType: .storage)
    }
}

class MockSecondStorageCategoryPlugin: MockStorageCategoryPlugin {
    override var key: String {
        return "MockSecondStorageCategoryPlugin"
    }
}

final class MockStorageCategoryPluginSelector: MessageReporter, StoragePluginSelector {
    func get(key: String, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func get(key: String, local: URL, options: StorageGetOption?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func getURL(key: String, options: StorageGetUrlOption?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation {
        return MockStorageGetUrlOperation(categoryType: .storage)
    }
    
    func put(key: String, data: Data, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func put(key: String, local: URL, options: StoragePutOption?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func remove(key: String, options: StorageRemoveOption?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation {
        return MockStorageRemoveOperation(categoryType: .storage)
    }
    
    func list(options: StorageListOption?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation {
        return MockStorageListOperation(categoryType: .storage)
    }
    
    var selectedPluginKey: PluginKey? = "MockStorageCategoryPlugin"

    func stub() {
        notify()
    }
    
    func get(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        notify()
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func get(remote: String, local: URL, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetResult, StorageGetError>) -> Void)?) -> StorageGetOperation {
        notify()
        return MockStorageGetOperation(categoryType: .storage)
    }
    
    func getURL(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?) -> StorageGetUrlOperation {
        notify()
        return MockStorageGetUrlOperation(categoryType: .storage)
    }
    
    func put(remote: String, data: Data, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        notify()
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func put(remote: String, local: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StoragePutResult, StoragePutError>) -> Void)?) -> StoragePutOperation {
        notify()
        return MockStoragePutOperation(categoryType: .storage)
    }
    
    func remove(remote: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?) -> StorageRemoveOperation {
        notify()
        return MockStorageRemoveOperation(categoryType: .storage)
    }
    
    func list(path: String, accessLevel: AccessLevel, options: Any?, onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?) -> StorageListOperation {
        notify()
        return MockStorageListOperation(categoryType: .storage)
    }
}

class MockStoragePluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.storage

    func makeSelector() -> PluginSelector {
        notify()
        return MockStorageCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}

class MockStorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>, StorageGetOperation {
    func pause() {
    }
    
    func resume() {
    }
}

class MockStorageGetUrlOperation: AmplifyOperation<Void, StorageGetUrlResult, StorageGetUrlError>, StorageGetUrlOperation {
}

class MockStoragePutOperation: AmplifyOperation<Progress, StoragePutResult, StoragePutError>, StoragePutOperation {
    func pause() {
    }
    
    func resume() {
    }
}

class MockStorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>, StorageRemoveOperation {
    func pause() {
    }
    
    func resume() {
    }
}

class MockStorageListOperation: AmplifyOperation<Void, StorageListResult, StorageListError>, StorageListOperation {
    func pause() {
    }
    
    func resume() {
    }
}
