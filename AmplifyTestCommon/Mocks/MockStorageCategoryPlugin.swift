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

    func getURL(key: String) -> StorageGetURLOperation {
        return getURL(key: key, options: nil, onEvent: nil)
    }

    func getURL(key: String, options: StorageGetURLOptions?) -> StorageGetURLOperation {
        return getURL(key: key, options: options, onEvent: nil)
    }

    func getURL(key: String, onEvent: StorageGetURLEventHandler?) -> StorageGetURLOperation {
        return getURL(key: key, options: nil, onEvent: onEvent)
    }

    func getData(key: String, options: StorageGetDataOptions?, onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {
        notify("getData")
        return MockStorageGetDataOperation(categoryType: .storage)
    }

    func getData(key: String) -> StorageGetDataOperation {
        return getData(key: key, options: nil, onEvent: nil)
    }

    func getData(key: String, options: StorageGetDataOptions?) -> StorageGetDataOperation {
        return getData(key: key, options: options, onEvent: nil)
    }

    func getData(key: String, onEvent: StorageGetDataEventHandler?) -> StorageGetDataOperation {
        return getData(key: key, options: nil, onEvent: onEvent)
    }

    func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?, onEvent: StorageDownloadFileEventHandler?)
        -> StorageDownloadFileOperation {
        notify("downloadFile")
        return MockStorageDownloadFileOperation(categoryType: .storage)
    }

    func downloadFile(key: String, local: URL) -> StorageDownloadFileOperation {
        downloadFile(key: key, local: local, options: nil, onEvent: nil)
    }

    func downloadFile(key: String, local: URL, options: StorageDownloadFileOptions?) -> StorageDownloadFileOperation {
        downloadFile(key: key, local: local, options: options, onEvent: nil)
    }

    func downloadFile(key: String, local: URL, onEvent: StorageDownloadFileEventHandler?) -> StorageDownloadFileOperation {
        downloadFile(key: key, local: local, options: nil, onEvent: onEvent)
    }

    func putData(key: String, data: Data, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("putData")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func putData(key: String, data: Data) -> StoragePutDataOperation {
        putData(key: key, data: data, options: nil, onEvent: nil)
    }

    func putData(key: String, data: Data, options: StoragePutDataOptions?) -> StoragePutDataOperation {
        putData(key: key, data: data, options: options, onEvent: nil)
    }

    func putData(key: String, data: Data, onEvent: StoragePutDataEventHandler?) -> StoragePutDataOperation {
        putData(key: key, data: data, options: nil, onEvent: onEvent)
    }

    func uploadFile(key: String, local: URL, options: StoragePutOptions?, onEvent: StoragePutEventHandler?) -> StoragePutOperation {
        notify("uploadFile")
        return MockStoragePutOperation(categoryType: .storage)
    }

    func uploadFile(key: String, local: URL) -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: nil, onEvent: nil)
    }

    func uploadFile(key: String, local: URL, options: StorageUploadFileOptions?) -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: options, onEvent: nil)
    }

    func uploadFile(key: String, local: URL, onEvent: StorageUploadFileEventHandler?) -> StorageUploadFileOperation {
        return uploadFile(key: key, local: local, options: nil, onEvent: onEvent)
    }

    func remove(key: String, options: StorageRemoveOptions?, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        notify("remove")
        return MockStorageRemoveOperation(categoryType: .storage)
    }

    func remove(key: String) -> StorageRemoveOperation {
        remove(key: key, options: nil, onEvent: nil)
    }

    func remove(key: String, options: StorageRemoveOptions?) -> StorageRemoveOperation {
        remove(key: key, options: options, onEvent: nil)
    }

    func remove(key: String, onEvent: StorageRemoveEventHandler?) -> StorageRemoveOperation {
        remove(key: key, options: nil, onEvent: onEvent)
    }

    func list(options: StorageListOptions?, onEvent: StorageListEventHandler?) -> StorageListOperation {
        notify("list")
        return MockStorageListOperation(categoryType: .storage)
    }

    func list() -> StorageListOperation {
        return list(options: nil, onEvent: nil)
    }

    func list(options: StorageListOptions?) -> StorageListOperation {
        return list(options: options, onEvent: nil)
    }

    func list(onEvent: StorageListEventHandler?) -> StorageListOperation {
        return list(options: nil, onEvent: onEvent)
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

class MockStorageGetURLOperation: AmplifyOperation<Void, URL, StorageError>,
    StorageGetURLOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageGetDataOperation: AmplifyOperation<Progress, Data, StorageError>,
    StorageGetDataOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageDownloadFileOperation: AmplifyOperation<Progress, Void, StorageError>,
    StorageDownloadFileOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStoragePutOperation: AmplifyOperation<Progress, String, StorageError>, StoragePutOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageRemoveOperation: AmplifyOperation<Void, String, StorageError>,
StorageRemoveOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageListOperation: AmplifyOperation<Void, StorageListResult, StorageError>, StorageListOperation {
    override func pause() {
    }

    override func resume() {
    }
}
