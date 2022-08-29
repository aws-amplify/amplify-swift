//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {

    func getURL(key: String,
                options: StorageGetURLRequest.Options?,
                resultListener: StorageGetURLOperation.ResultListener?) -> StorageGetURLOperation {
        notify("getURL")
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        return MockStorageGetURLOperation(request: request)
    }

    func downloadData(key: String,
                      options: StorageDownloadDataRequest.Options?,
                      progressListener: ProgressListener? = nil,
                      resultListener: StorageDownloadDataOperation.ResultListener?
    ) -> StorageDownloadDataOperation {
        notify("downloadData")
            let options = options ?? StorageDownloadDataRequest.Options()
            let request = StorageDownloadDataRequest(key: key, options: options)
            return MockStorageDownloadDataOperation(request: request)
    }

    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileRequest.Options?,
                      progressListener: ProgressListener? = nil,
                      resultListener: StorageDownloadFileOperation.ResultListener?
    ) -> StorageDownloadFileOperation {
        notify("downloadFile")
            let options = options ?? StorageDownloadFileRequest.Options()
            let request = StorageDownloadFileRequest(key: key, local: local, options: options)
            return MockStorageDownloadFileOperation(request: request)
    }

    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataRequest.Options?,
                    progressListener: ProgressListener? = nil,
                    resultListener: StorageUploadDataOperation.ResultListener?
    ) -> StorageUploadDataOperation {
        notify("uploadData")
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)
        return MockStorageUploadDataOperation(request: request)
    }

    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileRequest.Options?,
                    progressListener: ProgressListener? = nil,
                    resultListener: StorageUploadFileOperation.ResultListener?
    ) -> StorageUploadFileOperation {
        notify("uploadFile")
        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)
        return MockStorageUploadFileOperation(request: request)
    }

    func remove(key: String,
                options: StorageRemoveRequest.Options?,
                resultListener: StorageRemoveOperation.ResultListener?) -> StorageRemoveOperation {
        notify("remove")
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        return MockStorageRemoveOperation(request: request)
    }

    func list(options: StorageListRequest.Options?,
              resultListener: StorageListOperation.ResultListener?) -> StorageListOperation {
        notify("list")
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        return MockStorageListOperation(request: request)
    }

    var key: String {
        return "MockStorageCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

    // MARK: - Async API -

    @discardableResult
    func getURL(key: String,
                options: StorageGetURLOperation.Request.Options?) async throws -> URL {
        notify("getURL")
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        let operation = MockStorageGetURLOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }

}

class MockSecondStorageCategoryPlugin: MockStorageCategoryPlugin {
    override var key: String {
        return "MockSecondStorageCategoryPlugin"
    }
}

class MockStorageGetURLOperation: AmplifyOperation<StorageGetURLRequest, URL, StorageError>,
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

class MockStorageDownloadDataOperation: AmplifyInProcessReportingOperation<
    StorageDownloadDataRequest,
    Progress,
    Data,
    StorageError
>, StorageDownloadDataOperation {
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

class MockStorageDownloadFileOperation: AmplifyInProcessReportingOperation<
    StorageDownloadFileRequest,
    Progress,
    Void,
    StorageError
>, StorageDownloadFileOperation {
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

class MockStorageUploadDataOperation: AmplifyInProcessReportingOperation<
    StorageUploadDataRequest,
    Progress,
    String,
    StorageError
>, StorageUploadDataOperation {
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

class MockStorageUploadFileOperation: AmplifyInProcessReportingOperation<
    StorageUploadFileRequest,
    Progress,
    String,
    StorageError
>, StorageUploadFileOperation {
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

class MockStorageRemoveOperation: AmplifyOperation<StorageRemoveRequest, String, StorageError>,
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

class MockStorageListOperation: AmplifyOperation<StorageListRequest, StorageListResult, StorageError>,
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
