//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import Amplify
import AWSPluginsCore

extension AWSS3StoragePlugin {

    @discardableResult
    public func getURL(
        key: String,
        options: StorageGetURLOperation.Request.Options?
    ) async throws -> URL {
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageConfiguration: storageConfiguration,
                                                    storageService: storageService,
                                                    authService: authService)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return try await taskAdapter.value
    }

    @discardableResult
    public func downloadData(
        key: String,
        options: StorageDownloadDataOperation.Request.Options? = nil
    ) -> StorageDownloadDataTask {
        let options = options ?? StorageDownloadDataRequest.Options()
        let request = StorageDownloadDataRequest(key: key, options: options)
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                          storageConfiguration: storageConfiguration,
                                                          storageService: storageService,
                                                          authService: authService)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return taskAdapter
    }

    @discardableResult
    public func downloadFile(
        key: String,
        local: URL,
        options: StorageDownloadFileOperation.Request.Options?
    ) -> StorageDownloadFileTask {
        let options = options ?? StorageDownloadFileRequest.Options()
        let request = StorageDownloadFileRequest(key: key, local: local, options: options)
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: storageConfiguration,
                                                          storageService: storageService,
                                                          authService: authService)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)

        return taskAdapter
    }

    @discardableResult
    public func uploadData(
        key: String,
        data: Data,
        options: StorageUploadDataOperation.Request.Options?
    ) -> StorageUploadDataTask {
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return taskAdapter
    }

    @discardableResult
    public func uploadFile(
        key: String,
        local: URL,
        options: StorageUploadFileOperation.Request.Options?
    ) -> StorageUploadFileTask {
        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)
        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return taskAdapter
    }

    @discardableResult
    public func remove(
        key: String,
        options: StorageRemoveOperation.Request.Options?
    ) async throws -> String {
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        let operation = AWSS3StorageRemoveOperation(request,
                                                    storageConfiguration: storageConfiguration,
                                                    storageService: storageService,
                                                    authService: authService)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return try await taskAdapter.value
    }

    public func list(
        options: StorageListRequest.Options? = nil
    ) async throws -> StorageListResult {
        let options = options ?? StorageListRequest.Options()
        let request = StorageListRequest(options: options)
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: storageConfiguration,
                                                  storageService: storageService,
                                                  authService: authService)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        
        return try await taskAdapter.value
    }

    public func handleBackgroundEvents(identifier: String) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            StorageBackgroundEventsRegistry.handleBackgroundEvents(identifier: identifier, continuation: continuation)
        }
    }

}
