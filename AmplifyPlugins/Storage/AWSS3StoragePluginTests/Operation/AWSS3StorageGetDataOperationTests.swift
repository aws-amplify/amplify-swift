//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsCore
import AWSS3

class AWSS3StorageDownloadDataOperationTests: AWSS3StorageOperationTestBase {

    func testDownloadDataOperationValidationError() {
        let request = StorageDownloadDataRequest(key: "", options: StorageDownloadDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { event in
            switch event {
            case .failed(let error):
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

    func testDownloadDataOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "", "")
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { event in
            switch event {
            case .failed(let error):
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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testDownloadDataOperationDownloadData() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                 storageService: mockStorageService,
                                                 authService: mockAuthService) { event in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testDownloadDataOperationDownloadDataFailed() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]
        let request = StorageDownloadDataRequest(key: testKey, options: StorageDownloadDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.guest.serviceAccessPrefix + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "fail was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { event in
            switch event {
            case .failed:
                failInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testGetOperationDownloadDataFromTargetIdentityId() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected,
                                                    targetIdentityId: testTargetIdentityId)
        let request = StorageDownloadDataRequest(key: testKey, options: options)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageDownloadDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { event in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    // TODO: missing unit tets for pause resume and cancel. do we create a mock of the StorageTaskReference?
}
