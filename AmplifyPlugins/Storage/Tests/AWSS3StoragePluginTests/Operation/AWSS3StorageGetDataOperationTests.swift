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

class AWSS3StorageDownloadDataOperationTests: AWSS3StorageOperationTestBase {

    func testDownloadDataOperationValidationError() {
        let request = StorageDownloadDataRequest(key: "", options: StorageDownloadDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { event in
                                                            switch event {
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
        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testDownloadDataOperationGetIdentityIdError() async throws {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                          storageConfiguration: testStorageConfiguration,
                                                          storageService: mockStorageService,
                                                          authService: mockAuthService,
                                                          progressListener: nil) { event in
                                                            switch event {
                                                            case .failure(let error):
                                                                guard case .authError = error else {
                                                                    XCTFail("Should have failed with authError")
                                                                    return
                                                                }
                                                                failedInvoked.fulfill()
                                                            default:
                                                                XCTFail("Should have received failed event")
                                                            }
        }

        operation.start()

        await waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testDownloadDataOperationDownloadData() async throws {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(
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
                XCTFail("Unexpected event invoked on operation: \(error)")
            }
        })

        operation.start()

        await waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testDownloadDataOperationDownloadDataFailed() async throws {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "fail was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success(let data):
                XCTFail("Unexpected event invoked on operation: \(data)")
            case .failure:
                failInvoked.fulfill()
            }
        })

        operation.start()

        await waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testGetOperationDownloadDataFromTargetIdentityId() async throws {
        let task = StorageTransferTask(transferType: .download(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected,
                                                         targetIdentityId: testTargetIdentityId)
        let request = StorageDownloadDataRequest(key: testKey, options: options)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(
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
                XCTFail("Unexpected error in operation: \(error)")
            }
        })

        operation.start()

        await waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    // TODO: missing unit tets for pause resume and cancel. do we create a mock of the StorageTaskReference?
}
