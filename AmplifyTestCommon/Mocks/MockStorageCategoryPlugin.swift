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
