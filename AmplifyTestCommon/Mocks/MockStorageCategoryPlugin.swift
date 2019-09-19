//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {

    func getURL(key: String, options: StorageGetURLOptions?, onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {
        notify("getURL")
        return MockStorageGetURLOperation(categoryType: .storage)
    }

    func getData(key: String, options: StorageGetDataOptions?, onEvent: StorageGetDataEventHandler?)
        -> StorageGetDataOperation {
        notify("getData")
        return MockStorageGetDataOperation(categoryType: .storage)
    }

    func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?, onEvent: StorageDownloadFileEventHandler?)
        -> StorageDownloadFileOperation {
        notify("downloadFile")
        return MockStorageDownloadFileOperation(categoryType: .storage)
    }

    func put(key: String, data: Data, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("put")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func put(key: String, local: URL, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("putFile")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func remove(key: String, options: StorageRemoveOptions?, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        notify("remove")
        return MockStorageRemoveOperation(categoryType: .storage)
    }

    func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {
        notify("list")
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
}

class MockSecondStorageCategoryPlugin: MockStorageCategoryPlugin {
    override var key: String {
        return "MockSecondStorageCategoryPlugin"
    }
}

final class MockStorageCategoryPluginSelector: MessageReporter, StoragePluginSelector {

    func getURL(key: String, options: StorageGetURLOptions?, onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {
        notify("getURL")
        return MockStorageGetURLOperation(categoryType: .storage)
    }

    func getData(key: String, options: StorageGetDataOptions?, onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {
        notify("getData")
        return MockStorageGetDataOperation(categoryType: .storage)
    }

    func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?, onEvent: StorageDownloadFileEventHandler?)
        -> StorageDownloadFileOperation {
        notify("downloadFile")
        return MockStorageDownloadFileOperation(categoryType: .storage)
    }

    func put(key: String, data: Data, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("put")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func put(key: String, local: URL, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("put")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func remove(key: String, options: StorageRemoveOptions?, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        notify("remove")
        return MockStorageRemoveOperation(categoryType: .storage)
    }

    func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {
        notify("list")
        return MockStorageListOperation(categoryType: .storage)
    }

    var selectedPluginKey: PluginKey? = "MockStorageCategoryPlugin"
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

class MockStorageGetURLOperation: AmplifyOperation<Void, URL, StorageError>,
    StorageGetURLOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStorageGetDataOperation: AmplifyOperation<Progress, Data, StorageError>,
    StorageGetDataOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStorageDownloadFileOperation: AmplifyOperation<Progress, Void, StorageError>,
    StorageDownloadFileOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStoragePutOperation: AmplifyOperation<Progress, String, StorageError>, StoragePutOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStorageRemoveOperation: AmplifyOperation<Void, String, StorageError>,
StorageRemoveOperation {
    func pause() {
    }

    func resume() {
    }
}

class MockStorageListOperation: AmplifyOperation<Void, StorageListResult, StorageError>, StorageListOperation {
    func pause() {
    }

    func resume() {
    }
}
