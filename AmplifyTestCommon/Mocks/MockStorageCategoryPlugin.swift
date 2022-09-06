//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {

    var key: String {
        return "MockStorageCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

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

    @discardableResult
    func remove(key: String,
                options: StorageRemoveRequest.Options? = nil) async throws -> String {
        notify("remove")
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        let operation = MockStorageRemoveOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }

    @discardableResult
    func downloadData(key: String,
                      options: StorageDownloadDataOperation.Request.Options? = nil) async throws -> StorageDownloadDataTask {
        notify("downloadData")
        let options = options ?? StorageDownloadDataRequest.Options()
        let request = StorageDownloadDataRequest(key: key, options: options)
        let operation = MockStorageDownloadDataOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation, subscribeEnabled: false)
        return taskAdapter
    }

    @discardableResult
    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileTask {
        notify("downloadFile")
        let options = options ?? StorageDownloadFileRequest.Options()
        let request = StorageDownloadFileRequest(key: key, local: local, options: options)
        let operation = MockStorageDownloadFileOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation, subscribeEnabled: false)
        return taskAdapter
    }

    @discardableResult
    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataOperation.Request.Options?) async throws -> StorageUploadDataTask {
        notify("uploadData")
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)
        let operation = MockStorageUploadDataOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation, subscribeEnabled: false)
        return taskAdapter
    }

    @discardableResult
    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileOperation.Request.Options?) async throws -> StorageUploadFileTask {
        notify("uploadFile")
        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)
        let operation =  MockStorageUploadFileOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation, subscribeEnabled: false)
        return taskAdapter
    }

    @discardableResult
    func list(options: StorageListOperation.Request.Options?) async throws -> StorageListResult {
        notify("list")
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        let operation = MockStorageListOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        return try await taskAdapter.value
    }

    func handleBackgroundEvents(identifier: String) async -> Bool {
        false
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

class MockStorageDownloadDataOperation: AmplifyInProcessReportingOperation<StorageDownloadDataRequest, Progress, Data, StorageError>, StorageDownloadDataOperation {
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

class MockStorageDownloadFileOperation: AmplifyInProcessReportingOperation<StorageDownloadFileRequest, Progress, Void, StorageError>, StorageDownloadFileOperation {
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

class MockStorageUploadDataOperation: AmplifyInProcessReportingOperation<StorageUploadDataRequest, Progress, String, StorageError>, StorageUploadDataOperation {
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

class MockStorageUploadFileOperation: AmplifyInProcessReportingOperation<StorageUploadFileRequest, Progress, String, StorageError>, StorageUploadFileOperation {
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
