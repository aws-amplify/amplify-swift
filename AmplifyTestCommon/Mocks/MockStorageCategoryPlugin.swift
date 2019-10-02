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
                listener: StorageGetURLOperation.EventListener?) -> StorageGetURLOperation {
        notify("getURL")
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        return MockStorageGetURLOperation(request: request)
    }

    func getData(key: String,
                 options: StorageGetDataRequest.Options?,
                 listener: StorageGetDataOperation.EventListener?)
        -> StorageGetDataOperation {
        notify("getData")
            let options = options ?? StorageGetDataRequest.Options()
            let request = StorageGetDataRequest(key: key, options: options)
            return MockStorageGetDataOperation(request: request)
    }

    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileRequest.Options?,
                      listener: StorageDownloadFileOperation.EventListener?)
        -> StorageDownloadFileOperation {
        notify("downloadFile")
            let options = options ?? StorageDownloadFileRequest.Options()
            let request = StorageDownloadFileRequest(key: key, local: local, options: options)
            return MockStorageDownloadFileOperation(request: request)
    }

    func put(key: String,
             data: Data,
             options: StoragePutRequest.Options?,
             listener: StoragePutOperation.EventListener?) -> StoragePutOperation {
        notify("put")
        let options = options ?? StoragePutRequest.Options()
        let source = StoragePutRequest.Source.data(data)
        let request = StoragePutRequest(key: key, source: source, options: options)
        return MockStoragePutOperation(request: request)
    }

    func put(key: String,
             local: URL,
             options: StoragePutRequest.Options?,
             listener: StoragePutOperation.EventListener?) -> StoragePutOperation {
        notify("putFile")
        let options = options ?? StoragePutRequest.Options()
        let source = StoragePutRequest.Source.local(local)
        let request = StoragePutRequest(key: key, source: source, options: options)
        return MockStoragePutOperation(request: request)
    }

    func remove(key: String,
                options: StorageRemoveRequest.Options?,
                listener: StorageRemoveOperation.EventListener?) -> StorageRemoveOperation {
        notify("remove")
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        return MockStorageRemoveOperation(request: request)
    }

    func list(options: StorageListRequest.Options?,
              listener: StorageListOperation.EventListener?) -> StorageListOperation {
        notify("list")
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        return MockStorageListOperation(request: request)
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

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.getURL,
                   request: request)
    }
}

class MockStorageGetDataOperation: AmplifyOperation<StorageGetDataRequest, Progress, Data, StorageError>,
    StorageGetDataOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.getData,
                   request: request)
    }
}

class MockStorageDownloadFileOperation: AmplifyOperation<StorageDownloadFileRequest, Progress, Void, StorageError>,
    StorageDownloadFileOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadFile,
                   request: request)
    }
}

class MockStoragePutOperation: AmplifyOperation<StoragePutRequest, Progress, String, StorageError>,
StoragePutOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.put,
                   request: request)
    }
}

class MockStorageRemoveOperation: AmplifyOperation<StorageRemoveRequest, Void, String, StorageError>,
StorageRemoveOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.remove,
                   request: request)
    }
}

class MockStorageListOperation: AmplifyOperation<StorageListRequest, Void, StorageListResult, StorageError>,
StorageListOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.list,
                   request: request)
    }
}
