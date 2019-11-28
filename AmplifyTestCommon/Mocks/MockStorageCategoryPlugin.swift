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

    func downloadData(key: String,
                      options: StorageDownloadDataRequest.Options?,
                      listener: StorageDownloadDataOperation.EventListener?)
        -> StorageDownloadDataOperation {
        notify("downloadData")
            let options = options ?? StorageDownloadDataRequest.Options()
            let request = StorageDownloadDataRequest(key: key, options: options)
            return MockStorageDownloadDataOperation(request: request)
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

    func uploadData(key: String,
                 data: Data,
                 options: StorageUploadDataRequest.Options?,
                 listener: StorageUploadDataOperation.EventListener?) -> StorageUploadDataOperation {
        notify("uploadData")
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)
        return MockStorageUploadDataOperation(request: request)
    }

    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileRequest.Options?,
                    listener: StorageUploadFileOperation.EventListener?) -> StorageUploadFileOperation {
        notify("uploadFile")
        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)
        return MockStorageUploadFileOperation(request: request)
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

    func reset(onComplete: @escaping BasicClosure) {
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

class MockStorageDownloadDataOperation: AmplifyOperation<StorageDownloadDataRequest, Progress, Data, StorageError>,
    StorageDownloadDataOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadData,
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

class MockStorageUploadDataOperation: AmplifyOperation<StorageUploadDataRequest, Progress, String, StorageError>,
StorageUploadDataOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadData,
                   request: request)
    }
}

class MockStorageUploadFileOperation: AmplifyOperation<StorageUploadFileRequest, Progress, String, StorageError>,
StorageUploadFileOperation {
    override func pause() {
    }

    override func resume() {
    }

    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadFile,
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
