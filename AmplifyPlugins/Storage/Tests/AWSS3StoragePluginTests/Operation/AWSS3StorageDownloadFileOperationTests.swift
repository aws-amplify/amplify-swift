//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsCore
@testable import AWSPluginsTestCommon

import AWSS3

class AWSS3StorageDownloadFileOperationTests: AWSS3StorageOperationTestBase {

    private let livenessServiceDispatchQueue = DispatchQueue(
        label: "com.amazon.aws.amplify.liveness.service",
        target: .global()
    )

    func testDownloadFileOperationValidationError() async {
        let request = StorageDownloadFileRequest(key: "",
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testDownloadFileOperationGetIdentityIdError() async throws {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")
        let request = StorageDownloadFileRequest(key: testKey,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .authError = error else {
                    XCTFail("Should have failed with identity error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testDownloadFileOperationDownloadLocal() async {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(nil)]
        let url = URL(fileURLWithPath: "path")
        let request = StorageDownloadFileRequest(key: testKey,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
            }
        })

        operation.start()

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: url)
    }

    func testDownloadFileOperationDownloadLocalFailed() async {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]
        let url = URL(fileURLWithPath: "path")
        let request = StorageDownloadFileRequest(key: testKey,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .failure:
                failedInvoked.fulfill()
            case .success:
                XCTFail("Unexpected event invoked on operation")
            }
        })

        operation.start()

        await fulfillment(of: [failedInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: url)
    }

    func testGetOperationDownloadLocalFromTargetIdentityId() async throws {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(nil)]
        let url = URL(fileURLWithPath: "path")
        let options = StorageDownloadFileRequest.Options(accessLevel: .protected,
                                                         targetIdentityId: testTargetIdentityId)
        let request = StorageDownloadFileRequest(key: testKey,
                                                 local: testURL,
                                                 options: options)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
            }
        })

        operation.start()

        await fulfillment(of: [inProcessInvoked, completeInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: url)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an invalid StringStoragePath
    /// Then: The operation will fail with a validation error
    func testDownloadFileOperationStringStoragePathValidationError() async {
        let path = StringStoragePath(resolve: { _ in return "/my/path" })
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an invalid StringStoragePath
    /// Then: The operation will fail with a validation error
    func testDownloadFileOperationEmptyStoragePathValidationError() async {
        let path = StringStoragePath(resolve: { _ in return " " })
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an invalid IdentityIDStoragePath
    /// Then: The operation will fail with a validation error
    func testDownloadFileOperationIdentityIDStoragePathValidationError() async {
        let path = IdentityIDStoragePath(resolve: { _ in return "/my/path" })
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an a custom implementation of StoragePath
    /// Then: The operation will fail with a validation error
    func testDownloadFileOperationCustomStoragePathValidationError() async {
        let path = InvalidCustomStoragePath(resolve: { _ in return "my/path" })
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an valid StringStoragePath
    /// Then: The operation will succeed
    func testDownloadFileOperationWithStringStoragePathSucceeds() async throws {
        let path = StringStoragePath(resolve: { _ in return "public/\(self.testKey)" })
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(nil)]
        let url = URL(fileURLWithPath: "path")
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
            }
        })

        operation.start()

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: "public/\(self.testKey)", fileURL: url)
    }

    /// Given: Storage Download File Operation
    /// When: The operation is executed with a request that has an valid IdentityIDStoragePath
    /// Then: The operation will succeed
    func testDownloadFileOperationWithIdentityIDStoragePathSucceeds() async throws {
        mockAuthService.identityId = testIdentityId
        let path = IdentityIDStoragePath(resolve: { id in return "public/\(id)/\(self.testKey)" })
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(nil)]
        let url = URL(fileURLWithPath: "path")
        let request = StorageDownloadFileRequest(path: path,
                                                 local: testURL,
                                                 options: StorageDownloadFileRequest.Options())
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
            }
        })

        operation.start()

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: "public/\(testIdentityId)/\(self.testKey)", fileURL: url)
    }

    // TODO: missing unit tests for pause resume and cancel. do we create a mock of the StorageTaskReference?
}
