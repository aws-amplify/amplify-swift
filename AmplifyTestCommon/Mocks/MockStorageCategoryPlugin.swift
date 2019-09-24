//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {

    func getURL(key: String,
                options: StorageGetURLRequest.Options?,
                onEvent: StorageGetURLOperation.EventHandler?) -> StorageGetURLOperation {
        notify("getURL")
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        return MockStorageGetURLOperation(categoryType: .storage, request: request)
    }

    func getData(key: String,
                 options: StorageGetDataRequest.Options?,
                 onEvent: StorageGetDataOperation.EventHandler?)
        -> StorageGetDataOperation {
        notify("getData")
            let options = options ?? StorageGetDataRequest.Options()
            let request = StorageGetDataRequest(key: key, options: options)
            return MockStorageGetDataOperation(categoryType: .storage, request: request)
    }

    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileRequest.Options?,
                      onEvent: StorageDownloadFileOperation.EventHandler?)
        -> StorageDownloadFileOperation {
        notify("downloadFile")
            let options = options ?? StorageDownloadFileRequest.Options()
            let request = StorageDownloadFileRequest(key: key, local: local, options: options)
            return MockStorageDownloadFileOperation(categoryType: .storage, request: request)
    }

    func put(key: String,
             data: Data,
             options: StoragePutRequest.Options?,
             onEvent: StoragePutOperation.EventHandler?) -> StoragePutOperation {
        notify("put")
        let options = options ?? StoragePutRequest.Options()
        let source = StoragePutRequest.Source.data(data)
        let request = StoragePutRequest(key: key, source: source, options: options)
        return MockStoragePutOperation(categoryType: .storage, request: request)
    }

    func put(key: String,
             local: URL,
             options: StoragePutRequest.Options?,
             onEvent: StoragePutOperation.EventHandler?) -> StoragePutOperation {
        notify("putFile")
        let options = options ?? StoragePutRequest.Options()
        let source = StoragePutRequest.Source.local(local)
        let request = StoragePutRequest(key: key, source: source, options: options)
        return MockStoragePutOperation(categoryType: .storage, request: request)
    }

    func remove(key: String,
                options: StorageRemoveRequest.Options?,
                onEvent: StorageRemoveOperation.EventHandler?) -> StorageRemoveOperation {
        notify("remove")
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        return MockStorageRemoveOperation(categoryType: .storage, request: request)
    }

    func list(options: StorageListRequest.Options?,
              onEvent: StorageListOperation.EventHandler?) -> StorageListOperation {
        notify("list")
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        return MockStorageListOperation(categoryType: .storage, request: request)
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

class MockStorageGetURLOperation: AmplifyOperation<StorageGetURLRequest, Void, URL, StorageError>,
StorageGetURLOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageGetDataOperation: AmplifyOperation<StorageGetDataRequest, Progress, Data, StorageError>,
    StorageGetDataOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageDownloadFileOperation: AmplifyOperation<StorageDownloadFileRequest, Progress, Void, StorageError>,
    StorageDownloadFileOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStoragePutOperation: AmplifyOperation<StoragePutRequest, Progress, String, StorageError>,
StoragePutOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageRemoveOperation: AmplifyOperation<StorageRemoveRequest, Void, String, StorageError>,
StorageRemoveOperation {
    override func pause() {
    }

    override func resume() {
    }
}

class MockStorageListOperation: AmplifyOperation<StorageListRequest, Void, StorageListResult, StorageError>,
StorageListOperation {
    override func pause() {
    }

    override func resume() {
    }
}
