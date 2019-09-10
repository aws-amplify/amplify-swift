//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {
    func get(key: String, options: StorageGetOption?, onEvent: StorageGetEvent?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }

    func put(key: String, data: Data, options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }

    func put(key: String, local: URL, options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }

    func remove(key: String, options: StorageRemoveOption?,
                onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {
        return MockStorageRemoveOperation(categoryType: .storage)
    }

    func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {
        return MockStorageListOperation(categoryType: .storage)
    }

    var key: String {
        return "MockStorageCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset(onComplete: @escaping (() -> Void)) {
        notify("reset")
        onComplete()
    }

    func stub() {
        notify()
    }
}

class MockSecondStorageCategoryPlugin: MockStorageCategoryPlugin {
    override var key: String {
        return "MockSecondStorageCategoryPlugin"
    }
}

final class MockStorageCategoryPluginSelector: MessageReporter, StoragePluginSelector {
    func get(key: String, options: StorageGetOption?, onEvent: StorageGetEvent?) -> StorageGetOperation {
        return MockStorageGetOperation(categoryType: .storage)
    }

    func put(key: String, data: Data, options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }

    func put(key: String, local: URL, options: StoragePutOption?,
             onEvent: StoragePutEvent?) -> StoragePutOperation {
        return MockStoragePutOperation(categoryType: .storage)
    }

    func remove(key: String, options: StorageRemoveOption?,
                onEvent: StorageRemoveEvent?) -> StorageRemoveOperation {
        return MockStorageRemoveOperation(categoryType: .storage)
    }

    func list(options: StorageListOption?, onEvent: StorageListEvent?) -> StorageListOperation {
        return MockStorageListOperation(categoryType: .storage)
    }

    var selectedPluginKey: PluginKey? = "MockStorageCategoryPlugin"

    func stub() {
        notify()
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

class MockStoragePutOperation: AmplifyOperation<Progress, StoragePutResult, StoragePutError>, StoragePutOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>,
StorageRemoveOperation {
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
