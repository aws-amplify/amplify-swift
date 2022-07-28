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

    public func getURL(key: String,
                       options: StorageGetURLOperation.Request.Options?) async throws -> StorageGetURLOperation.Success {
        try await withCheckedThrowingContinuation { continuation in
            let options = options ?? StorageGetURLRequest.Options()
            let request = StorageGetURLRequest(key: key, options: options)
            let operation = AWSS3StorageGetURLOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

            }

            self.queue.addOperation(operation)
        }
    }

    public func downloadData(key: String,
                             options: StorageDownloadDataOperation.Request.Options?) async throws -> StorageDownloadDataOperation {
        let options = options ?? StorageDownloadDataRequest.Options()
        let request = StorageDownloadDataRequest(key: key, options: options)
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                          storageConfiguration: storageConfiguration,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          progressListener: nil,
                                                          resultListener: nil)

        queue.addOperation(operation)

        return operation
    }

    public func downloadFile(key: String,
                             local: URL,
                             options: StorageDownloadFileOperation.Request.Options?) async throws -> StorageDownloadFileOperation {
        let options = options ?? StorageDownloadFileRequest.Options()
        let request = StorageDownloadFileRequest(key: key, local: local, options: options)
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: storageConfiguration,
                                                          storageService: storageService,
                                                          authService: authService,
                                                          progressListener: nil,
                                                          resultListener: nil)

        queue.addOperation(operation)

        return operation
    }

    public func uploadData(key: String,
                           data: Data,
                           options: StorageUploadDataOperation.Request.Options?) async throws -> StorageUploadDataOperation {
        let options = options ?? StorageUploadDataRequest.Options()
        let request = StorageUploadDataRequest(key: key, data: data, options: options)

        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService,
                                                        progressListener: nil,
                                                        resultListener: nil)

        queue.addOperation(operation)

        return operation
    }

    public func uploadFile(key: String,
                           local: URL,
                           options: StorageUploadFileOperation.Request.Options?) async throws -> StorageUploadFileOperation {

        let options = options ?? StorageUploadFileRequest.Options()
        let request = StorageUploadFileRequest(key: key, local: local, options: options)

        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService,
                                                        progressListener: nil,
                                                        resultListener: nil)

        queue.addOperation(operation)

        return operation
    }

    public func remove(key: String,
                       options: StorageRemoveOperation.Request.Options?) async throws -> StorageRemoveOperation.Success {
        try await withCheckedThrowingContinuation { continuation in
            let options = options ?? StorageRemoveRequest.Options()
            let request = StorageRemoveRequest(key: key, options: options)
            let operation = AWSS3StorageRemoveOperation(request,
                                                        storageConfiguration: storageConfiguration,
                                                        storageService: storageService,
                                                        authService: authService) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

            }

            self.queue.addOperation(operation)
        }
    }

    public func list(options: StorageListOperation.Request.Options?) async throws -> StorageListOperation.Success {
        try await withCheckedThrowingContinuation { continuation in
            let options = options ?? StorageListRequest.Options()
            let request = StorageListRequest(options: options)
            let operation = AWSS3StorageListOperation(request,
                                                          storageConfiguration: storageConfiguration,
                                                          storageService: storageService,
                                                          authService: authService) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

            }
            self.queue.addOperation(operation)
        }

    }

}
